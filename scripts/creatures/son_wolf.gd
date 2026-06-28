extends Wolf
class_name SonWolf

enum LifeStage { PUP, INDEPENDENT, ROGUE }

const PUP_BODY_SIZE := Vector2(20.0, 32.0)
const ADULT_BODY_SIZE := Vector2(26.0, 42.0)

var life_stage: LifeStage = LifeStage.PUP
var age_seconds: float = 0.0

var _follow_target: Node2D = null
var _follow_distance := 80.0
var _wander_dir := Vector2.RIGHT
var _wander_timer := 0.0
var _rogue_attack_cooldown := 0.0
var _independent_age_seconds := 0.0


func _ready() -> void:
	is_player_controlled = false
	is_heir = true
	super._ready()
	needs.set_process(true)
	needs.refill()
	GameState.register_heir(self)
	_follow_target = GameState.player_wolf
	add_to_group("pack_member")
	_wander_timer = randf_range(2.0, 4.0)
	EventBus.pack_assist_requested.connect(_on_pack_assist_requested)


func setup_from_birth(birth_stats: WolfStats, node_id: String, partner_genes: WolfGenes) -> void:
	stats = birth_stats
	current_node_id = node_id
	trait_display_name = EvolutionResolver.get_display_name(node_id)
	partner_genes_at_birth = partner_genes
	health = stats.max_health
	body_size = PUP_BODY_SIZE
	body_color = EvolutionRegistry.get_offspring_color(partner_genes.archetype_id, node_id)
	life_stage = LifeStage.PUP
	age_seconds = 0.0
	_independent_age_seconds = 0.0
	if is_node_ready():
		_apply_growth_visual()
		_apply_body_sprite()
		_update_geometry()


func restore_lifecycle(stage: LifeStage, saved_age: float, saved_independent_age: float = 0.0) -> void:
	age_seconds = maxf(saved_age, 0.0)
	_independent_age_seconds = maxf(saved_independent_age, 0.0)
	_set_life_stage(stage, false)
	_apply_growth_visual()
	if is_node_ready():
		_apply_body_sprite()
		_update_geometry()


func is_pack_dependent() -> bool:
	return is_heir and life_stage == LifeStage.PUP and not is_dead


func is_hostile() -> bool:
	return is_heir and life_stage == LifeStage.ROGUE and not is_dead


func get_life_stage_label() -> String:
	match life_stage:
		LifeStage.PUP:
			return "Pup"
		LifeStage.INDEPENDENT:
			return "Young wolf"
		LifeStage.ROGUE:
			return "Rogue"
	return "Heir"


func _process(delta: float) -> void:
	if is_dead:
		return
	age_seconds += delta
	if life_stage == LifeStage.INDEPENDENT:
		_independent_age_seconds += delta
	_check_lifecycle_transitions()
	if life_stage == LifeStage.ROGUE:
		_rogue_process(delta)
		return
	super._process(delta)
	if life_stage == LifeStage.PUP:
		_apply_growth_visual()


func _check_lifecycle_transitions() -> void:
	if life_stage == LifeStage.PUP and age_seconds >= GameConstants.HEIR_INDEPENDENCE_SECONDS:
		_become_independent()
	elif life_stage == LifeStage.INDEPENDENT \
			and _independent_age_seconds >= GameConstants.HEIR_ROGUE_AFTER_INDEPENDENCE_SECONDS:
		_become_rogue()


func _become_independent() -> void:
	if life_stage != LifeStage.PUP:
		return
	_set_life_stage(LifeStage.INDEPENDENT, true)
	_independent_age_seconds = 0.0
	_apply_growth_visual()
	EventBus.ui_toast.emit("%s left the pack to hunt alone" % trait_display_name, 2.8)


func _become_rogue() -> void:
	if life_stage != LifeStage.INDEPENDENT:
		return
	_set_life_stage(LifeStage.ROGUE, true)
	body_color = body_color.darkened(0.35)
	_apply_body_sprite()
	stats.bite_damage = maxf(stats.bite_damage, GameConstants.HEIR_ROGUE_DAMAGE)
	EventBus.ui_toast.emit("%s turned rogue — now hostile!" % trait_display_name, 3.2)


func _set_life_stage(stage: LifeStage, emit_signal: bool) -> void:
	life_stage = stage
	if stage == LifeStage.PUP:
		if not is_in_group("pack_member"):
			add_to_group("pack_member")
		if is_in_group("rogue_heir"):
			remove_from_group("rogue_heir")
	elif stage == LifeStage.INDEPENDENT:
		remove_from_group("pack_member")
		if is_in_group("rogue_heir"):
			remove_from_group("rogue_heir")
	else:
		remove_from_group("pack_member")
		if not is_in_group("rogue_heir"):
			add_to_group("rogue_heir")
	if emit_signal:
		EventBus.heir_lifecycle_changed.emit(self, get_life_stage_label())


func _apply_growth_visual() -> void:
	if life_stage == LifeStage.ROGUE:
		body_size = ADULT_BODY_SIZE
		return
	var grow_t := clampf(age_seconds / GameConstants.HEIR_INDEPENDENCE_SECONDS, 0.0, 1.0)
	body_size = PUP_BODY_SIZE.lerp(ADULT_BODY_SIZE, grow_t)
	if is_node_ready():
		_update_geometry()


func _follow_as_heir(delta: float) -> void:
	if life_stage == LifeStage.PUP:
		_follow_parent(delta)
	elif life_stage == LifeStage.INDEPENDENT:
		_independent_behavior(delta)


