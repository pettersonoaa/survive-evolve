extends Area2D
class_name WolfDen

@export var safe_radius: float = GameConstants.DEN_SAFE_RADIUS


func _ready() -> void:
	add_to_group("wolf_den")


func contains_point(global_pos: Vector2) -> bool:
	return global_position.distance_to(global_pos) <= safe_radius


func contains_wolf(wolf: Node2D) -> bool:
	if wolf == null or not is_instance_valid(wolf):
		return false
	return contains_point(wolf.global_position)


func get_spawn_position() -> Vector2:
	return global_position + Vector2(randf_range(-14.0, 14.0), randf_range(-10.0, 10.0))
