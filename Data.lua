-- Weather-Cycle : Data.lua
-- Static definitions for every weather and time-of-day "scene" the addon can set.
-- Each scene carries a display name, an icon, an accent colour used by the toast
-- and screen tint, and a small pool of immersive lines that are broadcast to the
-- group. Nothing in this file touches the game state directly; it is pure data.

local ADDON, ns = ...
ns.Data = ns.Data or {}
local D = ns.Data

local ICON = [[Interface\Icons\%s]]

-- ---------------------------------------------------------------------------
-- Weather scenes
-- ---------------------------------------------------------------------------
D.weatherOrder = {
    "clear", "cloudy", "fog", "drizzle", "rain",
    "storm", "thunder", "snow", "blizzard", "sandstorm",
}

D.weather = {
    clear = {
        name = "Clear Skies",
        icon = ICON:format("Spell_Nature_WispSplode"),
        color = { 1.00, 0.92, 0.55 },
        lines = {
            "The clouds part and clear skies stretch overhead.",
            "Sunlight breaks through, warm and bright.",
            "The air stills as the last of the weather clears away.",
        },
    },
    cloudy = {
        name = "Overcast",
        icon = ICON:format("Spell_Nature_EarthBind"),
        color = { 0.70, 0.73, 0.78 },
        lines = {
            "Grey clouds gather, muting the light.",
            "An overcast sky rolls in from the horizon.",
            "The sun disappears behind a thick blanket of cloud.",
        },
    },
    fog = {
        name = "Fog",
        icon = ICON:format("Spell_Nature_Invisibilty"),
        color = { 0.62, 0.65, 0.70 },
        lines = {
            "A thick fog creeps in, softening every shape.",
            "Mist rises from the ground and blurs the horizon.",
            "The world grows hushed beneath a pale veil of fog.",
        },
    },
    drizzle = {
        name = "Drizzle",
        icon = ICON:format("Spell_Frost_FrostBolt02"),
        color = { 0.55, 0.68, 0.82 },
        lines = {
            "A light drizzle mists the air.",
            "Fine rain drifts down, barely more than mist.",
            "The faintest rain begins to fall, cool and soft.",
        },
    },
    rain = {
        name = "Rain",
        icon = ICON:format("Spell_Frost_FrostBolt02"),
        color = { 0.45, 0.62, 0.85 },
        lines = {
            "Rain begins to fall, pattering against the ground.",
            "A steady rain sweeps across the land.",
            "Droplets darken the earth as the rain sets in.",
        },
    },
    storm = {
        name = "Storm",
        icon = ICON:format("Spell_Nature_Cyclone"),
        color = { 0.35, 0.42, 0.62 },
        lines = {
            "The wind rises as a storm rolls in.",
            "Dark clouds churn overhead, heavy with rain.",
            "A brooding storm gathers along the horizon.",
        },
    },
    thunder = {
        name = "Thunderstorm",
        icon = ICON:format("Spell_Nature_Lightning"),
        color = { 0.55, 0.45, 0.85 },
        lines = {
            "Thunder rumbles as lightning splits the sky.",
            "A crack of thunder rolls across the heavens.",
            "Lightning flickers and thunder answers close behind.",
        },
    },
    snow = {
        name = "Snowfall",
        icon = ICON:format("Spell_Frost_ChillingBlast"),
        color = { 0.85, 0.92, 1.00 },
        lines = {
            "Snow begins to fall in slow, drifting flakes.",
            "A gentle snowfall settles quietly over the land.",
            "White flakes tumble from a pale grey sky.",
        },
    },
    blizzard = {
        name = "Blizzard",
        icon = ICON:format("Spell_Frost_ArcticWinds"),
        color = { 0.75, 0.85, 1.00 },
        lines = {
            "A howling blizzard tears across the land.",
            "Snow whips sideways as a blizzard descends.",
            "The world vanishes behind a wall of driving snow.",
        },
    },
    sandstorm = {
        name = "Sandstorm",
        icon = ICON:format("Spell_Nature_EarthquakesReserved"),
        color = { 0.85, 0.72, 0.45 },
        lines = {
            "A wall of sand sweeps in on a scouring wind.",
            "Grit fills the air as a sandstorm rises.",
            "The horizon disappears behind churning sand.",
        },
    },
}

