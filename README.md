# Project Perion

A top-down space sim about keeping the peace on the frontier. You're a lone
marshal of the Perion Frontier Authority: take cases from your security
station, hunt pirates and syndicates, and decide whether to talk, threaten or
shoot. Your methods decide what kind of peace the frontier ends up with.

Built with **Godot 4** (4.3 or newer). See [DESIGN.md](DESIGN.md) for the game design.

## Running it

1. Install Godot 4.3+ (standard version, not .NET) from https://godotengine.org/download
2. Open Godot → **Import** → select this folder's `project.godot`.
3. Press **F5** (or the ▶ button) to play.

## Current state: Milestone 1, "Fly and Fight"

A combat sandbox. You fly the PFA *Warden* patrol frigate against escalating
waves of pirates. Placeholder vector graphics for now.

### Controls

| Input | Action |
|---|---|
| W / S | Thrust forward / reverse |
| A / D | Turn (or strafe in face-cursor mode) |
| Q / E | Strafe left / right |
| T | Toggle face-cursor steering |
| Mouse | Aim the selected weapon group |
| Left mouse | Fire selected group |
| 1–5 | Select weapon group |
| Ctrl + 1–5 | Toggle autofire for a group |
| Right mouse | Toggle shield |
| V | Vent flux |
| R | Target the enemy nearest the cursor (restart when destroyed) |
| Mouse wheel | Zoom |
| Esc | Pause |
| F1 | Show / hide help |

### Combat basics (Starsector-style)

- **Flux** is your heat. Firing builds *soft* flux; shield hits build *hard*
  flux, which only drains with shields down. Max out and you **overload**
  (no shields or weapons for 4 s). **Vent** to dump flux fast while defenceless.
- **Damage types:** kinetic shreds shields (×2) but bounces off armor (×0.5);
  high explosive is the reverse; energy is even.
- **Armor** soaks damage until it's stripped, then the hull takes it all.

## Project layout

```
data/ships/      Hull definitions (.tres): stats, look, weapon mounts
data/weapons/    Weapon definitions (.tres)
scenes/          Scenes (main.tscn is the entry point)
scripts/data/    Resource classes: ShipData, WeaponData, WeaponMount
scripts/ship/    Ship, Weapon, PlayerController, ShipAI
scripts/combat/  Projectile, Effect
scripts/ui/      HUD
scripts/world/   Starfield background
scripts/autoload/  InputSetup (key bindings), Combat (spawning helpers)
tests/           Headless combat simulation
```

Ships and weapons are data: tweak numbers by opening the `.tres` files in the
Godot inspector, no code needed.
