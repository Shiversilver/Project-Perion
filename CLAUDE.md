# Project Perion: notes for Claude

Godot 4 (target 4.3+, GL Compatibility renderer) top-down space combat/sim.
Read DESIGN.md for the vision; README.md for controls and layout.

## Conventions
- GDScript with static typing (`:=`, typed params and returns). Tabs for indentation.
- Use `minf`/`maxf`/`clampf`, not `min`/`max`/`clamp` (those return Variant and break `:=` inference).
- Content is data: ships in `data/ships/*.tres` (ShipData), weapons in `data/weapons/*.tres` (WeaponData).
  Add a new weapon or hull by adding a .tres, not code.
- A Ship never reads input itself. A controller node (PlayerController / ShipAI)
  implements `think(ship, delta)` and writes the ship's intent fields.
- Placeholder art is drawn procedurally in `_draw()`. Ships face +X.
- Input actions are registered in `scripts/autoload/input_setup.gd` (not project.godot).

## Verifying changes
There's no display in cloud sessions. Validate headless:
```
GODOT=/path/to/godot tests/run_sim.sh
```
This imports the project, runs a 90 s AI-vs-pirates simulation and fails on
script errors or if no combat happens. Godot 4.3 Linux binary:
https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
