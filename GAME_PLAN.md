# Embervale Idle — Game Plan

Working title. This is an original concept inspired by the progression structure of RuneScape, the offline systems of Melvor Idle, and the disciplined AI-assisted Godot workflow shown in the reference video.

## 1. The pitch

**Queue an adventure, then watch your hero live it.**

Embervale Idle is a single-player idle RPG set in a compact, handcrafted 3D fantasy world. The player prepares journeys, chooses training activities, equips tools and supplies, and sets safety rules. Their hero then travels through the world and performs those plans automatically—whether the game is open or closed.

The long-term goal is to restore the broken Waystones connecting Embervale. Rebuilding them permanently changes the visible world: bridges reopen, workshops come alive, new paths appear, and dangerous ruins become reachable.

The game should feel like:

- RuneScape's classless skills, interconnected crafting, exploration, and unlocks.
- Melvor Idle's readable timers, preparation, mastery, and offline progress.
- A cozy low-poly 3D diorama where progress is visible instead of represented only by menus.

It should not try to be an MMO, a RuneScape clone, or a traditional action RPG.

## 2. The unique hook

Most idle RPGs abstract the world into screens. Most 3D RPGs require continuous control. Embervale Idle combines the two:

1. **Plan:** Choose a destination, activity, amount or duration, loadout, and return condition.
2. **Depart:** The hero physically travels along paths in the 3D world.
3. **Work:** Gathering, processing, and combat advance through a deterministic simulation.
4. **Adapt:** A queue can continue, branch to a fallback, or stop when inventory, supplies, or safety rules require it.
5. **Return:** The player receives a concise journey report and spends the gains on tools, skills, repairs, and new routes.

The 3D presentation must communicate useful state: where the hero is, what they are doing, how dangerous the area is, and how the world has changed. It is not decorative wallpaper.

## 3. Design pillars

### A. Preparation is the gameplay

The meaningful decisions happen before and between activities: route, gear, food, inventory space, activity order, quantity, and risk tolerance.

### B. One character, many skills

There are no classes. Using a skill earns XP, levels unlock better actions and equipment, and skills feed one another.

### C. A small world that visibly grows

Prefer one memorable valley with dense connections over a large empty map. Major milestones must alter the 3D environment.

### D. Idle time must tell a story

The return screen should explain the journey, not merely dump numbers: locations reached, levels gained, resources used, rare finds, stops, and setbacks.

### E. Respect the player's time

No gear deletion on normal defeat, no surprise permanent loss, no mandatory clicking while an activity runs, and no monetized time skips.

## 4. Player experience

### First session

The player arrives in Emberstead with a worn axe and a damaged Waystone. A short guided plan teaches the full game:

1. Walk to Whisperwood.
2. Cut 10 pine logs.
3. Return to town.
4. Repair the forge fire.
5. Mine copper at the newly marked quarry.
6. Smelt a copper bar and craft a better axe.

Within 20 minutes, the player has used travel, gathering, inventory, processing, crafting, skill XP, the action queue, and a visible world upgrade.

### Daily rhythm

- **30–90 seconds:** Review the journey report and collect completed goals.
- **2–5 minutes:** Craft upgrades, change equipment, and create the next plan.
- **Optional active viewing:** Follow the hero, inspect the world, read lore, compare equipment, or revise the remaining queue.
- **Milestone sessions:** Prepare for a new region, dungeon, or Waystone repair.

## 5. MVP: the first complete playable region

The MVP should prove the entire experience with a polished 2–4 hour progression arc and useful offline play afterward.

### World

- Emberstead village hub
- Whisperwood forest
- Copperfall quarry
- Mirrorpond fishing bank
- Old Road combat area
- One small ruin with a final guardian
- One bridge and one Waystone that visibly change when restored

### Skills

Use six skills, all built on the same reusable action framework:

- **Woodcutting:** Logs and fuel
- **Mining:** Ore and stone
- **Fishing:** Raw food and rare salvage
- **Cooking:** Safe travel and combat supplies
- **Smithing:** Bars, tools, and basic equipment
- **Combat:** One combined MVP level; split into styles only after the core loop works

