extends SceneTree

## Run: godot --path . --headless -s res://scripts/tools/generate_prey_sheet.gd

const _Factory = preload("res://scripts/art/prey_sprite_factory.gd")
const OUTPUT := "res://assets/sprites/prey/prey_sheet.png"
const DEER_COLOR := Color(0.72, 0.58, 0.38)
const HARE_COLOR := Color(0.62, 0.55, 0.42)
const DEER_SIZE := Vector2(18.0, 24.0)
const HARE_SIZE := Vector2(14.0, 18.0)
const FRAMES := 4
const CELL_W := 20
const CELL_H := 26


func _initialize() -> void:
	_generate()
	quit()


func _generate() -> void:
	var sheet := Image.create(CELL_W * FRAMES * 2, CELL_H, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	for i in FRAMES:
		var bob := sin(float(i) / float(FRAMES) * TAU) * 0.8
		var tex := _Factory.create(DEER_COLOR, DEER_SIZE + Vector2(0, bob))
		_blit(sheet, tex, i * CELL_W, 0)

	for i in FRAMES:
		var bob := sin(float(i) / float(FRAMES) * TAU) * 0.6
		var tex := _Factory.create_hare(HARE_COLOR, HARE_SIZE + Vector2(0, bob))
		_blit(sheet, tex, (FRAMES + i) * CELL_W, 0)

	var err := sheet.save_png(ProjectSettings.globalize_path(OUTPUT))
	if err != OK:
		push_error("Failed to write prey_sheet.png (%s)" % err)
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
