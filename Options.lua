-- Weather-Cycle : Options.lua
-- A settings panel registered into the game's Options window (Settings API on
-- modern clients, with a graceful fallback to the legacy interface panel).
-- Every control reads and writes directly into the saved-variable table.

local ADDON, ns = ...
ns.Options = ns.Options or {}
local O = ns.Options

local panel, category
local controls = {}       -- checkbuttons refreshed from their getters
local intervalSlider, channelBtn, modeBtn

-- Checkbox bound to a getter/setter pair.
local function AddCheck(parent, label, tooltip, get, set, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    local fs = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetText(label)
    cb:SetScript("OnClick", function(self)
        set(self:GetChecked() and true or false)
        O:Refresh()
    end)
    cb:SetScript("OnEnter", function(self)
        if not tooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(label)
        GameTooltip:AddLine(tooltip, 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", GameTooltip_Hide)
    cb._get = get
    controls[#controls + 1] = cb
    return cb
end

function O:Build()
    if panel then return end

    panel = CreateFrame("Frame", "WeatherCycleOptionsPanel")
    panel.name = "Weather-Cycle"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Weather-Cycle")

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetPoint("RIGHT", -32, 0)
    sub:SetJustifyH("LEFT")
    sub:SetText("Set and cycle the weather and time of day for your party or raid. Type |cffffd200/wc|r to open the scene picker.")

    local x = 20
    local y = -70

    AddCheck(panel, "Broadcast immersive lines to chat",
        "Send a short scene description to your group (or an emote when solo) so everyone reads the change.",
        function() return ns.db.broadcast end,
        function(v) ns.db.broadcast = v end, x, y)
    y = y - 28

    AddCheck(panel, "Sync scenes with group members",
        "Send a hidden message so other Weather-Cycle users see the matching on-screen effect.",
        function() return ns.db.sync end,
        function(v) ns.db.sync = v end, x, y)
    y = y - 28

    AddCheck(panel, "React to scenes set by others",
        "Show the toast and tint when a group member running Weather-Cycle sets a scene.",
        function() return ns.db.receiveSync end,
        function(v) ns.db.receiveSync = v end, x, y)
    y = y - 28

    AddCheck(panel, "Show the on-screen scene toast",
        "Display the themed pop-up with the scene name and description.",
        function() return ns.db.toast end,
        function(v) ns.db.toast = v end, x, y)
    y = y - 28

    AddCheck(panel, "Tint the screen on a scene change",
        "Briefly wash the screen in the scene's colour for atmosphere.",
        function() return ns.db.screenTint end,
        function(v) ns.db.screenTint = v end, x, y)
    y = y - 28

    AddCheck(panel, "Fire bound toys",
        "When a toy is bound to a scene (see /wc toy), use it on setting that scene. Optional.",
        function() return ns.db.toys end,
        function(v) ns.db.toys = v end, x, y)
    y = y - 28

    AddCheck(panel, "Hide the minimap button",
        "Remove the minimap button. You can still open the window with /wc.",
        function() return ns.db.minimap.hide end,
        function(v) ns.db.minimap.hide = v; if ns.Minimap then ns.Minimap:Update() end end, x, y)
    y = y - 40

    -- Broadcast channel (cycling button)
    local chanLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    chanLabel:SetPoint("TOPLEFT", x, y)
    chanLabel:SetText("Broadcast channel")
    channelBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    channelBtn:SetSize(140, 22)
    channelBtn:SetPoint("TOPLEFT", x + 160, y + 4)
    channelBtn:SetScript("OnClick", function()
        local seq = { "AUTO", "PARTY", "RAID", "SAY", "YELL", "EMOTE" }
        local idx = 1
        for i, v in ipairs(seq) do if v == ns.db.channel then idx = i break end end
        ns.db.channel = seq[(idx % #seq) + 1]
        O:Refresh(); if ns.UI then ns.UI:Refresh() end
    end)
    y = y - 40

    -- Auto-cycle section
    local cycHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    cycHeader:SetPoint("TOPLEFT", x, y)
    cycHeader:SetText("Auto-cycle")
    y = y - 26

    AddCheck(panel, "Enable auto-cycle",
        "Automatically advance the scene on a timer for a living-world feel.",
        function() return ns.db.cycle.enabled end,
        function(v) ns.db.cycle.enabled = v; ns:RefreshCycle() end, x, y)
    y = y - 26

    AddCheck(panel, "Announce cycle changes in chat",
        "Also broadcast the immersive line each time the auto-cycle advances.",
        function() return ns.db.cycle.announce end,
        function(v) ns.db.cycle.announce = v end, x, y)
    y = y - 40

    -- Cycle mode (cycling button)
    local modeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    modeLabel:SetPoint("TOPLEFT", x, y)
    modeLabel:SetText("Cycle affects")
    modeBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    modeBtn:SetSize(140, 22)
    modeBtn:SetPoint("TOPLEFT", x + 160, y + 4)
    modeBtn:SetScript("OnClick", function()
        local seq = { "time", "weather", "both" }
        local idx = 1
        for i, v in ipairs(seq) do if v == ns.db.cycle.mode then idx = i break end end
        ns.db.cycle.mode = seq[(idx % #seq) + 1]
        O:Refresh()
    end)
    y = y - 50

    -- Interval slider
    intervalSlider = CreateFrame("Slider", "WeatherCycleIntervalSlider", panel, "OptionsSliderTemplate")
    intervalSlider:SetPoint("TOPLEFT", x + 6, y)
    intervalSlider:SetWidth(280)
    intervalSlider:SetMinMaxValues(1, 60)
    intervalSlider:SetValueStep(1)
    intervalSlider:SetObeyStepOnDrag(true)
    _G[intervalSlider:GetName() .. "Low"]:SetText("1 min")
    _G[intervalSlider:GetName() .. "High"]:SetText("60 min")
    intervalSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        ns.db.cycle.interval = value
        _G[self:GetName() .. "Text"]:SetText("Cycle interval: " .. value .. " min")
        ns:RefreshCycle()
        if ns.UI then ns.UI:Refresh() end
    end)

    self.panel = panel
end

function O:Refresh()
    if not panel then return end
    for _, cb in ipairs(controls) do
        cb:SetChecked(cb._get() and true or false)
    end
    if channelBtn then channelBtn:SetText(ns.db.channel) end
    if modeBtn then modeBtn:SetText(ns.db.cycle.mode) end
    if intervalSlider then
        intervalSlider:SetValue(ns.db.cycle.interval)
        _G[intervalSlider:GetName() .. "Text"]:SetText("Cycle interval: " .. ns.db.cycle.interval .. " min")
    end
end

function O:Init()
    self:Build()
    if Settings and Settings.RegisterCanvasLayoutCategory then
        category = Settings.RegisterCanvasLayoutCategory(panel, "Weather-Cycle")
        category.ID = "Weather-Cycle"
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
    self:Refresh()
end

function O:Open()
    self:Build()
    self:Refresh()
    if Settings and Settings.OpenToCategory and category then
        Settings.OpenToCategory(category.ID)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel) -- called twice to defeat a Blizzard bug
    end
end
