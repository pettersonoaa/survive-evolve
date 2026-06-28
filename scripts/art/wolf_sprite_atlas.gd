class_name WolfSpriteAtlas
extends RefCounted

const SHEET_PATH := "res://assets/sprites/wolf/wolf_sheet.png"
const IDLE_FRAMES := 4
const WALK_FRAMES := 4


static func build_sprite_frames(body_color: Color, body_size: Vector2) -> SpriteFrames:
	if ResourceLoader.exists(SHEET_PATH):
		var sheet := load(SHEET_PATH) as Texture2D
		if sheet != null:
			return build_sprite_frames_from_sheet(sheet, body_size)
	return _frames_procedural(body_color, body_size)


static func build_sprite_frames_from_sheet(sheet: Texture2D, body_size: Vector2) -> SpriteFrames:
	return _frames_from_sheet(sheet, body_size)


static func _frames_from_sheet(sheet: Texture2D, body_size: Vector2) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.add_animation(&"walk")
	frames.set_animation_speed(&"idle", 4.0)
	frames.set_animation_speed(&"walk", 8.0)

	var cell_w := int(sheet.get_width() / float(IDLE_FRAMES + WALK_FRAMES))
	var cell_h := int(sheet.get_height())
	if cell_w < 4 or cell_h < 4:
		return _frames_procedural(Color(0.55, 0.55, 0.58), body_size)

	for i in IDLE_FRAMES:
		frames.add_frame(&"idle", _slice(sheet, i * cell_w, 0, cell_w, cell_h))
	for i in WALK_FRAMES:
		frames.add_frame(&"walk", _slice(sheet, (IDLE_FRAMES + i) * cell_w, 0, cell_w, cell_h))
	return frames


static func _slice(sheet: Texture2D, x: int, y: int, w: int, h: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(x, y, w, h)
	return atlas


static func _frames_procedural(body_color: Color, body_size: Vector2) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.add_animation(&"walk")
	frames.set_animation_speed(&"idle", 3.0)
	frames.set_animation_speed(&"walk", 9.0)
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_loop(&"walk", true)

	for i in IDLE_FRAMES:
		var bob := sin(float(i) / float(IDLE_FRAMES) * TAU) * 1.0
		frames.add_frame(&"idle", WolfSpriteFactory.create(body_color, body_size + Vector2(0, bob)))
	for i in WALK_FRAMES:
		var sway := sin(float(i) / float(WALK_FRAMES) * TAU) * 2.0
		frames.add_frame(
			&"walk",
			WolfSpriteFactory.create(body_color, body_size + Vector2(absf(sway) * 0.15, 0), int(sway))
		)
	return frames


static func single_texture(body_color: Color, body_size: Vector2) -> Texture2D:
	return WolfSpriteFactory.create(body_color, body_size)
