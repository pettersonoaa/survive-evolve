extends Node

@onready var _y_sort: Node2D = $"../WorldContent/YSort"
@onready var _son_scene: PackedScene = preload("res://scenes/creatures/son_wolf.tscn")

const _LITTER_OFFSETS := [
	Vector2(34, 8),
	Vector2(52, -4),
	Vector2(14, 16),
]


func _ready() -> void:
	add_to_group("lineage_manager")


func _process(delta: float) -> void:
	if GameState.active_gestations.is_empty():
		return

	var finished: Array = []
	for entry in GameState.active_gestations:
		entry.time_left -= delta
		EventBus.gestation_tick.emit(GameState.player_wolf, entry.time_left)
		if entry.time_left <= 0.0:
			finished.append(entry)

	for entry in finished:
		_finish_gestation(entry)


func try_mate(player, partner: PartnerWolf) -> bool:
	if GameState.is_partner_gestating(partner):
		return false
	if not InteractUtils.is_in_mate_range(player, partner):
		return false
	if GameConstants.MATE_REQUIRES_FED:
		if not player.needs.is_fed_for_mate() or not partner.needs.is_fed_for_mate():
			return false

	var child_node_id := EvolutionResolver.roll_child(player.current_node_id, partner.genes)
	var offspring_stats := EvolutionResolver.build_offspring_stats(player, partner.genes, child_node_id)
	var trait_name := EvolutionResolver.get_display_name(child_node_id)
	var litter_size := randi_range(GameConstants.LITTER_SIZE_MIN, GameConstants.LITTER_SIZE_MAX)

	var pending := {
		"stats": offspring_stats,
		"node_id": child_node_id,
		"trait_name": trait_name,
		"partner": partner,
		"partner_genes": partner.genes,
		"parent": player,
		"litter_size": litter_size,
	}
	GameState.add_gestation(partner, pending)
	GameState.lineage.record_trait(trait_name)
	EventBus.mate_started.emit(player, partner)
	EventBus.evolution_applied.emit(player, child_node_id, trait_name)
	EventBus.ui_toast.emit(
		"Mating with %s — %s, %d pup(s) in %ds" % [
			partner.genes.display_tag,
			trait_name,
			litter_size,
			int(GameConstants.GESTATION_SECONDS),
		],
		3.0,
	)
	return true


func _finish_gestation(entry: Dictionary) -> void:
	GameState.remove_gestation(entry)
	var data: Dictionary = entry.get("pending", {})
	if data.is_empty():
		return

	var parent = data.get("parent")
	if not is_instance_valid(parent):
		parent = GameState.player_wolf
	var partner = data.get("partner")
	var litter_size: int = int(data.get("litter_size", 1))
	litter_size = clampi(litter_size, GameConstants.LITTER_SIZE_MIN, GameConstants.LITTER_SIZE_MAX)

	var born_pups: Array[SonWolf] = []
	for i in litter_size:
		var son: SonWolf = _son_scene.instantiate() as SonWolf
		_y_sort.add_child(son)
		son.global_position = _birth_position(partner, parent, i)
		son.setup_from_birth(data["stats"], data["node_id"], data["partner_genes"])
		born_pups.append(son)
		if partner is PartnerWolf and is_instance_valid(partner):
			partner.register_offspring(son)

	GameState.lineage.generation += 1
	GameState.lineage.record_trait(born_pups[0].trait_display_name if not born_pups.is_empty() else "")

	var partner_tag := ""
	if data["partner_genes"] is WolfGenes:
		partner_tag = data["partner_genes"].display_tag
	var trait_name: String = data.get("trait_name", born_pups[0].trait_display_name if not born_pups.is_empty() else "")
	if litter_size == 1:
		EventBus.ui_toast.emit("Pup born: %s (%s)" % [trait_name, partner_tag], 3.0)
	else:
		EventBus.ui_toast.emit("%d pups born: %s (%s)" % [litter_size, trait_name, partner_tag], 3.0)

	for son in born_pups:
		EventBus.mate_completed.emit(parent, partner, son)

	if GameState.pending_succession_after_gestation and not born_pups.is_empty():
		GameState.pending_succession_after_gestation = false
		var run_manager := get_tree().get_first_node_in_group("run_manager")
		var succession_parent = data.get("parent")
		if not is_instance_valid(succession_parent):
			succession_parent = parent
		if run_manager != null and is_instance_valid(succession_parent) and succession_parent.is_dead:
			run_manager.promote_heir(born_pups[0], succession_parent)


func _birth_position(partner, parent, index: int) -> Vector2:
	var base := Vector2.ZERO
	if partner is Node2D and is_instance_valid(partner):
		base = (partner as Node2D).global_position
	elif parent is Node2D and is_instance_valid(parent):
		base = (parent as Node2D).global_position + Vector2(24, 8)
	var offset: Vector2 = _LITTER_OFFSETS[index % _LITTER_OFFSETS.size()]
	return base + offset


func force_mate_debug() -> void:
	var player := GameState.player_wolf
	if player == null:
		EventBus.ui_toast.emit("Debug mate: no player", 1.5)
		return
	var nearest: PartnerWolf = null
	var best := 9999.0
	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if node is PartnerWolf and not GameState.is_partner_gestating(node as PartnerWolf):
			var dist: float = InteractUtils.distance_to(player, node)
			if dist < best:
				best = dist
				nearest = node
	if nearest == null:
		EventBus.ui_toast.emit("Debug mate: no available partner", 1.5)
		return
	if not InteractUtils.is_in_mate_range(player, nearest):
		nearest.global_position = player.global_position + Vector2(36, 0)
	if GameConstants.MATE_REQUIRES_FED:
		player.needs.refill()
		nearest.needs.refill()
	if try_mate(player, nearest):
		EventBus.ui_toast.emit("Debug mate: gestation started", 2.0)
	else:
		EventBus.ui_toast.emit("Debug mate failed", 2.0)
