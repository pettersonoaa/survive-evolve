extends Control

@onready var _label: Label = $Label


func _process(_delta: float) -> void:
	var wolf := GameState.player_wolf
	if wolf == null or not is_instance_valid(wolf) or wolf.is_dead or GameState.modal_ui_open:
		_label.visible = false
		return

	var best_text := ""
	var best_dist := 9999.0

	for node in get_tree().get_nodes_in_group("predator_wolf"):
		if not node is PredatorWolf:
			continue
		var predator := node as PredatorWolf
		if predator.is_dead:
			continue
		var dist := InteractUtils.distance_to(wolf, predator)
		if dist > GameConstants.INTERACT_RANGE or dist >= best_dist:
			continue
		best_dist = dist
		best_text = "[E] Bite predator"

	for node in get_tree().get_nodes_in_group("prey_animal"):
		if node.get("is_dead"):
			continue
		var dist := InteractUtils.distance_to(wolf, node)
		if dist > GameConstants.INTERACT_RANGE or dist >= best_dist:
			continue
		best_dist = dist
		best_text = "[E] Hunt deer"

	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if not node is PartnerWolf:
			continue
		var partner := node as PartnerWolf
		if partner.is_dead:
			continue
		var dist := InteractUtils.distance_to(wolf, partner)
		if dist > GameConstants.MATE_RANGE or dist >= best_dist:
			continue
		var hint := _partner_hint(partner, wolf)
		if hint.is_empty():
			continue
		best_dist = dist
		best_text = hint

	var resource_dist := GameConstants.INTERACT_RANGE + 1.0
	for node in get_tree().get_nodes_in_group("interact_handlers"):
		if node is PartnerWolf:
			continue
		if not node.has_method("handle_interact"):
			continue
		if not InteractUtils.is_in_interact_range(wolf, node):
			continue
		var dist := InteractUtils.distance_to(wolf, node)
		if dist >= resource_dist:
			continue
		var hint := _resource_hint(node)
		if hint.is_empty():
			continue
		resource_dist = dist
		if dist < best_dist:
			best_text = hint
			best_dist = dist

	_label.visible = not best_text.is_empty()
	_label.text = best_text


func _partner_hint(partner: PartnerWolf, player) -> String:
	if GameState.gestation_active:
		return "[E] Mate (gestating...)"
	if GameConstants.MATE_REQUIRES_FED and not player.needs.is_fed_for_mate():
		return "[E] Mate (need >50% hunger & thirst)"
	if GameConstants.MATE_REQUIRES_FED and not partner.needs.is_fed_for_mate():
		return "[E] Mate (partner needs food)"
	if not InteractUtils.is_in_mate_range(player, partner):
		return "[E] Mate (move closer)"
	return "[E] Mate with %s" % partner.genes.display_tag


func _resource_hint(node: Node) -> String:
	if node is FoodCarcass:
		if (node as FoodCarcass).depleted:
			return ""
		return "[E] Eat carcass"
	if node is WaterSource:
		if (node as WaterSource).depleted:
			return ""
		return "[E] Drink water"
	return ""
