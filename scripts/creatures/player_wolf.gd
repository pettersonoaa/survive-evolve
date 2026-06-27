extends Wolf
class_name PlayerWolf


func _ready() -> void:
	is_player_controlled = true
	body_color = Color(0.55, 0.55, 0.58)
	current_node_id = "wolf_base"
	trait_display_name = "Grey Wolf"
	super._ready()
	GameState.player_wolf = self
	global_position = Vector2.ZERO


func _process(delta: float) -> void:
	if is_dead:
		return
	super._process(delta)
	if is_player_controlled:
		global_position = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if is_dead or GameState.modal_ui_open:
		return
	if event.is_action_pressed("interact"):
		_try_nearest_interact()


func _try_nearest_interact() -> void:
	var target := _pick_interact_target()
	if target == null:
		if _has_approach_target():
			EventBus.ui_toast.emit("Get closer to interact", 1.5)
		else:
			EventBus.ui_toast.emit("Nothing to interact with nearby", 1.5)
		return
	if target.handle_interact(self):
		return
	_fail_message_for(target)


func _has_approach_target() -> bool:
	for node in get_tree().get_nodes_in_group("interact_handlers"):
		if not node.has_method("handle_interact"):
			continue
		if node is FoodCarcass and (node as FoodCarcass).depleted:
			continue
		if node is WaterSource and (node as WaterSource).depleted:
			continue
		if InteractUtils.is_in_approach_range(self, node):
			return true
	return false


func _pick_interact_target() -> Node:
	var in_range: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("interact_handlers"):
		if not node.has_method("handle_interact"):
			continue
		if not InteractUtils.is_in_interact_range(self, node):
			continue
		if node is FoodCarcass and (node as FoodCarcass).depleted:
			continue
		if node is WaterSource and (node as WaterSource).depleted:
			continue
		in_range.append({"node": node, "dist": InteractUtils.distance_to(self, node)})

	if in_range.is_empty():
		return null

	for entry in in_range:
		var node: Node = entry["node"]
		if node is PartnerWolf:
			var partner := node as PartnerWolf
			if not partner.is_dead and not GameState.gestation_active \
					and needs.is_fed_for_mate() and partner.needs.is_fed_for_mate():
				return partner

	var want_food := needs.hunger <= needs.thirst
	for entry in in_range:
		var node: Node = entry["node"]
		if want_food and node is FoodCarcass:
			return node
		if not want_food and node is WaterSource:
			return node
	for entry in in_range:
		var node: Node = entry["node"]
		if node is FoodCarcass or node is WaterSource:
			return node

	for entry in in_range:
		if entry["node"] is PartnerWolf:
			return entry["node"]

	return in_range[0]["node"]


func _fail_message_for(node: Node) -> void:
	if node is PartnerWolf:
		if GameState.gestation_active:
			EventBus.ui_toast.emit("Already gestating — wait for birth", 2.0)
		elif not needs.is_fed_for_mate():
			EventBus.ui_toast.emit("Need hunger & thirst above 50% to mate", 2.0)
		elif not (node as PartnerWolf).needs.is_fed_for_mate():
			EventBus.ui_toast.emit("Partner needs food and water first", 2.0)
		else:
			EventBus.ui_toast.emit("Cannot mate right now", 1.5)
	elif node is FoodCarcass:
		EventBus.ui_toast.emit("Carcass depleted", 1.5)
	elif node is WaterSource:
		EventBus.ui_toast.emit("Water depleted", 1.5)
