extends Entity25D
## Player movement prototype for the 2.5D world.


@export var move_speed := 220.0


func _ready() -> void:
	body_color = Color(0.92, 0.78, 0.48, 1.0)
	body_size = Vector2(26.0, 42.0)
	super._ready()


func _process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		return
	global_position += direction.normalized() * move_speed * delta
