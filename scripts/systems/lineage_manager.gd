extends Node

const GESTATION_SECONDS := 60.0

@onready var _y_sort: Node2D = $"../WorldContent/YSort"
@onready var _son_scene: PackedScene = preload("res://scenes/creatures/son_wolf.tscn")


func _ready() -> void:
	add_to_group("lineage_manager")


func _process(delta: float) -> void:
	if not GameState.gestation_active:
		return
	GameState.gestation_time_left -= delta
	EventBus.gestation_tick.emit(GameState.player_wolf, GameState.gestation_time_left)
	if GameState.gestation_time_left <= 0.0:
		_finish_gestation()


func try_mate(player, partner: PartnerWolf) -> bool:
	if GameState.gestation_active:
		return false
	if not InteractUtils.is_in_mate_range(player, partner):
		return false
	if GameConstants.MATE_REQUIRES_FED:
		if not player.needs.is_fed_for_mate() or not partner.needs.is_fed_for_mate():
			return false

	var child_node_id := EvolutionResolver.roll_child(player.current_node_id, partner.genes)
	var offspring_stats := EvolutionResolver.build_offspring_stats(player, partner.genes, child_node_id)
	var trait_name := EvolutionResolver.get_display_name(child_node_id)

	GameState.pending_offspring = {
		"stats": offspring_stats,
		"node_id": child_node_id,
		"trait_name": trait_name,
		"partner": partner,
		"partner_genes": partner.genes,
		"parent": player,
	}
	GameState.gestation_active = true
	GameState.gestation_time_left = GESTATION_SECONDS
	GameState.gestation_partner = partner
	GameState.lineage.record_trait(trait_name)
	EventBus.mate_started.emit(player, partner)
	EventBus.evolution_applied.emit(player, child_node_id, trait_name)
	EventBus.ui_toast.emit("Mating — trait rolled: %s (60s gestation)" % trait_name, 3.0)
	return true


func _finish_gestation() -> void:
	GameState.gestation_active = false
	GameState.gestation_partner = null
	var data: Dictionary = GameState.pending_offspring
	if data.is_empty():
		return

	var parent = data["parent"]
	var partner: PartnerWolf = data["partner"]
	var son: SonWolf = _son_scene.instantiate() as SonWolf
	_y_sort.add_child(son)
	son.global_position = parent.global_position + Vector2(24, 8)
	son.setup_from_birth(data["stats"], data["node_id"], data["partner_genes"])

	GameState.lineage.generation += 1
	GameState.lineage.record_trait(son.trait_display_name)
	GameState.pending_offspring = {}

	var partner_tag := ""
	if data["partner_genes"] is WolfGenes:
		partner_tag = data["partner_genes"].display_tag
	EventBus.ui_toast.emit("Son born: %s (%s)" % [son.trait_display_name, partner_tag], 3.0)
	EventBus.mate_completed.emit(parent, partner, son)

	if GameState.pending_succession_after_gestation:
		GameState.pending_succession_after_gestation = false
		var run_manager := get_tree().get_first_node_in_group("run_manager")
		if run_manager != null and is_instance_valid(parent) and parent.is_dead:
			run_manager.promote_heir(son, parent)


func force_mate_debug() -> void:
	var player := GameState.player_wolf
	if player == null:
		EventBus.ui_toast.emit("Debug mate: no player", 1.5)
		return
	if GameState.gestation_active:
		EventBus.ui_toast.emit("Debug mate: already gestating", 2.0)
		return
	var nearest: PartnerWolf = null
	var best := 9999.0
	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if node is PartnerWolf:
			var dist: float = InteractUtils.distance_to(player, node)
			if dist < best:
				best = dist
				nearest = node
	if nearest == null:
		EventBus.ui_toast.emit("Debug mate: no partner found", 1.5)
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
