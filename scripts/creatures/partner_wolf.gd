extends Wolf
class_name PartnerWolf

@export var archetype_id: String = "forest_wolf"

@export var wander_speed := 48.0
var _wander_dir := Vector2.RIGHT
var _wander_timer := 0.0
var genes: WolfGenes


func _ready() -> void:
	is_player_controlled = false
	genes = EvolutionRegistry.make_partner_genes(archetype_id)
	body_color = EvolutionRegistry.get_partner_color(archetype_id)
	add_to_group("interact_handlers")
	add_to_group("partner_wolf")
	super._ready()
	needs.set_process(false)
	needs.refill()
	_add_tag_label()
	_wander_timer = randf_range(2.0, 4.0)
	EventBus.pack_assist_requested.connect(_on_pack_assist_requested)


func _add_tag_label() -> void:
	var label := Label.new()
	label.text = genes.display_tag
	label.position = Vector2(-46, -58)
	label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.88))
	add_child(label)


func _apply_needs_damage(_delta: float) -> void:
	pass


func _process(delta: float) -> void:
	if is_dead:
		return
	super._process(delta)
	if _is_gestation_partner():
		_follow_player_during_gestation(delta)
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
	return GameState.gestation_active \
		and GameState.gestation_partner == self \
		and is_instance_valid(GameState.player_wolf)


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
	if GameState.gestation_partner == self:
		GameState.gestation_partner = null
		EventBus.ui_toast.emit("Gestation partner fell — birth still incoming", 2.5)
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
