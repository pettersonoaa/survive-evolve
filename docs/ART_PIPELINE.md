# Art pipeline (Romestead-inspired)

Romestead's look comes as much from **how art is made** as from the engine. Beartwigs' workflow (public interviews):

1. **Model in Blender** — block out volume and lighting reference
2. **Render from game camera** — capture the exact top-down / 2.5D angle
3. **Paint in Aseprite** — draw pixel art over the render for consistent perspective and light
4. **Import to engine** — sprite sits on `Entity25D`; feet anchor matches ground contact

We follow the same **creative** pipeline in Godot even though our runtime is different from their Candide engine.

## Folder conventions (planned)

```
assets/
├── sprites/
│   ├── player/
│   ├── enemies/
│   └── props/
├── source/
│   ├── blender/       # .blend reference meshes
│   └── aseprite/      # .ase sources
└── tilesets/
```

## Sprite authoring rules

- **Feet line** — bottom row of opaque pixels = ground contact (aligns with `Entity25D` origin)
- **Consistent light** — one sun direction across all assets in a biome
- **Silhouette first** — survivor games need readable shapes in crowds
- **Pivot** — Godot texture import: default center bottom or custom feet offset

## Placeholder phase

Current prototype uses colored `Polygon2D` blocks in `entity_25d.tscn`. Swap to `Sprite2D` when the first painted sheet exists — no scene structure change required.

### Partner wolf placeholder colors

| Archetype | Palette | `body_color` on `Entity25D` |
|-----------|---------|----------------------------|
| Forest | Cinza / preto | `Color(0.42, 0.42, 0.45)` |
| Plains | Marrom / bege | `Color(0.58, 0.44, 0.32)` |
| Tundra | Branco | `Color(0.93, 0.94, 0.96)` |

Player wolf default: grey `Color(0.55, 0.55, 0.58)`. Sons inherit player grey until painted sprites exist.

## Tools

| Tool | Use |
|------|-----|
| Blender | Volume + render reference |
| Aseprite | Pixel paint / animation |
| Godot | Import, Y-sort, gameplay |
