# Embervale Idle Roadmap

This roadmap tracks outcomes rather than promised dates. The design target is documented in [GAME_PLAN.md](GAME_PLAN.md).

## Milestone 0 — Walking spreadsheet

Status: **playable**

- [x] Godot 4.7.1 project
- [x] Small 3D town-to-forest route
- [x] Travel and gathering action queue
- [x] Woodcutting XP and pine-log inventory
- [x] Versioned local JSON save
- [x] Offline catch-up and return report
- [x] Headless deterministic simulation tests
- [x] Public-facing project documentation

Exit criterion: queue travel, gather ten logs, return, close mid-plan, reopen, and receive correct results.

## Milestone 1 — Reliable planner

Status: **next**

- [ ] Quantity, duration, and inventory-reserve queue rules
- [ ] Inventory capacity and bank storage
- [ ] Tool requirements and three tool tiers
- [ ] Stop/fallback reasons shown in the journey log
- [ ] Backup save and corrupt-save recovery
- [ ] Save migration test fixture
- [ ] Keyboard/controller navigation pass

Exit criterion: players can predict exactly when and why every plan stops.

## Milestone 2 — Interlocking skills

- [ ] Mining and copper ore
- [ ] Fishing and raw food
- [ ] Cooking and travel rations
- [ ] Smithing and copper tools
- [ ] Data-authored items, recipes, actions, and unlocks
- [ ] First-hour balance pass

Exit criterion: gathering, processing, and upgrades form one understandable economic loop.

## Milestone 3 — Risk and combat

- [ ] Hands-off timed combat
- [ ] Equipment, armour, accuracy, evasion, and damage
- [ ] Auto-eat and retreat thresholds
- [ ] Five enemies with one readable trait each
- [ ] One preparation-focused guardian
- [ ] Online/offline combat equivalence tests

Exit criterion: danger is legible before a plan begins, and failure is safe and explainable.

## Milestone 4 — A world worth restoring

- [ ] Repairable forge
- [ ] Bridge restoration and shorter travel route
- [ ] Waystone restoration and visible environmental change
- [ ] Six short goals/quests
- [ ] Complete first-region ending

Exit criterion: progression changes both the simulation and the visible world.

## Milestone 5 — Public demo

- [ ] Cohesive low-poly art direction
- [ ] Activity animation and VFX pass
- [ ] Ambience, sound effects, and settings
- [ ] Five outside usability tests
- [ ] Windows demo package
- [ ] Regression and save-safety pass

Exit criterion: outside players complete the first restoration without developer help or save loss.

## Not planned for the first region

Multiplayer, trading, a server backend, procedural world generation, manual action combat, mobile release, player housing, farming, pets, prestige systems, live-service seasons, or runtime generative AI.
