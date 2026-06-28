extends SceneTree

## Run: godot --path . --headless -s res://scripts/tools/generate_wolf_sheet.gd

const _Factory = preload("res://scripts/art/wolf_sprite_factory.gd")
const OUTPUT := "res://assets/sprites/wolf/wolf_sheet.png"
const BODY_COLOR := Color(0.55, 0.55, 0.58)
const BODY_SIZE := Vector2(26.0, 42.0)
const CELL_W := 28
const CELL_H := 44
const IDLE_FRAMES := 4
const WALK_FRAMES := 4


func _initialize() -> void:
	_generate()
	quit()


func _generate() -> void:
	var sheet := Image.create(CELL_W * (IDLE_FRAMES + WALK_FRAMES), CELL_H, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	for i in IDLE_FRAMES:
		var bob := sin(float(i) / float(IDLE_FRAMES) * TAU) * 1.0
		var tex := _Factory.create(BODY_COLOR, BODY_SIZE + Vector2(0, bob))
		_blit(sheet, tex, i * CELL_W, 0)

	for i in WALK_FRAMES:
		var sway := sin(float(i) / float(WALK_FRAMES) * TAU) * 2.0
		var tex := _Factory.create(BODY_COLOR, BODY_SIZE + Vector2(absf(sway) * 0.15, 0.0), int(sway))
		_blit(sheet, tex, (IDLE_FRAMES + i) * CELL_W, 0)

	var err := sheet.save_png(ProjectSettings.globalize_path(OUTPUT))
	if err != OK:
		push_error("Failed to write wolf_sheet.png (%s)" % err)
	else:
		print("Wrote ", OUTPUT)


func _blit(sheet: Image, tex: Texture2D, ox: int, oy: int) -> void:
	var img := tex.get_image()
	if img == null:
		return
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.01:
				continue
			var tx := ox + x
			var ty := oy + y
			if tx >= 0 and ty >= 0 and tx < sheet.get_width() and ty < sheet.get_height():
				sheet.set_pixel(tx, ty, c)
