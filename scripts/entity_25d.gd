extends Node2D
class_name Entity25D
## Base for Romestead-style 2.5D entities. Node position = feet on the ground.
## Y-sort parent uses position.y for depth; Visual is lifted above the feet.

const _Atlas = preload("res://scripts/art/wolf_sprite_atlas.gd")

@export var body_size := Vector2(28.0, 44.0)
@export var body_color := Color(0.85, 0.72, 0.45, 1.0)
@export var visual_lift := 0.0
@export var use_walk_animations := true

var _last_facing := Vector2.DOWN
var _is_moving := false

@onready var _visual: Node2D = $Visual
@onready var _body: AnimatedSprite2D = $Visual/Body
@onready var _shadow: Polygon2D = $Shadow


func _ready() -> void:
	_apply_body_sprite()
	_update_geometry()


func _process(_delta: float) -> void:
	_visual.position.y = -body_size.y - visual_lift
	_update_shadow()


func set_motion_state(moving: bool, facing: Vector2) -> void:
	_is_moving = moving
	if facing.length_squared() > 0.0001:
		_last_facing = facing.normalized()
	_update_animation()


func _apply_body_sprite() -> void:
	_body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body.centered = false
	if use_walk_animations:
		_body.sprite_frames = _Atlas.build_sprite_frames(body_color, body_size)
		_update_animation()
	else:
		var tex := _Atlas.single_texture(body_color, body_size)
		var frames := SpriteFrames.new()
		frames.add_animation(&"idle")
		frames.add_frame(&"idle", tex)
		_body.sprite_frames = frames
		_body.play(&"idle")


func _update_animation() -> void:
	if not use_walk_animations or _body.sprite_frames == null:
		return
	var anim := &"walk" if _is_moving else &"idle"
	if _body.sprite_frames.has_animation(anim) and _body.animation != anim:
		_body.play(anim)
	elif not _body.is_playing():
		_body.play(anim)
	if absf(_last_facing.x) > 0.05:
		_body.flip_h = _last_facing.x < 0.0


func _update_geometry() -> void:
	var tex_size := Vector2.ZERO
	if _body.sprite_frames != null and _body.sprite_frames.has_animation(_body.animation):
		var frame_tex = _body.sprite_frames.get_frame_texture(_body.animation, _body.frame)
		if frame_tex != null:
			tex_size = frame_tex.get_size()
	if tex_size == Vector2.ZERO and _body.sprite_frames != null:
		if _body.sprite_frames.has_animation(&"idle"):
			var idle_tex = _body.sprite_frames.get_frame_texture(&"idle", 0)
			if idle_tex != null:
				tex_size = idle_tex.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		_body.scale = Vector2(body_size.x / tex_size.x, body_size.y / tex_size.y)
		_body.position.x = -body_size.x * 0.5
		_body.position.y = -body_size.y
	_update_shadow()


func _update_shadow() -> void:
	var lift_factor := clampf(1.0 - visual_lift / 80.0, 0.25, 1.0)
	var sw := body_size.x * 0.7 * lift_factor
	var sh := body_size.x * 0.22 * lift_factor
	_shadow.polygon = _ellipse_polygon(sw, sh, 14)
	_shadow.modulate = Color(0.0, 0.0, 0.0, 0.22 * lift_factor)


func _ellipse_polygon(rx: float, ry: float, segments: int) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i in segments:
		var t := float(i) / float(segments) * TAU
		points.append(Vector2(cos(t) * rx, sin(t) * ry * 0.45))
	return points
