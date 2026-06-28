extends Wolf
class_name PartnerWolf

@export var archetype_id: String = "forest_wolf"

const _PartnerAtlas = preload("res://scripts/art/partner_sprite_atlas.gd")

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
	super._ready()
	needs.set_process(true)
	needs.refill()
	_add_tag_label()
	_wander_timer = randf_range(2.0, 4.0)
	EventBus.pack_assist_requested.connect(_on_pack_assist_requested)


func _apply_body_sprite() -> void:
	_body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body.centered = false
	if use_walk_animations:
		_body.sprite_frames = _PartnerAtlas.build_sprite_frames(body_color, body_size)
		_update_animation()
	else:
		var tex := _PartnerAtlas.build_sprite_frames(body_color, body_size).get_frame_texture(&"idle", 0)
		var frames := SpriteFrames.new()
		frames.add_animation(&"idle")
		frames.add_frame(&"idle", tex)
		_body.sprite_frames = frames
		_body.play(&"idle")


func is_active_pack_member() -> bool:
	return GameState.is_partner_gestating(self) or _has_living_offspring()


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
	if is_active_pack_member():
		if _is_gestation_partner():
			_follow_player_during_gestation(delta)
			return
		if _has_living_offspring():
			_stay_near_offspring(delta)
			return
	_independent_survival(delta)


func _independent_survival(delta: float) -> void:
	if needs.hunger <= 40.0 or needs.thirst <= 40.0:
		if _seek_resource(delta):
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


func _seek_resource(delta: float) -> bool:
	var want_food := needs.hunger <= needs.thirst
	var best: Node2D = null
	var best_dist := GameConstants.INTERACT_RANGE + 1.0
	for node in get_tree().get_nodes_in_group("interact_handlers"):
		if not node.has_method("handle_interact"):
			continue
		if node is PartnerWolf or node is SonWolf:
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
		global_position += offset.normalized() * wander_speed * 0.75 * delta
		return true
	_last_move_dir = Vector2.ZERO
	best.handle_interact(self)
	return true


func _is_gestation_partner() -> bool:
	return GameState.is_partner_gestating(self) and is_instance_valid(GameState.player_wolf)


func _has_living_offspring() -> bool:
	_prune_offspring_guard()
	for son in _offspring_guard:
		if is_instance_valid(son) and not son.is_dead and son.is_pack_dependent():
			return true
	return false


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
