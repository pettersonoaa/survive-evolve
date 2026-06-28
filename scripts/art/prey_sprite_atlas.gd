class_name PreySpriteAtlas
extends RefCounted

const _PreySprites = preload("res://scripts/art/prey_sprite_factory.gd")
const SHEET_PATH := "res://assets/sprites/prey/prey_sheet.png"
const FRAMES_PER_KIND := 4


static func build_sprite_frames(kind: PreyAnimal.PreyKind, body_color: Color, body_size: Vector2) -> SpriteFrames:
	if ResourceLoader.exists(SHEET_PATH):
		var sheet := load(SHEET_PATH) as Texture2D
		if sheet != null:
			return _frames_from_sheet(sheet, kind, body_size)
	return _frames_procedural(kind, body_color, body_size)


static func single_texture(kind: PreyAnimal.PreyKind, body_color: Color, body_size: Vector2) -> Texture2D:
	if kind == PreyAnimal.PreyKind.HARE:
		return _PreySprites.create_hare(body_color, body_size)
	return _PreySprites.create(body_color, body_size)


static func _frames_from_sheet(sheet: Texture2D, kind: PreyAnimal.PreyKind, body_size: Vector2) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 3.0)
	frames.set_animation_loop(&"idle", true)

	var kinds := FRAMES_PER_KIND * 2
	var cell_w := int(sheet.get_width() / float(kinds))
	var cell_h := int(sheet.get_height())
	if cell_w < 4 or cell_h < 4:
		return _frames_procedural(kind, Color.WHITE, body_size)

	var kind_offset := FRAMES_PER_KIND if kind == PreyAnimal.PreyKind.HARE else 0
	for i in FRAMES_PER_KIND:
		frames.add_frame(&"idle", _slice(sheet, (kind_offset + i) * cell_w, 0, cell_w, cell_h))
	return frames


static func _slice(sheet: Texture2D, x: int, y: int, w: int, h: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(x, y, w, h)
	return atlas


static func _frames_procedural(kind: PreyAnimal.PreyKind, body_color: Color, body_size: Vector2) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 3.0)
	frames.set_animation_loop(&"idle", true)
	for i in FRAMES_PER_KIND:
		var bob := sin(float(i) / float(FRAMES_PER_KIND) * TAU) * 0.8
		var tex: Texture2D
		if kind == PreyAnimal.PreyKind.HARE:
			tex = _PreySprites.create_hare(body_color, body_size + Vector2(0, bob))
		else:
			tex = _PreySprites.create(body_color, body_size + Vector2(0, bob))
		frames.add_frame(&"idle", tex)
	return frames
