extends Entity25D
class_name PreyAnimal

enum PreyKind { DEER, HARE }

const _PreySprites = preload("res://scripts/art/prey_sprite_factory.gd")
const _CarcassScene = preload("res://scenes/resources/food_carcass.tscn")

@export var prey_kind: PreyKind = PreyKind.DEER
@export var max_health: float = 30.0
@export var food_yield: float = 40.0
@export var wander_speed: float = 36.0
@export var flee_speed: float = 105.0

var health: float = 30.0
var is_dead: bool = false
var _wander_dir := Vector2.RIGHT
var _wander_timer := 0.0


func _ready() -> void:
	_apply_kind_defaults()
	use_walk_animations = false
	health = max_health
	add_to_group("prey_animal")
	super._ready()
	_wander_timer = randf_range(1.5, 3.0)


func _apply_kind_defaults() -> void:
	match prey_kind:
		PreyKind.HARE:
			body_color = Color(0.62, 0.55, 0.42)
			body_size = Vector2(14.0, 18.0)
			max_health = 18.0
			food_yield = 22.0
			wander_speed = 48.0
			flee_speed = 130.0
		_:
			body_color = Color(0.72, 0.58, 0.38)
			body_size = Vector2(18.0, 24.0)
			max_health = 30.0
			food_yield = 40.0
			wander_speed = 36.0
			flee_speed = 105.0


func _apply_body_sprite() -> void:
	var tex: Texture2D
	if prey_kind == PreyKind.HARE:
		tex = _PreySprites.create_hare(body_color, body_size)
	else:
		tex = _PreySprites.create(body_color, body_size)
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.add_frame(&"idle", tex)
	_body.sprite_frames = frames
	_body.centered = false
	_body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body.play(&"idle")


func _process(delta: float) -> void:
	if is_dead:
		return
	super._process(delta)
	_move(delta)


func _move(delta: float) -> void:
	var threat := _nearest_threat()
	if threat != null:
		var away := global_position - threat.global_position
		if away.length_squared() > 0.01:
			global_position += away.normalized() * flee_speed * delta
		return

	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.5, 3.5)
		_wander_dir = Vector2.RIGHT.rotated(randf() * TAU)
	global_position += _wander_dir * wander_speed * delta


func _flee_range() -> float:
	return GameConstants.HARE_FLEE_RANGE if prey_kind == PreyKind.HARE else GameConstants.PREY_FLEE_RANGE


func _nearest_threat() -> Node2D:
	var best: Node2D = null
	var best_dist := _flee_range()
	if GameState.player_wolf != null and is_instance_valid(GameState.player_wolf):
		var player := GameState.player_wolf
		if not player.get("is_dead"):
			var dist := global_position.distance_to(player.global_position)
			if dist < best_dist:
				best_dist = dist
				best = player
	for heir in GameState.get_living_heirs():
		if is_instance_valid(heir) and not heir.get("is_dead"):
			var dist := global_position.distance_to(heir.global_position)
			if dist < best_dist:
				best_dist = dist
				best = heir
	return best


func receive_bite(attacker: Node) -> void:
	if is_dead or attacker == null:
		return
	var bite_damage: float = attacker.stats.bite_damage if attacker.get("stats") else 10.0
	take_damage(bite_damage)
	EventBus.ui_toast.emit(
		"Hunt bite! %.0f damage (prey %.0f HP)" % [bite_damage, maxf(health, 0.0)],
		1.0
	)


func take_damage(amount: float) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0.0:
		_die()


func _die() -> void:
	is_dead = true
	set_process(false)
	modulate = Color(0.5, 0.5, 0.5, 0.4)
	_spawn_carcass()
	var label := "Hare" if prey_kind == PreyKind.HARE else "Prey"
	EventBus.ui_toast.emit("%s down — press E to feed" % label, 2.0)
	queue_free()


func _spawn_carcass() -> void:
	var carcass := _CarcassScene.instantiate() as FoodCarcass
	carcass.food_amount = food_yield
	var parent := get_parent()
	if parent == null:
		carcass.queue_free()
		return
	parent.add_child(carcass)
	carcass.global_position = global_position
