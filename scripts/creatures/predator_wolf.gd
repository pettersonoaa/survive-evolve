extends Wolf
class_name PredatorWolf

@export var chase_speed_mult: float = 0.9
@export var contact_damage: float = 12.0
@export var attack_cooldown: float = 1.2

var _cooldown := 0.0


func _ready() -> void:
	is_player_controlled = false
	body_color = Color(0.35, 0.12, 0.12)
	body_size = Vector2(30.0, 46.0)
	super._ready()
	needs.set_process(false)
	stats.bite_damage = 15.0


func _apply_needs_damage(_delta: float) -> void:
	pass


func _process(delta: float) -> void:
	if is_dead:
		return
	super._process(delta)
	_cooldown = maxf(_cooldown - delta, 0.0)
	var target := GameState.player_wolf
	if target == null or not is_instance_valid(target) or target.is_dead:
		return
	var offset := target.global_position - global_position
	var dist := offset.length()
	if dist < 200.0 and dist > 28.0:
		global_position += offset.normalized() * stats.move_speed * chase_speed_mult * delta
	elif dist <= 28.0 and _cooldown <= 0.0:
		target.take_damage(contact_damage, "predator")
		_cooldown = attack_cooldown