Level range is 1–20 for the slice. Each skill needs only 3–5 meaningful unlocks.

### Content budget

- About 30 items
- 12–15 recipes
- 8 gathering actions
- 5 normal enemies and 1 guardian
- 6 short quests or restoration goals
- 3 tool tiers
- 8–10 equipment pieces
- 3 visible settlement/world upgrades
- 5–8 hours of offline storage, upgradeable later

### Required features

- Action queue with travel, gather, process, craft, and combat steps
- Repeat by quantity, duration, or “until inventory reserve”
- Stop conditions for full inventory, missing inputs, low food, low health, and defeat
- Versioned local save
- Offline simulation and a clear return report
- 3D character navigation and activity animations
- Inventory, equipment, skills, recipes, map, queue, and report UI
- A beginning, a guardian encounter, and a region-completion moment

### Explicitly excluded from the MVP

- Multiplayer, trading, clans, or a server backend
- A seamless giant open world
- Manual/twitch combat
- Procedural world generation
- More than one region
- Player housing, farming, pets, prestige, or seasonal events
- Mobile release and cloud saves
- Runtime generative AI

## 6. Example progression chain

The systems should form a loop rather than six unrelated progress bars:

```text
Woodcutting -> fuel -------------------+
                                        v
Mining -> copper ore -> Smithing -> better tools
   |                              -> better weapon
   v                                      |
stone -> bridge repair                    v
Fishing -> Cooking -> travel food -> Combat -> Waystone shard
                                               |
                                               v
                                   restore region / unlock paths
```

Example early decisions:

- Carry more food for a longer Old Road trip, or leave space for loot.
- Spend copper on an axe for faster woodcutting, or a sword for safer combat.
- Repair the bridge for a short route, or upgrade the forge first.
- Queue a safe fixed quantity, or continue until a reserve threshold is reached.

## 7. Idle and offline rules

This is the foundation and should be implemented before most content.

### Simulation model

Each action is data with:

- duration
- location
- skill and XP reward
- item inputs and outputs
- equipment and level requirements
- success/failure rules
- stop conditions
- visual animation/state

The game simulation owns the truth. The 3D character only visualizes that state. Animation events and physics must never decide rewards.

When the game closes, save the current action, fractional progress, queue, player state, last trusted timestamp, and random seed. On return, advance the same simulation using elapsed time. Long simple activities should be calculated in batches; combat can advance from one meaningful event to the next rather than frame by frame.

### Safe failure

- If food reaches the player's reserve or health reaches the retreat threshold, return to town.
- On defeat, keep equipped gear and return with reduced unbanked common materials.
- If the inventory is full or inputs run out, attempt the configured fallback; otherwise stop safely.
- Negative clock changes are clamped. This is a single-player game, so do not spend development time fighting harmless clock manipulation during the MVP.

### Return report

Show:

- elapsed time and completed plan steps
- XP and levels gained
- items gained, consumed, and lost
- enemies defeated and rare drops
- why the plan ended or what is still running
- one suggested next action, such as a newly unlocked recipe

## 8. Combat

Combat should be hands-off but strategically configurable.

The player chooses equipment, food, target, stance, auto-eat threshold, retreat threshold, and maximum kills or duration. Combat resolves on timed attacks using accuracy, evasion, damage, defence, and enemy traits. The hero and enemy animate the results in 3D.

For the MVP:

- Use one player attack timer and one enemy attack timer.
- Include physical damage, armour, accuracy, evasion, and food healing.
- Give enemies one readable trait each, such as armoured, fast, or heavy-hitting.
- Make the guardian a preparation check, not a reflex test.
- Avoid active abilities, elemental systems, status stacks, and a combat triangle until the basic numbers are enjoyable.

## 9. 3D world and presentation

Use a stylized low-poly look with a slightly elevated third-person or diorama camera. It is achievable, readable at distance, and forgiving for a small asset library.

### Interaction

