# 2.5D rendering in Godot

How we approximate Romestead-style depth without a custom engine.

## Scene graph rules

1. **`YSort` layer** — one `Node2D` with `y_sort_enabled = true`; all walkable entities and tall props are **direct children**.
2. **Feet at origin** — each `Entity25D` node's `position` is where the character touches the ground.
3. **`Visual` child** — sprite mesh drawn above the feet (`position.y` negative).
4. **`Shadow` child** — drawn at feet; shrinks/fades when `visual_lift` > 0 (jump knockback later).
5. **Ground** — separate node with low `z_index`, **not** inside `YSort`.

## Code entry points

| File | Role |
|------|------|
| `scripts/entity_25d.gd` | Base feet / visual / shadow |
| `scripts/player.gd` | Movement |
| `scenes/world.tscn` | `Ground` + `YSort` + camera |

## Romestead vs our stack

| Romestead (Candide) | Survive-evolve (Godot) |
|---------------------|-------------------------|
| Custom MonoGame engine | Godot 4 CanvasItem pipeline |
| Blender → screenshot → Aseprite → projected sprite | Same **art** pipeline; Godot displays `Sprite2D` / `AnimatedSprite2D` |
| Engine-specific projection | Y-sort + authored sprite offsets |

## Next technical steps

- Replace `Polygon2D` placeholders with `Sprite2D` sheets
- TileMap terrain with matching perspective
- Enemy hordes as pooled `Entity25D` instances
- Optional: slight camera bob, hit-stop, particle blood/spores on same Y-sort layer