-- ---------------------------------------------------------------------------
-- Time-of-day scenes
-- ---------------------------------------------------------------------------
D.timeOrder = { "dawn", "morning", "noon", "dusk", "night", "midnight" }

D.time = {
    dawn = {
        name = "Dawn",
        icon = ICON:format("Spell_Holy_SurgeOfLight"),
        color = { 1.00, 0.70, 0.50 },
        lines = {
            "The first light of dawn spills over the horizon.",
            "Pale morning light creeps slowly across the sky.",
        },
    },
    morning = {
        name = "Morning",
        icon = ICON:format("Spell_Nature_WispSplode"),
        color = { 0.90, 0.85, 0.60 },
        lines = {
            "The morning sun climbs, bright and clear.",
            "Daylight settles fully across the land.",
        },
    },
    noon = {
        name = "Midday",
        icon = ICON:format("Spell_Fire_Fire"),
        color = { 1.00, 0.95, 0.70 },
        lines = {
            "The sun hangs high at its zenith.",
            "Midday light blazes down from directly overhead.",
        },
    },
    dusk = {
        name = "Dusk",
        icon = ICON:format("Spell_Shadow_Twilight"),
        color = { 0.95, 0.55, 0.40 },
        lines = {
            "The sun sinks low, painting the sky in amber and rose.",
            "Twilight settles in as the day draws to a close.",
        },
    },
    night = {
        name = "Night",
        icon = ICON:format("Spell_Nature_StarFall"),
        color = { 0.35, 0.40, 0.60 },
        lines = {
            "Night falls, and the stars wheel slowly into view.",
            "Darkness settles over the land beneath a field of stars.",
        },
    },
    midnight = {
        name = "Midnight",
        icon = ICON:format("Spell_Shadow_SummonInfernal"),
        color = { 0.20, 0.25, 0.45 },
        lines = {
            "The dead of night holds the world in silence.",
            "At the stroke of midnight the moon rides high and cold.",
        },
    },
}

-- ---------------------------------------------------------------------------
-- Accessors
-- ---------------------------------------------------------------------------

-- Returns the ordered key list for a given kind ("weather" or "time").
function D:Order(kind)
    return kind == "time" and self.timeOrder or self.weatherOrder
end

-- Returns the scene definition table for a kind + key, or nil if unknown.
function D:Get(kind, key)
    local set = kind == "time" and self.time or self.weather
    return set and set[key]
end

-- Returns true if key is a valid scene for the given kind.
function D:IsValid(kind, key)
    return self:Get(kind, key) ~= nil
end

-- Returns a random immersive line for a scene (falls back to the name).
function D:Line(kind, key)
    local def = self:Get(kind, key)
    if not def then return nil end
    local lines = def.lines
    if lines and #lines > 0 then
        return lines[math.random(#lines)]
    end
    return def.name
end

-- Returns the next key in the ordered list, wrapping around. Used by the
-- auto-cycle engine to advance the time of day in a natural sequence.
function D:Next(kind, key)
    local order = self:Order(kind)
    for i = 1, #order do
        if order[i] == key then
            return order[(i % #order) + 1]
        end
    end
    return order[1]
end

-- Returns a random key for the kind, guaranteed different from `avoid`
-- when more than one option exists. Used for random weather cycling.
function D:Random(kind, avoid)
    local order = self:Order(kind)
    if #order <= 1 then return order[1] end
    local key
    repeat
        key = order[math.random(#order)]
    until key ~= avoid
    return key
end
