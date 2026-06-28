# Partner sprite sheet

- `partner_sheet.png` — same layout as wolf (4 idle + 4 walk)
- Tint at runtime via `body_color` per bloodline
- Generate: `godot --path . --headless -s res://scripts/tools/generate_partner_sheet.gd`
- Runtime: `PartnerSpriteAtlas` → falls back to `WolfSpriteAtlas`
