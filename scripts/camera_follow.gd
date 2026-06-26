extends Camera2D
## Top-down follow cam tuned for readable 2.5D crowds.


@export var target_path: NodePath
@export var smooth_speed := 10.0

var _target: Node2D


func _ready() -> void:
	if target_path.is_empty():
		return
	_target = get_node(target_path) as Node2D


func _process(delta: float) -> void:
	if _target == null:
		return
	global_position = global_position.lerp(_target.global_position, smooth_speed * delta)
