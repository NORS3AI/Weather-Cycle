-- Weather-Cycle : Core.lua
-- The engine. Owns saved variables, the current scene state, the auto-cycle
-- ticker, party/raid addon synchronisation, optional toy triggering, and the
-- slash-command interface. Presentation (toast, tint, chat text, UI, minimap,
-- options) lives in the other files and is driven from here.

local ADDON, ns = ...
ns.name = ADDON
ns.version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version") or "1.0.0"

-- Addon-message prefix (must be <= 16 characters).
local PREFIX = "WeatherCyc"
-- Unit separator used to delimit fields inside a sync message.
local SEP = "\31"

-- ---------------------------------------------------------------------------
-- Saved-variable defaults
-- ---------------------------------------------------------------------------
local DEFAULTS = {
    version     = 1,
    broadcast   = true,          -- print immersive lines to a chat channel
    channel     = "AUTO",        -- AUTO | PARTY | RAID | SAY | YELL | EMOTE
    sync        = true,          -- send silent scene sync to group members
    receiveSync = true,          -- react to scenes broadcast by other members
    toys        = false,         -- attempt to fire a bound toy for the scene
    toast       = true,          -- show the on-screen scene toast
    screenTint  = true,          -- briefly tint the screen in the scene colour
    minimap     = { hide = false, angle = 210 },
    cycle = {
        enabled  = false,        -- run the auto-cycle ticker
        interval = 10,           -- minutes between cycle steps
        mode     = "time",       -- time | weather | both
        announce = true,         -- also broadcast cycle changes to chat
    },
    toyBinds = {                 -- scene key -> toy itemID
        weather = {},
        time    = {},
    },
    current = { weather = "clear", time = "morning" },
    uiPoint = nil,               -- saved main-window position
}

-- Recursively fill any missing fields of `db` from `defaults`.
local function ApplyDefaults(db, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(db[k]) ~= "table" then db[k] = {} end
            ApplyDefaults(db[k], v)
        elseif db[k] == nil then
            db[k] = v
        end
    end
    return db
end

-- ---------------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------------
local PREFIX_TAG = "|cff6ec6ffWeather-Cycle|r: "

function ns:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX_TAG .. tostring(msg))
end

-- Full "Name-Realm" for the local player, used to ignore our own sync echoes.
local function MyFullName()
    local name = UnitName("player")
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
    if realm then realm = realm:gsub("%s+", "") end
    if name and realm then return name .. "-" .. realm end
    return name
end

-- Resolve the chat channel to actually send to, honouring the AUTO setting and
-- the current group state. Returns nil when there is nowhere sensible to send.
function ns:ResolveChannel()
    local c = self.db and self.db.channel or "AUTO"
    if c == "AUTO" then
        if IsInRaid() then return "RAID"
        elseif IsInGroup() then return "PARTY"
        else return "EMOTE" end
    end
    if (c == "PARTY" or c == "RAID") and not IsInGroup() then
        return "EMOTE"
    end
    if c == "RAID" and not IsInRaid() then
        return "PARTY"
    end
    return c
end

-- ---------------------------------------------------------------------------
-- Applying a scene
-- ---------------------------------------------------------------------------
-- Set the current weather or time-of-day scene and present it. `kind` is
-- "weather" or "time"; `key` is a scene key from Data.lua. `opts` fields:
--   broadcast : override the chat broadcast for this call (bool)
--   sync      : override the group sync for this call (bool)
--   toy       : override toy firing for this call (bool)
--   fromSync  : true when the change originated from another player's sync
function ns:SetScene(kind, key, opts)
    opts = opts or {}
    if kind ~= "weather" and kind ~= "time" then return false end
    if not ns.Data:IsValid(kind, key) then
        self:Print("Unknown " .. kind .. " scene: " .. tostring(key))
        return false
    end

    self.db.current[kind] = key

    -- Local presentation is always shown for the person driving the scene.
    if self.db.toast and ns.Toast then
        ns.Toast:Show(kind, key, opts.fromSync and opts.sender or nil)
    end

    if not opts.fromSync then
        if opts.broadcast ~= false and self.db.broadcast and ns.Broadcast then
            ns.Broadcast:Chat(kind, key)
        end
        if opts.sync ~= false and self.db.sync and ns.Broadcast then
            ns.Broadcast:Sync(kind, key, PREFIX, SEP)
        end
        if opts.toy ~= false and self.db.toys then
            self:FireToy(kind, key)
        end
    end

    if ns.UI and ns.UI.Refresh then ns.UI:Refresh() end
    return true
end

