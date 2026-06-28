extends Node

var _den: Node2D = null


func _ready() -> void:
	add_to_group("territory_manager")
	call_deferred("_bind_den")


func _bind_den() -> void:
	_den = InteractUtils.find_den(get_tree())


func is_in_territory(global_pos: Vector2) -> bool:
	if _den == null or not is_instance_valid(_den):
		_den = InteractUtils.find_den(get_tree())
	if _den == null:
		return false
	return _den.global_position.distance_to(global_pos) <= GameConstants.TERRITORY_RADIUS


func get_center() -> Vector2:
	if _den == null or not is_instance_valid(_den):
		_den = InteractUtils.find_den(get_tree())
	if _den == null:
		return Vector2.ZERO
	return _den.global_position
