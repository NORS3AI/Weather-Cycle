-- Weather-Cycle : Broadcast.lua
-- Turns a scene change into words. Two independent channels:
--   Chat  : an immersive line sent to party/raid/say/emote so *everyone* in the
--           group reads the scene, whether or not they run the addon.
--   Sync  : a compact hidden addon message so group members who *do* run the
--           addon get the matching on-screen toast and screen tint.

local ADDON, ns = ...
ns.Broadcast = ns.Broadcast or {}
local B = ns.Broadcast

-- Send the immersive flavour line for a scene to the resolved chat channel.
function B:Chat(kind, key)
    local line = ns.Data:Line(kind, key)
    if not line then return end
    local channel = ns:ResolveChannel()
    if not channel then return end

    if channel == "EMOTE" then
        -- Emote reads naturally when solo or when you want a softer touch.
        SendChatMessage(line, "EMOTE")
    else
        SendChatMessage(line, channel)
    end
end

-- Send a hidden sync message so other Weather-Cycle users mirror the scene.
-- prefix/sep are passed in from Core so the wire format stays in one place.
function B:Sync(kind, key, prefix, sep)
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
    if not IsInGroup() then return end
    local channel = IsInRaid() and "RAID" or "PARTY"
    -- Format: version SEP op SEP kind SEP key
    local msg = table.concat({ "1", "SET", kind, key }, sep)
    C_ChatInfo.SendAddonMessage(prefix, msg, channel)
end
