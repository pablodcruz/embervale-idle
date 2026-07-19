# Contributing to Embervale Idle

Thank you for helping explore a calmer kind of 3D RPG.

## Before starting

- Open an issue before investing in a large feature.
- Keep changes aligned with the current milestone in [ROADMAP.md](ROADMAP.md).
- Prefer a complete narrow improvement over a broad unfinished system.
- Do not submit copyrighted assets or content derived from another game.

## Development setup

Use Godot 4.7.1 and GDScript. Import `project.godot`, run the project, then execute the headless simulator tests:

```powershell
godot --headless --path . --script res://tests/test_simulator.gd
```

## Architecture rules

- The simulator owns rewards, inventory changes, XP, travel completion, and combat results.
- Visual nodes may observe state but must not be required for offline progress.
- Live and offline time must use the same simulation path.
- Save data must contain plain versioned values, never live scene nodes.
- New stop conditions and actions require deterministic tests.

## Pull requests

Include:

- the player-visible outcome;
- why the change belongs in the current milestone;
- tests performed;
- screenshots for UI or 3D changes;
- any asset source and license information.

By contributing, you agree that your contribution may be distributed under the repository's MIT License.