- Clicking a world location opens its activities and travel time.
- Selecting an activity previews requirements, expected rates, risks, and queue impact.
- The camera can follow the hero or jump to the current activity.
- A map overlay provides direct planning without forcing the player to hunt for hotspots.

### Visible progression

- Repairing the forge adds fire, smoke, an NPC, and new crafting stations.
- Repairing the bridge replaces a blocked route and reduces travel time.
- Restoring the Waystone adds light, vegetation, ambient life, and access to the ruin.

### Asset rule

Create a one-page style guide before producing final assets: shape language, proportions, camera angle, lighting, material roughness, palette, UI treatment, and animation exaggeration. Every generated or purchased asset must be checked against it.

## 10. Technical plan

### Recommended stack

- **Engine:** Godot 4.7.1 stable
- **Language:** GDScript
- **First platform:** Windows desktop
- **3D pipeline:** Blender or compatible low-poly `.glb` assets
- **Source control:** Git from the first prototype

### Architecture

Keep the simulation independent from scenes and visuals:

```text
Content Definitions
  Items / Skills / Recipes / Enemies / Locations / Actions
                         |
                         v
Game State <-> Action Queue <-> Deterministic Simulator
    |                               |
    v                               v
Save System                    Journey Event Log
    |                               |
    +-------------+-----------------+
                  v
          UI and 3D World View
```

Suggested responsibilities:

- `GameState`: skills, inventory, equipment, quests, unlocks, current plan
- `Simulator`: travel, action cycles, combat events, rewards, stop conditions
- `ActionQueue`: validates and sequences player plans
- `ContentDB`: loads immutable content definitions
- `SaveSystem`: versioned serialization, backup save, migration, timestamps
- `WorldView`: renders the current location/action and navigation
- `ReportBuilder`: converts simulation events into the return summary

Use custom Godot Resources for authored content definitions and JSON or another explicit versioned structure for save data. Do not serialize live scene nodes as the canonical save.

### Critical automated tests

- Sixty minutes simulated online and offline produce equivalent results.
- Fractional action progress survives save/load.
- Every queue stop condition ends at the correct event.
- Full inventory, missing inputs, defeat, and retreat cannot duplicate items.
- Saves load after a content update and recover from one corrupt primary file.
- The simulator can process the maximum offline window quickly.

## 11. Ten-week vertical-slice roadmap

Assumption: one developer using AI assistance for roughly 15–25 focused hours per week. Double the calendar estimate if learning both programming and Godot from scratch.

### Week 0 — design lock

- Confirm the pitch, art direction, camera, and player controls.
- Make three concept images: world view, activity selection, return report.
- Finalize the MVP content table and naming conventions.
- Write a build brief detailed enough that another developer could implement it.

**Gate:** The full first-session loop can be explained in one page without contradictions.

### Week 1 — simulation proof

- Implement skills, inventory, one gathering action, queue, save/load, and offline calculation without 3D art.
- Add tests comparing online and offline rewards.

**Gate:** Closing for ten minutes produces exactly the expected logs and XP.

### Weeks 2–3 — spatial proof

- Build a greybox town, forest, quarry, lake, and road.
- Add hero navigation, camera, interaction markers, and gathering animations.
- Connect world locations to the action queue.

**Gate:** The player can queue “travel, gather, return” and understand it entirely from the 3D view and HUD.

### Weeks 4–5 — production loop

- Add all six skills, recipes, equipment, banking, resource reserves, and tool tiers.
- Add the return report and new-unlock notifications.
- Balance the first 60 minutes.

**Gate:** The copper tool loop is enjoyable and no UI requires developer knowledge.

### Week 6 — combat and risk

- Add enemies, equipment stats, food, auto-eat, retreat, defeat, and the guardian.
- Test online/offline combat equivalence and edge cases.

**Gate:** A player can predict why a fight is safe or dangerous before starting it.

### Week 7 — progression and ending

- Add restoration goals, quests, bridge repair, forge upgrade, Waystone change, and credits/region-complete state.

**Gate:** The slice has a clear beginning, escalating goals, climax, and payoff.

