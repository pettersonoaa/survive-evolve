# Wolf sprite sheets

Drop painted Aseprite exports here to replace procedural placeholders.

## Expected file

- `wolf_sheet.png` — horizontal strip, **4 idle + 4 walk** frames (8 total)
- Frame size should match feet anchor at bottom-center of each cell
- Godot import: **Filter = Nearest**, **Mipmaps = Off**

## Layout

| Frames 0–3 | `idle` animation |
| Frames 4–7 | `walk` animation |

If `wolf_sheet.png` is missing, `WolfSpriteAtlas` generates procedural frames at runtime.
