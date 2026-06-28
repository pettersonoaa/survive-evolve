# Survive now, evolve if you can

A **2.5D** wolf lineage roguelike inspired by the depth and pixel look of [Romestead](https://store.steampowered.com/app/2660460/Romestead/). Survive hunger, raise a pack, evolve your bloodline—or die without heirs.

## Visual direction (Romestead-like)

- **Top-down** camera with **Y-sorted depth** (walk behind trees, in front of rocks)
- **Feet-based sorting** — entity root sits on the ground; the sprite sits above
- **Sprite atlas** pipeline with procedural fallback (`assets/sprites/wolf/`)
- Nearest-neighbor filtering for crisp pixels

## Gameplay pillars

- **Survive now** — hunger, thirst, predators, pack pressure
- **Evolve if you can** — mate-time evolution on a 34-node wolf tree
- **Lineage** — multiple pups per life; choose your heir when you die

## Stack

- [Godot 4.7](https://godotengine.org/) (GDScript)
- Desktop first

## Run the prototype

1. Open this folder in Godot 4.7 (`project.godot`).
2. Press **F5** (main menu).
3. **New Lineage** or **Continue**.

### Controls

| Key | Action |
|-----|--------|
| WASD / arrows | Move |
| E | Eat, drink, hunt deer, bite predators / rogue heirs, mate |
| K | Debug: kill player |
| R | Debug: refill needs |
| M | Debug: force mate |

### Core loop

Survive needs → mate wandering partners (up to one gestation each) → **30s gestation** → **1–3 pups** beside the mother → feed the pack → pups grow independent → some turn rogue → die → play as heir or game over.

See `docs/PROTOTYPE_STATUS.md` for the full playtest checklist.

## Layout

```
survive-evolve/
├── assets/sprites/wolf/   # optional Aseprite drop-in sheet
├── scenes/
│   ├── world.tscn
│   ├── ui/main_menu.tscn
│   └── creatures/
├── scripts/
│   ├── autoload/          # EventBus, GameState, LineageSave, LineageCodex
│   ├── systems/           # lineage, pack needs, world generator
│   └── creatures/         # wolf, partner, son, predator
└── docs/
    ├── DESIGN_DECISIONS.md   # locked design (read first)
    ├── PROTOTYPE_PLAN.md
    ├── PROTOTYPE_STATUS.md
    └── GAME_CONCEPT.md
```

## Status

**Playable prototype** through STEP-46: pack feeding, litters, pup lifecycle, procedural runs, save/load, lineage codex, and meta progression tiers.

## Tests (headless)

```bash
godot --path . --headless res://scenes/test/integration_runner.tscn
godot --path . --headless res://scenes/test/gestation_succession_test.tscn
```

Expect `INTEGRATION_PASS` and `GESTATION_FIX_PASS`.
