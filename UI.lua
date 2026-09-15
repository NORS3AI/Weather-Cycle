-- Weather-Cycle : UI.lua
-- The main window: a movable panel with a grid of weather buttons and a grid of
-- time-of-day buttons, plus a footer of quick toggles (broadcast channel,
-- auto-cycle) and a shortcut to the options panel. Clicking a scene button
-- applies that scene through the Core engine.

local ADDON, ns = ...
ns.UI = ns.UI or {}
local UI = ns.UI

local frame
local weatherButtons, timeButtons = {}, {}
local channelButton, cycleButton, sceneText

local ICON_SIZE = 46
local PAD = 10

-- Create one clickable scene button (icon + accent border + tooltip).
local function CreateSceneButton(parent, kind, key)
    local def = ns.Data:Get(kind, key)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(ICON_SIZE, ICON_SIZE)
    b.kind, b.key = kind, key

    b:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    local c = def.color or { 1, 1, 1 }
    b:SetBackdropBorderColor(c[1] * 0.6, c[2] * 0.6, c[3] * 0.6, 1)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    b.icon:SetTexture(def.icon)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    b.selected = b:CreateTexture(nil, "OVERLAY")
    b.selected:SetPoint("TOPLEFT", -2, 2)
    b.selected:SetPoint("BOTTOMRIGHT", 2, -2)
    b.selected:SetColorTexture(c[1], c[2], c[3], 0.35)
    b.selected:Hide()

    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    b:SetScript("OnClick", function()
        ns:SetScene(kind, key)
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(def.name, c[1], c[2], c[3])
        GameTooltip:AddLine(ns.Data:Line(kind, key), 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to set this scene for your group.", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    return b
end

-- Lay a set of scene buttons out in a grid, returning the total height used.
local function LayoutGrid(parent, order, kind, store, anchor, yOffset, perRow)
    local x, y = PAD, yOffset
    for i, key in ipairs(order) do
        local b = CreateSceneButton(parent, kind, key)
        local col = (i - 1) % perRow
        local row = math.floor((i - 1) / perRow)
        b:SetPoint("TOPLEFT", anchor, "TOPLEFT", PAD + col * (ICON_SIZE + 6), y - row * (ICON_SIZE + 6))
        store[key] = b
    end
    local rows = math.ceil(#order / perRow)
    return rows * (ICON_SIZE + 6)
end

function UI:Build()
    if frame then return end

    -- Width fits the widest row (the six time-of-day buttons); height is fixed
    -- up after the footer is laid out below.
    frame = CreateFrame("Frame", "WeatherCycleFrame", UIParent, "BackdropTemplate")
    frame:SetSize(6 * (ICON_SIZE + 6) + PAD * 2, 320)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        ns.db.uiPoint = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    -- Title bar
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Weather-Cycle")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    -- Weather section
    local wLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    wLabel:SetPoint("TOPLEFT", PAD + 2, -40)
    wLabel:SetText("Weather")
    local wAnchor = CreateFrame("Frame", nil, frame)
    wAnchor:SetPoint("TOPLEFT", 0, -54)
    wAnchor:SetSize(1, 1)
    local wHeight = LayoutGrid(frame, ns.Data.weatherOrder, "weather", weatherButtons, wAnchor, 0, 5)

    -- Time section
    local tLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tLabel:SetPoint("TOPLEFT", PAD + 2, -54 - wHeight - 8)
    tLabel:SetText("Time of Day")
    local tAnchor = CreateFrame("Frame", nil, frame)
    tAnchor:SetPoint("TOPLEFT", 0, -54 - wHeight - 22)
    tAnchor:SetSize(1, 1)
    local tHeight = LayoutGrid(frame, ns.Data.timeOrder, "time", timeButtons, tAnchor, 0, 6)

    -- Footer controls
    local footY = -54 - wHeight - 22 - tHeight - 12

    channelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    channelButton:SetSize(150, 22)
    channelButton:SetPoint("TOPLEFT", PAD, footY)
    channelButton:SetScript("OnClick", function()
        local seq = { "AUTO", "PARTY", "RAID", "SAY", "YELL", "EMOTE" }
        local cur = ns.db.channel
        local idx = 1
        for i, v in ipairs(seq) do if v == cur then idx = i break end end
        ns.db.channel = seq[(idx % #seq) + 1]
        UI:Refresh()
        if ns.Options and ns.Options.Refresh then ns.Options:Refresh() end
    end)
    channelButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Broadcast channel")
        GameTooltip:AddLine("Where the immersive lines are sent. AUTO picks raid, party, or a solo emote automatically.", 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    channelButton:SetScript("OnLeave", GameTooltip_Hide)

    cycleButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cycleButton:SetSize(150, 22)
    cycleButton:SetPoint("TOPRIGHT", -PAD, footY)
    cycleButton:SetScript("OnClick", function()
        ns.db.cycle.enabled = not ns.db.cycle.enabled
        ns:RefreshCycle()
        if ns.Options and ns.Options.Refresh then ns.Options:Refresh() end
    end)
    cycleButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Auto-cycle")
        GameTooltip:AddLine(("Advance %s automatically every %d minutes."):format(ns.db.cycle.mode, ns.db.cycle.interval), 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    cycleButton:SetScript("OnLeave", GameTooltip_Hide)

    local optButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    optButton:SetSize(90, 22)
    optButton:SetPoint("TOP", 0, footY - 26)
    optButton:SetText("Options")
    optButton:SetScript("OnClick", function()
        if ns.Options and ns.Options.Open then ns.Options:Open() end
    end)

    sceneText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sceneText:SetPoint("BOTTOM", 0, 12)
    sceneText:SetPoint("LEFT", PAD, 0)
    sceneText:SetPoint("RIGHT", -PAD, 0)
    sceneText:SetJustifyH("CENTER")

    -- Grow the frame to fit everything, then restore saved position.
    frame:SetHeight(-footY + 64)
    if ns.db.uiPoint then
        local p = ns.db.uiPoint
        frame:ClearAllPoints()
        frame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    end

    frame:Hide()
    self.frame = frame
    self:Refresh()
end

-- Refresh all dynamic labels and the selected-scene highlight.
function UI:Refresh()
    if not frame then return end
    local cur = ns.db.current

    for key, b in pairs(weatherButtons) do
        b.selected:SetShown(key == cur.weather)
    end
    for key, b in pairs(timeButtons) do
        b.selected:SetShown(key == cur.time)
    end

    if channelButton then
        channelButton:SetText("Channel: " .. ns.db.channel)
    end
    if cycleButton then
        cycleButton:SetText(ns.db.cycle.enabled
            and ("Cycle: On (%dm)"):format(ns.db.cycle.interval)
            or "Cycle: Off")
    end
    if sceneText then
        local w = ns.Data:Get("weather", cur.weather)
        local t = ns.Data:Get("time", cur.time)
        sceneText:SetText(("Current scene: |cffffd200%s|r, |cffffd200%s|r")
            :format(w and w.name or cur.weather, t and t.name or cur.time))
    end
end

function UI:Init()
    self:Build()
end

function UI:Show()
    self:Build()
    self:Refresh()
    frame:Show()
end

function UI:Hide()
    if frame then frame:Hide() end
end

function UI:Toggle()
    self:Build()
    if frame:IsShown() then frame:Hide() else self:Show() end
end