func _follow_parent(delta: float) -> void:
	if _follow_target == null or not is_instance_valid(_follow_target):
		_follow_target = GameState.player_wolf
	if _follow_target == null:
		return
	var den: Node2D = InteractUtils.find_den(get_tree())
	if den != null and den.has_method("contains_wolf") and den.contains_wolf(self):
		var dist_to_parent := global_position.distance_to(_follow_target.global_position)
		if dist_to_parent > GameConstants.DEN_STAY_RANGE:
			return
	var offset := _follow_target.global_position - global_position
	if offset.length() > _follow_distance:
		_last_move_dir = offset.normalized()
		global_position += offset.normalized() * stats.move_speed * 0.65 * delta
	else:
		_last_move_dir = Vector2.ZERO


func _independent_behavior(delta: float) -> void:
	if needs.hunger <= 40.0 or needs.thirst <= 40.0:
		if _seek_resource(delta):
			return
	_wander(delta)


func _seek_resource(delta: float) -> bool:
	var want_food := needs.hunger <= needs.thirst
	var best: Node2D = null
	var best_dist := GameConstants.INTERACT_RANGE + 1.0
	for node in get_tree().get_nodes_in_group("interact_handlers"):
		if not node.has_method("handle_interact"):
			continue
		if node is PartnerWolf:
			continue
		if node is FoodCarcass:
			if want_food and not (node as FoodCarcass).depleted:
				var dist := global_position.distance_to(node.global_position)
				if dist < best_dist:
					best_dist = dist
					best = node
		elif node is WaterSource:
			if not want_food and not (node as WaterSource).depleted:
				var dist := global_position.distance_to(node.global_position)
				if dist < best_dist:
					best_dist = dist
					best = node
	if best == null:
		return false
	var offset := best.global_position - global_position
	var dist := offset.length()
	if dist > GameConstants.INTERACT_RANGE:
		_last_move_dir = offset.normalized()
		global_position += offset.normalized() * stats.move_speed * GameConstants.HEIR_INDEPENDENT_WANDER_MULT * delta
		return true
	_last_move_dir = Vector2.ZERO
	best.handle_interact(self)
	return true


func _wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.0, 4.0)
		_wander_dir = Vector2.RIGHT.rotated(randf() * TAU)
	_last_move_dir = _wander_dir
	global_position += _wander_dir * stats.move_speed * GameConstants.HEIR_INDEPENDENT_WANDER_MULT * delta


func _rogue_process(delta: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_rogue_attack_cooldown = maxf(_rogue_attack_cooldown - delta, 0.0)
	var target := _pick_rogue_target()
	if target == null:
		_wander(delta)
	else:
		var offset := target.global_position - global_position
		var dist := offset.length()
		if dist > 28.0:
			_last_move_dir = offset.normalized()
			global_position += offset.normalized() * stats.move_speed * 0.85 * delta
		elif _rogue_attack_cooldown <= 0.0:
			_last_move_dir = Vector2.ZERO
			target.take_damage(GameConstants.HEIR_ROGUE_DAMAGE, "rogue_heir")
			_rogue_attack_cooldown = GameConstants.HEIR_ROGUE_ATTACK_COOLDOWN
	_update_motion_anim()
	_apply_needs_damage(delta)


func _pick_rogue_target() -> Wolf:
	var best: Wolf = null
	var best_dist := GameConstants.PREDATOR_AGGRO_RANGE
	for candidate in _rogue_targets():
		var dist := global_position.distance_to(candidate.global_position)
		if dist < best_dist:
			best_dist = dist
			best = candidate
	return best


func _rogue_targets() -> Array[Wolf]:
	var targets: Array[Wolf] = []
	if GameState.player_wolf is Wolf and is_instance_valid(GameState.player_wolf):
		var player := GameState.player_wolf as Wolf
		if not player.is_dead and not _is_den_protected(player):
			targets.append(player)
	for heir in GameState.get_living_heirs():
		if heir is SonWolf and heir != self and is_instance_valid(heir) and not heir.is_dead:
			var son := heir as SonWolf
			if son.is_pack_dependent() and not _is_den_protected(son):
				targets.append(son)
	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if node is PartnerWolf and is_instance_valid(node) and not node.is_dead and not _is_den_protected(node as Wolf):
			targets.append(node as Wolf)
	return targets


func _is_den_protected(wolf: Wolf) -> bool:
	return InteractUtils.den_covers(get_tree(), wolf.global_position)


func receive_bite(attacker: Wolf) -> void:
	if is_dead or attacker == null or not is_hostile():
		return
	take_damage(attacker.stats.bite_damage, "player_bite")
	EventBus.ui_toast.emit(
		"Rogue heir hit! %.0f damage (%.0f HP)" % [attacker.stats.bite_damage, maxf(health, 0.0)],
		1.2,
	)


func _on_pack_assist_requested(attacker: Node, target: Node) -> void:
	if is_dead or not is_pack_dependent() or attacker != GameState.player_wolf:
		return
	if not target.has_method("receive_bite"):
		return
	_try_attack(target)


func promote_to_player() -> void:
	if is_in_group("rogue_heir"):
		remove_from_group("rogue_heir")
	var heir_global := global_position
	var world_content := get_tree().get_first_node_in_group("world_content") as Node2D
	if world_content != null:
		world_content.position -= heir_global
		global_position = Vector2.ZERO
	is_player_controlled = true
	is_heir = false
	life_stage = LifeStage.INDEPENDENT
	set_process(true)
	needs.set_process(true)
	needs.refill()
	GameState.unregister_heir(self)
	GameState.player_wolf = self
	body_color = Color(0.55, 0.55, 0.58)
	body_size = ADULT_BODY_SIZE
	_apply_body_sprite()
	_attack_cooldown = 0.0