### Weeks 8–9 — art, audio, and usability

- Replace only the most visible greybox assets.
- Add consistent materials, lighting, VFX, activity sounds, ambience, and UI feedback.
- Run fresh-player tests and fix the three largest points of confusion per round.

**Gate:** The game communicates current action, progress, danger, and queue status at a glance.

### Week 10 — demo hardening

- Balance pacing and offline limits.
- Profile, repair save issues, add settings, package Windows builds, and run regression tests.
- Record a trailer-quality 60-second journey from planning to restored Waystone.

**Gate:** Five outside players complete the first restoration without developer help or save loss.

## 12. Development workflow borrowed from the video

The useful lesson from the video is not “ask AI to make the whole game.” The presenter prepared concept art, a detailed design/build brief, prompt and palette references, and a consistent asset set before handing work to the coding agent. They also explicitly remained responsible for validating the idea and assets.

Use this loop for each milestone:

1. Define one player outcome and its acceptance tests.
2. Provide the current design brief, architecture rules, screenshots, and relevant assets.
3. Ask the coding agent to implement one bounded vertical feature.
4. Run the game and inspect it visually.
5. Test save/offline edge cases, review the diff, and correct design drift.
6. Commit only when the feature is playable and the tests pass.

AI can accelerate scripts, UI assembly, repetitive content definitions, test creation, placeholder assets, and debugging. Human judgment remains essential for scope, feel, balance, visual consistency, licensing, and deciding what is actually fun.

## 13. Biggest risks and responses

### Risk: building two games

A manual 3D RPG plus a deep idle game is too large. Keep movement and combat automatic; active play is planning and inspection.

### Risk: content explosion

Do not begin with 20 skills or 10 regions. Make the data model expandable but ship one complete region first.

### Risk: the 3D world feels pointless

Tie locations to travel time, risk, resources, and visible restoration. Every major unlock should change either a route or the environment.

### Risk: offline results are inconsistent

Build one simulation used by both live and offline play. Never calculate rewards from animation, frame rate, or scene physics.

### Risk: AI-generated inconsistency

Use references and a style guide, generate small batches, keep provenance/license notes, and reject assets that do not fit.

### Risk: too much UI

Expose one choice at a time. Default settings should be safe. Advanced thresholds and rate details can live in expandable panels.

## 14. First seven-day target

Do not start with art production. Build a “walking spreadsheet” prototype:

- Day 1: Create the Godot project and content definitions for pine logs, Woodcutting, Emberstead, and Whisperwood.
- Day 2: Implement inventory, skill XP, and a timed chopping action.
- Day 3: Add queue steps and validation.
- Day 4: Add save/load and ten-minute offline progress.
- Day 5: Greybox two locations and make a capsule character walk between them.
- Day 6: Bind the simulator state to walking and chopping visuals; add a minimal HUD.
- Day 7: Package a build and test: queue travel, chop 10 logs, return, close mid-plan, reopen, and receive the correct report.

If that loop feels satisfying, continue. If it does not, revise the interaction before adding skills, enemies, or final art.

## 15. Decisions to make after the prototype

These should remain open until the first playable loop exists:

- Fixed diorama camera versus freely rotatable third-person camera
- Whether players can directly walk for flavor, without gaining an efficiency advantage
- Exact offline cap and how it expands
- Whether queues can branch or only use simple fallback rules
- One shared Combat skill versus separate combat skills in the full game
- Premium one-time purchase versus a free demo with one-time unlock

## Reference links

- Video: https://www.youtube.com/watch?v=dKTpO1ZhfTg
- RuneScape skills overview: https://www.runescape.com/game-guide/skills
- Melvor Idle beginner guide: https://wiki.melvoridle.com/index.php?title=Beginners_Guide
- Godot release archive: https://godotengine.org/download/archive/
- Godot navigation documentation: https://docs.godotengine.org/en/stable/tutorials/navigation/index.html
- Godot file and save documentation: https://docs.godotengine.org/en/stable/tutorials/io/index.html
