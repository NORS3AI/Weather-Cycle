-- Weather-Cycle : Minimap.lua
-- A self-contained minimap button (no external libraries). Left-click toggles
-- the main window, right-click opens the options panel, and the button can be
-- dragged around the minimap ring with its angle saved between sessions.

local ADDON, ns = ...
ns.Minimap = ns.Minimap or {}
local M = ns.Minimap

local button

-- Position the button on the minimap ring for a given angle (degrees).
local function UpdatePosition()
    if not button then return end
    local angle = math.rad(ns.db.minimap.angle or 210)
    local radius = 80
    button:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * radius, math.sin(angle) * radius)
end

local function OnDragUpdate(self)
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    ns.db.minimap.angle = math.deg(math.atan2(py - my, px - mx))
    UpdatePosition()
end

function M:Init()
    if button then self:Update() return end

    button = CreateFrame("Button", "WeatherCycleMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
    icon:SetPoint("CENTER", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("CENTER", -1, 1)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            if ns.Options and ns.Options.Open then ns.Options:Open() end
        else
            if ns.UI then ns.UI:Toggle() end
        end
    end)

    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", OnDragUpdate)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Weather-Cycle")
        local w = ns.Data:Get("weather", ns.db.current.weather)
        local t = ns.Data:Get("time", ns.db.current.time)
        GameTooltip:AddLine(("|cffffffff%s, %s|r"):format(
            w and w.name or "?", t and t.name or "?"), 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: open the scene picker", 0.6, 0.8, 1)
        GameTooltip:AddLine("Right-click: open options", 0.6, 0.8, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    UpdatePosition()
    self:Update()
end

-- Show or hide the button according to the saved setting.
function M:Update()
    if not button then return end
    if ns.db.minimap.hide then button:Hide() else button:Show() end
    UpdatePosition()
end