-- ---------------------------------------------------------------------------
-- Optional toy integration
-- ---------------------------------------------------------------------------
-- Fire a toy the player has bound to this scene, if any. Purely optional --
-- the roleplay works entirely through chat/sync without owning any toy.
function ns:FireToy(kind, key)
    local binds = self.db.toyBinds[kind]
    local itemID = binds and binds[key]
    if not itemID then return end
    if InCombatLockdown() then
        self:Print("Cannot use a toy while in combat.")
        return
    end
    if C_ToyBox and PlayerHasToy and PlayerHasToy(itemID) and C_ToyBox.UseToy then
        pcall(C_ToyBox.UseToy, itemID)
    elseif C_Item and C_Item.GetItemCount and C_Item.GetItemCount(itemID) > 0 and C_Item.UseItemByID then
        pcall(C_Item.UseItemByID, itemID)
    else
        self:Print("You do not have the toy bound to this scene (item " .. itemID .. ").")
    end
end

function ns:BindToy(kind, key, itemID)
    if kind ~= "weather" and kind ~= "time" then
        self:Print("Toy bind kind must be 'weather' or 'time'.")
        return
    end
    if not ns.Data:IsValid(kind, key) then
        self:Print("Unknown " .. kind .. " scene: " .. tostring(key))
        return
    end
    itemID = tonumber(itemID)
    if not itemID then
        self.db.toyBinds[kind][key] = nil
        self:Print("Cleared toy binding for " .. kind .. " '" .. key .. "'.")
        return
    end
    self.db.toyBinds[kind][key] = itemID
    self:Print(("Bound %s '%s' to item %d."):format(kind, key, itemID))
end

-- ---------------------------------------------------------------------------
-- Auto-cycle engine
-- ---------------------------------------------------------------------------
function ns:StopCycle()
    if self.cycleTicker then
        self.cycleTicker:Cancel()
        self.cycleTicker = nil
    end
end

function ns:StartCycle()
    self:StopCycle()
    if not self.db.cycle.enabled then return end
    local minutes = math.max(1, tonumber(self.db.cycle.interval) or 10)
    self.cycleTicker = C_Timer.NewTicker(minutes * 60, function()
        self:CycleStep()
    end)
end

-- Restart the ticker after a settings change so a new interval takes effect.
function ns:RefreshCycle()
    if self.db.cycle.enabled then
        self:StartCycle()
    else
        self:StopCycle()
    end
    if ns.UI and ns.UI.Refresh then ns.UI:Refresh() end
end

-- One tick of the auto-cycle: advance time in sequence and/or roll new weather.
function ns:CycleStep()
    local mode = self.db.cycle.mode
    local announce = self.db.cycle.announce
    -- toy = false: the ticker is not a hardware event, so a protected
    -- C_ToyBox.UseToy would be blocked. Toys only fire from a real click.
    if mode == "time" or mode == "both" then
        local nextKey = ns.Data:Next("time", self.db.current.time)
        self:SetScene("time", nextKey, { broadcast = announce, toy = false })
    end
    if mode == "weather" or mode == "both" then
        local nextKey = ns.Data:Random("weather", self.db.current.weather)
        self:SetScene("weather", nextKey, { broadcast = announce, toy = false })
    end
end

-- ---------------------------------------------------------------------------
-- Incoming addon-message sync
-- ---------------------------------------------------------------------------
local myName
function ns:OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= PREFIX then return end
    if not self.db.receiveSync then return end
    myName = myName or MyFullName()
    if sender == myName then return end -- ignore our own echo

    local ver, op, kind, key = strsplit(SEP, message)
    if op == "SET" and ns.Data:IsValid(kind, key) then
        -- fromSync = true means: update + show locally, but do not re-broadcast
        -- or re-sync, which prevents an endless echo around the group.
        self:SetScene(kind, key, { fromSync = true, sender = Ambiguate and Ambiguate(sender, "short") or sender })
    end
end

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------
local function ChannelName(kind, key)
    local def = ns.Data:Get(kind, key)
    return def and def.name or key
end

local function ListScenes()
    ns:Print("Weather scenes:")
    DEFAULT_CHAT_FRAME:AddMessage("  " .. table.concat(ns.Data.weatherOrder, ", "))
    ns:Print("Time scenes:")
    DEFAULT_CHAT_FRAME:AddMessage("  " .. table.concat(ns.Data.timeOrder, ", "))
end

local function ShowHelp()
    ns:Print("Commands:")
    local help = {
        "/wc                     - toggle the main window",
        "/wc show | hide         - open or close the main window",
        "/wc config              - open the options panel",
        "/wc weather <key>       - set a weather scene",
        "/wc time <key>          - set a time-of-day scene",
        "/wc list                - list every scene key",
        "/wc cycle on | off      - toggle the auto-cycle",
        "/wc cycle interval <m>  - set cycle interval in minutes",
        "/wc cycle mode <t|w|b>  - cycle time, weather, or both",
        "/wc broadcast on | off  - toggle chat broadcasting",
        "/wc channel <name>      - AUTO | PARTY | RAID | SAY | YELL | EMOTE",
        "/wc minimap             - toggle the minimap button",
        "/wc toy <w|t> <key> <id>- bind a toy itemID to a scene (blank to clear)",
    }
    for _, line in ipairs(help) do
        DEFAULT_CHAT_FRAME:AddMessage("  " .. line)
    end
end

