-- Weather-Cycle : Toast.lua
-- The visual feedback when a scene is set: a themed toast that fades in near the
-- top of the screen with the scene's icon, name and flavour line, plus a brief
-- full-screen colour wash so the mood change is felt as well as read.

local ADDON, ns = ...
ns.Toast = ns.Toast or {}
local T = ns.Toast

local toast, tint

-- Build the toast frame lazily so nothing is created before PLAYER_LOGIN.
local function EnsureFrames()
    if toast then return end

    -- Full-screen colour wash, drawn behind the toast, very low alpha.
    tint = CreateFrame("Frame", nil, UIParent)
    tint:SetAllPoints(UIParent)
    tint:SetFrameStrata("BACKGROUND")
    tint.tex = tint:CreateTexture(nil, "BACKGROUND")
    tint.tex:SetAllPoints(tint)
    tint.tex:SetColorTexture(1, 1, 1, 1)
    tint:SetAlpha(0)
    tint:Hide()

    local tintAnim = tint:CreateAnimationGroup()
    local tIn = tintAnim:CreateAnimation("Alpha")
    tIn:SetFromAlpha(0); tIn:SetToAlpha(0.16); tIn:SetDuration(0.5); tIn:SetOrder(1)
    local tHold = tintAnim:CreateAnimation("Alpha")
    tHold:SetFromAlpha(0.16); tHold:SetToAlpha(0.16); tHold:SetDuration(1.0); tHold:SetOrder(2)
    local tOut = tintAnim:CreateAnimation("Alpha")
    tOut:SetFromAlpha(0.16); tOut:SetToAlpha(0); tOut:SetDuration(1.4); tOut:SetOrder(3)
    tintAnim:SetScript("OnFinished", function() tint:Hide() end)
    tint.anim = tintAnim

    -- The toast card itself.
    toast = CreateFrame("Frame", "WeatherCycleToast", UIParent, "BackdropTemplate")
    toast:SetSize(340, 74)
    toast:SetPoint("TOP", UIParent, "TOP", 0, -140)
    toast:SetFrameStrata("HIGH")
    toast:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    toast:SetBackdropColor(0.05, 0.05, 0.07, 0.92)
    toast:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    -- Accent stripe down the left edge, coloured per scene.
    toast.accent = toast:CreateTexture(nil, "ARTWORK")
    toast.accent:SetPoint("TOPLEFT", 3, -3)
    toast.accent:SetPoint("BOTTOMLEFT", 3, 3)
    toast.accent:SetWidth(4)
    toast.accent:SetColorTexture(1, 1, 1, 1)

    toast.icon = toast:CreateTexture(nil, "ARTWORK")
    toast.icon:SetSize(44, 44)
    toast.icon:SetPoint("LEFT", 16, 0)
    toast.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    toast.title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    toast.title:SetPoint("TOPLEFT", toast.icon, "TOPRIGHT", 12, -2)
    toast.title:SetPoint("RIGHT", -12, 0)
    toast.title:SetJustifyH("LEFT")

    toast.line = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toast.line:SetPoint("TOPLEFT", toast.title, "BOTTOMLEFT", 0, -4)
    toast.line:SetPoint("RIGHT", -12, 0)
    toast.line:SetJustifyH("LEFT")
    toast.line:SetHeight(34)
    toast.line:SetWordWrap(true)

    local anim = toast:CreateAnimationGroup()
    local fadeIn = anim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.35); fadeIn:SetOrder(1)
    local hold = anim:CreateAnimation("Alpha")
    hold:SetFromAlpha(1); hold:SetToAlpha(1); hold:SetDuration(3.2); hold:SetOrder(2)
    local fadeOut = anim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0); fadeOut:SetDuration(1.0); fadeOut:SetOrder(3)
    anim:SetScript("OnFinished", function() toast:Hide() end)
    toast.anim = anim
    toast:Hide()
end

-- Show the toast for a scene. `sender` (optional) labels a scene that arrived
-- from another player via group sync.
function T:Show(kind, key, sender)
    local def = ns.Data:Get(kind, key)
    if not def then return end
    EnsureFrames()

    local c = def.color or { 1, 1, 1 }
    toast.accent:SetColorTexture(c[1], c[2], c[3], 1)
    toast:SetBackdropBorderColor(c[1] * 0.9, c[2] * 0.9, c[3] * 0.9, 1)
    toast.icon:SetTexture(def.icon)

    local heading = def.name
    if sender then
        heading = ("%s |cffaaaaaa(%s)|r"):format(def.name, sender)
    end
    toast.title:SetText(heading)
    toast.title:SetTextColor(c[1], c[2], c[3])
    toast.line:SetText(ns.Data:Line(kind, key))

    toast.anim:Stop()
    toast:SetAlpha(0)
    toast:Show()
    toast.anim:Play()

    if ns.db and ns.db.screenTint then
        tint.anim:Stop()
        tint.tex:SetColorTexture(c[1], c[2], c[3], 1)
        tint:SetAlpha(0)
        tint:Show()
        tint.anim:Play()
    end
end
