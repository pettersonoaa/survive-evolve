extends Control

@onready var _label: Label = $Label


func _process(_delta: float) -> void:
	var wolf := GameState.player_wolf
	if wolf == null or not is_instance_valid(wolf) or wolf.is_dead or GameState.modal_ui_open:
		_label.visible = false
		return

	var best_text := ""
	var best_dist := GameConstants.INTERACT_RANGE + 1.0

	for node in get_tree().get_nodes_in_group("interact_handlers"):
		if not node.has_method("handle_interact"):
			continue
		if not InteractUtils.is_in_interact_range(wolf, node):
			continue
		var dist := InteractUtils.distance_to(wolf, node)
		if dist >= best_dist:
			continue
		var hint := _hint_for(node, wolf)
		if hint.is_empty():
			continue
		best_dist = dist
		best_text = hint

	_label.visible = not best_text.is_empty()
	_label.text = best_text


func _hint_for(node: Node, player) -> String:
	if node is FoodCarcass:
		var food := node as FoodCarcass
		if food.depleted:
			return ""
		return "[E] Eat carcass"
	if node is WaterSource:
		var water := node as WaterSource
		if water.depleted:
			return ""
		return "[E] Drink water"
	if node is PartnerWolf:
		var partner := node as PartnerWolf
		if partner.is_dead:
			return ""
		if GameState.gestation_active:
			return "[E] Mate (gestating...)"
		if not player.needs.is_fed_for_mate():
			return "[E] Mate (need >50% hunger & thirst)"
		if not partner.needs.is_fed_for_mate():
			return "[E] Mate (partner needs food)"
		return "[E] Mate with %s" % partner.genes.display_tag
	return ""
