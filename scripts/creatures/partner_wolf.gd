extends Wolf
class_name PartnerWolf

@export var archetype_id: String = "forest_wolf"

@export var wander_speed := 48.0
var _wander_dir := Vector2.RIGHT
var _wander_timer := 0.0
var genes: WolfGenes
var _offspring_guard: Array[SonWolf] = []


func _ready() -> void:
	is_player_controlled = false
	genes = EvolutionRegistry.make_partner_genes(archetype_id)
	body_color = EvolutionRegistry.get_partner_color(archetype_id)
	add_to_group("interact_handlers")
	add_to_group("partner_wolf")
	add_to_group("pack_member")
	super._ready()
	needs.set_process(true)
	needs.refill()
	_add_tag_label()
	_wander_timer = randf_range(2.0, 4.0)
	EventBus.pack_assist_requested.connect(_on_pack_assist_requested)


func register_offspring(son: SonWolf) -> void:
	if son != null and son not in _offspring_guard:
		_offspring_guard.append(son)


func _add_tag_label() -> void:
	var label := Label.new()
	label.text = genes.display_tag
	label.position = Vector2(-46, -58)
	label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.88))
	add_child(label)


func _apply_needs_damage(delta: float) -> void:
	var damage := needs.get_passive_damage() * delta
	if damage > 0.0:
		take_damage(damage, "needs")


func _process(delta: float) -> void:
	if is_dead:
		return
	super._process(delta)
	if _is_gestation_partner():
		_follow_player_during_gestation(delta)
		return
	if _has_living_offspring():
		_stay_near_offspring(delta)
		return
	var player := GameState.player_wolf
	if player != null and is_instance_valid(player) and not player.is_dead:
		if global_position.distance_to(player.global_position) < GameConstants.PARTNER_IDLE_RANGE:
			_last_move_dir = Vector2.ZERO
			return
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.0, 4.0)
		_wander_dir = Vector2.RIGHT.rotated(randf() * TAU)
	global_position += _wander_dir * wander_speed * delta
	_last_move_dir = _wander_dir


func _is_gestation_partner() -> bool:
	return GameState.is_partner_gestating(self) and is_instance_valid(GameState.player_wolf)


func _has_living_offspring() -> bool:
	_prune_offspring_guard()
	return not _offspring_guard.is_empty()


func _prune_offspring_guard() -> void:
	var kept: Array[SonWolf] = []
	for son in _offspring_guard:
		if is_instance_valid(son) and not son.is_dead:
			kept.append(son)
	_offspring_guard = kept


func _nearest_offspring() -> SonWolf:
	_prune_offspring_guard()
	var best: SonWolf = null
	var best_dist := INF
	for son in _offspring_guard:
		var dist := global_position.distance_to(son.global_position)
		if dist < best_dist:
			best_dist = dist
			best = son
	return best


func _stay_near_offspring(delta: float) -> void:
	var offspring := _nearest_offspring()
	if offspring == null:
		return
	var offset := offspring.global_position - global_position
	var dist := offset.length()
	if dist <= GameConstants.PARTNER_OFFSPRING_RANGE:
		_last_move_dir = Vector2.ZERO
		return
	_last_move_dir = offset.normalized()
	global_position += offset.normalized() * wander_speed * 1.15 * delta


func _follow_player_during_gestation(delta: float) -> void:
	var player := GameState.player_wolf
	if player == null or not is_instance_valid(player) or player.is_dead:
		return
	var offset := player.global_position - global_position
	var dist := offset.length()
	if dist <= GameConstants.PARTNER_GESTATION_STOP_RANGE:
		_last_move_dir = Vector2.ZERO
		return
	_last_move_dir = offset.normalized()
	global_position += offset.normalized() * GameConstants.PARTNER_GESTATION_FOLLOW_SPEED * delta


func _on_pack_assist_requested(attacker: Node, target: Node) -> void:
	if is_dead or not _is_gestation_partner() or attacker != GameState.player_wolf:
		return
	if not target.has_method("receive_bite"):
		return
	_try_attack(target)


func _die(cause: String) -> void:
	EventBus.ui_toast.emit("%s fell — pups still incoming" % genes.display_tag, 2.5)
	super._die(cause)


func handle_interact(player) -> bool:
	if is_dead:
		return false
	if player != GameState.player_wolf:
		return false
	if not InteractUtils.is_in_mate_range(player, self):
		return false
	var manager := get_tree().get_first_node_in_group("lineage_manager")
	if manager == null:
		push_error("LineageManager not found")
		return false
	if manager.has_method("try_mate"):
		return manager.try_mate(player, self)
	return false
