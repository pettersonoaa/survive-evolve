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
	add_to_group("predator_wolf")
	super._ready()
	needs.set_process(false)
	stats.bite_damage = 15.0
	stats.max_health = 80.0
	health = stats.max_health


func _apply_needs_damage(_delta: float) -> void:
	pass


func _process(delta: float) -> void:
	if is_dead:
		return
	super._process(delta)
	_cooldown = maxf(_cooldown - delta, 0.0)
	var target := _pick_attack_target()
	if target == null:
		return
	var offset := target.global_position - global_position
	var dist := offset.length()
	if dist < GameConstants.PREDATOR_AGGRO_RANGE and dist > 28.0:
		_last_move_dir = offset.normalized()
		var speed_mult := chase_speed_mult
		var territory := get_tree().get_first_node_in_group("territory_manager")
		if territory != null and territory.has_method("is_in_territory"):
			if territory.is_in_territory(global_position):
				speed_mult *= GameConstants.TERRITORY_PREDATOR_SPEED_MULT
		global_position += offset.normalized() * stats.move_speed * speed_mult * delta
	elif dist <= 28.0 and _cooldown <= 0.0:
		_last_move_dir = Vector2.ZERO
		target.take_damage(contact_damage, "predator")
		_cooldown = attack_cooldown


func receive_bite(attacker: Wolf) -> void:
	if is_dead or attacker == null:
		return
	take_damage(attacker.stats.bite_damage, "player_bite")
	EventBus.ui_toast.emit(
		"Bite! %.0f damage (predator %.0f HP)" % [attacker.stats.bite_damage, maxf(health, 0.0)],
		1.2
	)


func _die(cause: String) -> void:
	super._die(cause)
	EventBus.ui_toast.emit("Predator defeated!", 2.0)
	queue_free()


func _pick_attack_target() -> Wolf:
	var best: Wolf = null
	var best_dist := GameConstants.PREDATOR_AGGRO_RANGE
	for candidate in _gather_targets():
		var dist := global_position.distance_to(candidate.global_position)
		if dist < best_dist:
			best_dist = dist
			best = candidate
	return best


func _gather_targets() -> Array[Wolf]:
	var targets: Array[Wolf] = []
	if GameState.player_wolf is Wolf and is_instance_valid(GameState.player_wolf):
		var player := GameState.player_wolf as Wolf
		if not player.is_dead and not _is_protected(player):
			targets.append(player)
	for heir in GameState.get_living_heirs():
		if heir is Wolf and is_instance_valid(heir) and not heir.is_dead and not _is_protected(heir as Wolf):
			targets.append(heir as Wolf)
	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if node is PartnerWolf and is_instance_valid(node) and not node.is_dead and not _is_protected(node as Wolf):
			targets.append(node as Wolf)
	return targets


func _is_protected(wolf: Wolf) -> bool:
	return InteractUtils.den_covers(get_tree(), wolf.global_position)
