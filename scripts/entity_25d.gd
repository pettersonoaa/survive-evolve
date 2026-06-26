extends Node2D
class_name Entity25D
## Base for Romestead-style 2.5D entities. Node position = feet on the ground.
## Y-sort parent uses position.y for depth; Visual is lifted above the feet.


@export var body_size := Vector2(28.0, 44.0)
@export var body_color := Color(0.85, 0.72, 0.45, 1.0)
@export var visual_lift := 0.0

@onready var _visual: Node2D = $Visual
@onready var _body: Polygon2D = $Visual/Body
@onready var _shadow: Polygon2D = $Shadow


func _ready() -> void:
	_body.color = body_color
	_update_geometry()


func _process(_delta: float) -> void:
	_visual.position.y = -body_size.y - visual_lift
	_update_shadow()


func _update_geometry() -> void:
	var half_w := body_size.x * 0.5
	var h := body_size.y
	_body.polygon = PackedVector2Array([
		Vector2(-half_w, -h),
		Vector2(half_w, -h),
		Vector2(half_w, 0.0),
		Vector2(-half_w, 0.0),
	])
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
