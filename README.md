# Survive now, evolve if you can

A **2.5D** roguelike / survivor game inspired by the depth and pixel look of [Romestead](https://store.steampowered.com/app/2660460/Romestead/). Survive waves, mutate, evolve—or die trying.

## Visual direction (Romestead-like)

- **Top-down** camera with **Y-sorted depth** (walk behind trees, in front of rocks)
- **Feet-based sorting** — entity root sits on the ground; the sprite sits above
- **Projected pixel art** pipeline (see `docs/ART_PIPELINE.md`) once we move past placeholders
- Nearest-neighbor filtering for crisp pixels

## Gameplay pillars

- **Survive now** — movement, dodge, escalating pressure
- **Evolve if you can** — risky mutations, run-based builds
- **Readable crowds** — depth + telegraphs matter in survivor combat

## Stack

- [Godot 4.3+](https://godotengine.org/) (GDScript)
- Desktop first

## Run the prototype

1. Open this folder in Godot (`project.godot`).
2. Press **F5**.
3. **WASD** to move — walk around props and notice depth sorting.

## Layout

```
survive-evolve/
├── assets/              # final sprites, audio (Blender exports, Aseprite)
├── scenes/
│   ├── world.tscn       # 2.5D play space
│   ├── entity_25d.tscn  # base feet + visual + shadow
│   ├── player.tscn
│   └── prop_*.tscn
├── scripts/
│   ├── entity_25d.gd    # depth / lift / shadow
│   ├── player.gd
│   └── ...
└── docs/
    ├── ART_PIPELINE.md
    ├── RENDERING_25D.md
    └── GAME_CONCEPT.md
```

## Status

2.5D movement prototype with placeholder shapes — combat and evolution next.
