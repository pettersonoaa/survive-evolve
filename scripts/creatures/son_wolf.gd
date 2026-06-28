extends Wolf
class_name SonWolf

var _follow_target: Node2D = null
var _follow_distance := 80.0


func _ready() -> void:
	is_player_controlled = false
	is_heir = true
	body_color = Color(0.62, 0.62, 0.65)
	super._ready()
	needs.set_process(true)
	needs.refill()
	GameState.register_heir(self)
	_follow_target = GameState.player_wolf
	EventBus.pack_assist_requested.connect(_on_pack_assist_requested)


func setup_from_birth(birth_stats: WolfStats, node_id: String, partner_genes: WolfGenes) -> void:
	stats = birth_stats
	current_node_id = node_id
	trait_display_name = EvolutionResolver.get_display_name(node_id)
	partner_genes_at_birth = partner_genes
	health = stats.max_health
	body_size = Vector2(20.0, 32.0)
	if is_node_ready():
		_apply_body_sprite()
		_update_geometry()


func _follow_as_heir(delta: float) -> void:
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


func _on_pack_assist_requested(attacker: Node, target: Node) -> void:
	if is_dead or not is_heir or attacker != GameState.player_wolf:
		return
	if not target.has_method("receive_bite"):
		return
	_try_attack(target)


func promote_to_player() -> void:
	var heir_global := global_position
	var world_content := get_tree().get_first_node_in_group("world_content") as Node2D
	if world_content != null:
		world_content.position -= heir_global
		global_position = Vector2.ZERO
	is_player_controlled = true
	is_heir = false
	set_process(true)
	needs.set_process(true)
	needs.refill()
	GameState.unregister_heir(self)
	GameState.player_wolf = self
	body_color = Color(0.55, 0.55, 0.58)
	_apply_body_sprite()
	_attack_cooldown = 0.0