local function HandleSlash(input)
    input = (input or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local cmd, rest = input:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    if cmd == "" or cmd == "toggle" then
        if ns.UI then ns.UI:Toggle() end
    elseif cmd == "show" or cmd == "open" then
        if ns.UI then ns.UI:Show() end
    elseif cmd == "hide" or cmd == "close" then
        if ns.UI then ns.UI:Hide() end
    elseif cmd == "config" or cmd == "options" then
        if ns.Options and ns.Options.Open then ns.Options:Open() end
    elseif cmd == "weather" then
        ns:SetScene("weather", rest:lower())
    elseif cmd == "time" then
        ns:SetScene("time", rest:lower())
    elseif cmd == "list" then
        ListScenes()
    elseif cmd == "broadcast" then
        ns.db.broadcast = (rest:lower() ~= "off")
        ns:Print("Chat broadcasting " .. (ns.db.broadcast and "enabled." or "disabled."))
        if ns.Options and ns.Options.Refresh then ns.Options:Refresh() end
    elseif cmd == "channel" then
        local c = rest:upper()
        local valid = { AUTO = true, PARTY = true, RAID = true, SAY = true, YELL = true, EMOTE = true }
        if valid[c] then
            ns.db.channel = c
            ns:Print("Broadcast channel set to " .. c .. ".")
            if ns.Options and ns.Options.Refresh then ns.Options:Refresh() end
        else
            ns:Print("Channel must be AUTO, PARTY, RAID, SAY, YELL or EMOTE.")
        end
    elseif cmd == "minimap" then
        ns.db.minimap.hide = not ns.db.minimap.hide
        if ns.Minimap and ns.Minimap.Update then ns.Minimap:Update() end
        ns:Print("Minimap button " .. (ns.db.minimap.hide and "hidden." or "shown."))
    elseif cmd == "cycle" then
        local sub, arg = rest:match("^(%S*)%s*(.-)$")
        sub = (sub or ""):lower()
        if sub == "on" then
            ns.db.cycle.enabled = true; ns:RefreshCycle()
            ns:Print(("Auto-cycle enabled (%s, every %d min)."):format(ns.db.cycle.mode, ns.db.cycle.interval))
        elseif sub == "off" then
            ns.db.cycle.enabled = false; ns:RefreshCycle()
            ns:Print("Auto-cycle disabled.")
        elseif sub == "interval" then
            local m = tonumber(arg)
            if m and m >= 1 then
                ns.db.cycle.interval = math.floor(m); ns:RefreshCycle()
                ns:Print("Cycle interval set to " .. ns.db.cycle.interval .. " min.")
            else
                ns:Print("Interval must be a number of minutes (>= 1).")
            end
        elseif sub == "mode" then
            local m = arg:lower()
            local map = { t = "time", time = "time", w = "weather", weather = "weather", b = "both", both = "both" }
            if map[m] then
                ns.db.cycle.mode = map[m]; ns:RefreshCycle()
                ns:Print("Cycle mode set to " .. ns.db.cycle.mode .. ".")
            else
                ns:Print("Mode must be time, weather or both.")
            end
        else
            ns:Print("Usage: /wc cycle on|off|interval <m>|mode <time|weather|both>")
        end
        if ns.Options and ns.Options.Refresh then ns.Options:Refresh() end
    elseif cmd == "toy" then
        local k, key, id = rest:match("^(%S*)%s+(%S*)%s*(.-)$")
        local kind = (k == "w" or k == "weather") and "weather"
            or (k == "t" or k == "time") and "time" or nil
        if kind and key and key ~= "" then
            ns:BindToy(kind, key, id ~= "" and id or nil)
        else
            ns:Print("Usage: /wc toy <weather|time> <scene key> <itemID>")
        end
    elseif cmd == "help" or cmd == "?" then
        ShowHelp()
    else
        ns:Print("Unknown command. Type /wc help for a list.")
    end
end

-- ---------------------------------------------------------------------------
-- Bootstrap
-- ---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CHAT_MSG_ADDON")

frame:SetScript("OnEvent", function(_, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        WeatherCycleDB = ApplyDefaults(WeatherCycleDB or {}, DEFAULTS)
        ns.db = WeatherCycleDB
    elseif event == "PLAYER_LOGIN" then
        -- db is guaranteed to exist by now (ADDON_LOADED fires first).
        ns.db = ns.db or ApplyDefaults(WeatherCycleDB or {}, DEFAULTS)
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
        end
        if ns.Minimap and ns.Minimap.Init then ns.Minimap:Init() end
        if ns.Options and ns.Options.Init then ns.Options:Init() end
        if ns.UI and ns.UI.Init then ns.UI:Init() end
        ns:StartCycle()
        ns:Print("loaded. Type /wc to open, or /wc help for commands.")
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = arg1, ...
        ns:OnAddonMessage(prefix, message, channel, sender)
    end
end)

SLASH_WEATHERCYCLE1 = "/wc"
SLASH_WEATHERCYCLE2 = "/weathercycle"
SlashCmdList["WEATHERCYCLE"] = HandleSlash
