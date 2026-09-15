# Weather-Cycle

**Set and cycle the weather and time of day for your party or raid — an immersion tool for roleplayers.**

Weather-Cycle brings the feel of the in-game weather/time toys to your group
roleplay. Pick a scene — *Rain*, *Blizzard*, *Dusk*, *Midnight* — and everyone
in your party or raid gets a short, atmospheric line in chat, while anyone else
running the addon sees a themed on-screen toast and a brief colour wash. Set an
auto-cycle and the world will drift from dawn to dusk (or roll through changing
weather) on its own for a living-world feel.

---

## How it works (please read)

World of Warcraft does **not** give addons a way to change the *actual*
server-side weather or time of day for other players — that is controlled by
Blizzard and by specific in-game toys. Weather-Cycle instead creates the
**shared illusion** of a changing sky, which is exactly what group roleplay
needs:

- **Chat narration** — a short immersive line is sent to your party/raid (or as
  an emote when you are solo), so *everyone* reads the scene change, addon or
  not.
- **Group sync** — a hidden addon message tells other Weather-Cycle users to
  show the matching toast and screen tint, so the whole group shares the mood.
- **Optional toys** — if you own a toy that produces a real weather or lighting
  effect, you can bind it to a scene so setting that scene also fires the toy
  (see *Toys* below). This is entirely optional; the roleplay works without any
  toy.

---

## Features

- Ten weather scenes (clear, overcast, fog, drizzle, rain, storm, thunderstorm,
  snow, blizzard, sandstorm) and six time-of-day scenes (dawn, morning, midday,
  dusk, night, midnight), each with its own colour, icon and flavour text.
- A movable scene-picker window with tooltips.
- Themed on-screen toast and an optional brief full-screen colour wash.
- Party/raid **chat broadcasting** with a choice of channel
  (auto / party / raid / say / yell / emote).
- Silent **group synchronisation** so other users share the on-screen scene.
- An **auto-cycle** engine that advances the time of day, rolls new weather, or
  both, on a configurable interval.
- A draggable minimap button and a full options panel.
- Optional per-scene **toy bindings**.

---

## Installation

1. Copy the `Weather-Cycle` folder into your
   `World of Warcraft/_retail_/Interface/AddOns/` directory. The folder must
   contain `WeatherCycle.toc` at its top level.
2. Restart the game or run `/reload`.
3. Type `/wc` to open the scene picker.

> **Interface version:** `WeatherCycle.toc` targets a recent retail patch. If
> the game marks the addon "out of date", either enable *Load out of date
> AddOns* on the character-select AddOns screen, or update the `## Interface:`
> line to your current patch's value.

---

## Usage

Open the window with the minimap button or `/wc`, then click any weather or
time-of-day button to set that scene. Whoever sets a scene "drives" it for the
group.

### Slash commands

| Command | Description |
| --- | --- |
| `/wc` | Toggle the main window |
| `/wc show` / `/wc hide` | Open or close the window |
| `/wc config` | Open the options panel |
| `/wc weather <key>` | Set a weather scene (e.g. `/wc weather storm`) |
| `/wc time <key>` | Set a time-of-day scene (e.g. `/wc time dusk`) |
| `/wc list` | List every scene key |
| `/wc cycle on` / `off` | Toggle the auto-cycle |
| `/wc cycle interval <m>` | Set the cycle interval in minutes |
| `/wc cycle mode <time\|weather\|both>` | Choose what the cycle advances |
| `/wc broadcast on` / `off` | Toggle chat broadcasting |
| `/wc channel <name>` | `AUTO`, `PARTY`, `RAID`, `SAY`, `YELL` or `EMOTE` |
| `/wc minimap` | Toggle the minimap button |
| `/wc toy <weather\|time> <key> <itemID>` | Bind a toy to a scene (blank id clears) |
| `/wc help` | Show the command list |

**Scene keys**

- Weather: `clear`, `cloudy`, `fog`, `drizzle`, `rain`, `storm`, `thunder`,
  `snow`, `blizzard`, `sandstorm`
- Time: `dawn`, `morning`, `noon`, `dusk`, `night`, `midnight`

### Toys (optional)

If you own a toy with a real environmental effect, bind it to a scene and enable
*Fire bound toys* in the options:

```
/wc toy weather storm 54212      -- fire item 54212 whenever you set "storm"
/wc toy time night 122298        -- fire item 122298 whenever you set "night"
/wc toy weather storm            -- (no id) clears the binding
```

The toy is only used if you actually own it and are out of combat.

---

## Options

Open with `/wc config` or the *Options → AddOns → Weather-Cycle* panel:

- Broadcast immersive lines to chat, and which channel to use.
- Sync scenes to group members, and react to scenes set by others.
- Show the on-screen toast and/or the screen tint.
- Fire bound toys.
- Hide the minimap button.
- Auto-cycle: enable, interval, what it affects, and whether it announces in chat.

Settings are saved account-wide in `WeatherCycleDB`.

---

## Notes for a group

- Only the person setting the scene needs to broadcast; everyone else just needs
  *React to scenes set by others* enabled (on by default) to share the visuals.
- If several people are setting scenes, the most recent one wins for everyone —
  pick a "scene director" for a calmer session.
- Nothing here affects combat, instances, or other players' game state; it is
  purely cosmetic roleplay flavour.
