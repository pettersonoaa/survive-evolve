extends Entity25D
class_name Wolf

@export var stats: WolfStats
@export var is_player_controlled: bool = false
@export var is_heir: bool = false
@export var current_node_id: String = "wolf_base"
@export var trait_display_name: String = "Grey Wolf"

var health: float = 100.0
var is_dead: bool = false
var partner_genes_at_birth: WolfGenes = null
var _attack_cooldown := 0.0

@onready var needs: NeedsComponent = $NeedsComponent


func _ready() -> void:
	if stats == null:
		stats = WolfStats.new()
	health = stats.max_health
	body_size = Vector2(26.0, 42.0) if not is_heir else Vector2(20.0, 32.0)
	if trait_display_name.is_empty():
		trait_display_name = EvolutionResolver.get_display_name(current_node_id)
	super._ready()


func _process(delta: float) -> void:
	if is_dead:
		return
	super._process(delta)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if is_player_controlled:
		_handle_movement(delta)
		global_position = Vector2.ZERO
	elif is_heir:
		_follow_as_heir(delta)
	_apply_needs_damage(delta)


func _follow_as_heir(_delta: float) -> void:
	pass


func _handle_movement(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		return
	var world_content := get_tree().get_first_node_in_group("world_content") as Node2D
	if world_content != null:
		world_content.position -= direction.normalized() * stats.move_speed * delta
	else:
		global_position += direction.normalized() * stats.move_speed * delta


func _unhandled_input(event: InputEvent) -> void:
	if not is_player_controlled or is_dead or GameState.modal_ui_open:
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
	if target.is_in_group("predator_wolf") or target.is_in_group("prey_animal"):
		if _try_attack(target):
			return
		EventBus.ui_toast.emit("Attack on cooldown — wait a moment", 1.2)
		return
	if target.has_method("handle_interact") and target.handle_interact(self):
		return
	_fail_message_for(target)


func _try_attack(target: Node) -> bool:
	if _attack_cooldown > 0.0 or not target.has_method("receive_bite"):
		return false
	if target.get("is_dead"):
		return false
	if not InteractUtils.is_in_interact_range(self, target):
		return false
	target.receive_bite(self)
	_attack_cooldown = GameConstants.ATTACK_COOLDOWN
	return true


func _has_approach_target() -> bool:
	for node in get_tree().get_nodes_in_group("predator_wolf"):
		if node is PredatorWolf and not (node as PredatorWolf).is_dead:
			if InteractUtils.is_in_approach_range(self, node):
				return true
	for node in get_tree().get_nodes_in_group("prey_animal"):
		if node.get("is_dead"):
			continue
		if InteractUtils.is_in_approach_range(self, node):
			return true
	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if node is PartnerWolf and not (node as PartnerWolf).is_dead:
			if InteractUtils.is_in_mate_range(self, node):
				return true
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
	var best_predator: PredatorWolf = null
	var best_predator_dist := GameConstants.INTERACT_RANGE + 1.0
	for node in get_tree().get_nodes_in_group("predator_wolf"):
		if not node is PredatorWolf:
			continue
		var predator := node as PredatorWolf
		if predator.is_dead:
			continue
		var dist := InteractUtils.distance_to(self, predator)
		if dist <= GameConstants.INTERACT_RANGE and dist < best_predator_dist:
			best_predator_dist = dist
			best_predator = predator
	if best_predator != null:
		return best_predator

	var best_prey: Node = null
	var best_prey_dist := GameConstants.INTERACT_RANGE + 1.0
	for node in get_tree().get_nodes_in_group("prey_animal"):
		if node.get("is_dead"):
			continue
		var dist := InteractUtils.distance_to(self, node)
		if dist <= GameConstants.INTERACT_RANGE and dist < best_prey_dist:
			best_prey_dist = dist
			best_prey = node
	if best_prey != null:
		return best_prey

	var best_partner: PartnerWolf = null
	var best_partner_dist := GameConstants.MATE_RANGE + 1.0
	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if not node is PartnerWolf:
			continue
		var partner := node as PartnerWolf
		if partner.is_dead or GameState.gestation_active:
			continue
		var dist := InteractUtils.distance_to(self, partner)
		if dist <= GameConstants.MATE_RANGE and dist < best_partner_dist:
			best_partner_dist = dist
			best_partner = partner
	if best_partner != null:
		return best_partner

	var in_range: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("interact_handlers"):
		if not node.has_method("handle_interact"):
			continue
		if node is PartnerWolf:
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

	return in_range[0]["node"]


func _fail_message_for(node: Node) -> void:
	if node is PartnerWolf:
		var partner := node as PartnerWolf
		if GameState.gestation_active:
			EventBus.ui_toast.emit("Already gestating — wait for birth", 2.0)
		elif not InteractUtils.is_in_mate_range(self, partner):
			EventBus.ui_toast.emit("Move closer to mate", 1.5)
		elif GameConstants.MATE_REQUIRES_FED and not needs.is_fed_for_mate():
			EventBus.ui_toast.emit("Need hunger & thirst above 50% to mate", 2.0)
		elif GameConstants.MATE_REQUIRES_FED and not partner.needs.is_fed_for_mate():
			EventBus.ui_toast.emit("Partner needs food and water first", 2.0)
		else:
			EventBus.ui_toast.emit("Cannot mate — try again", 1.5)
	elif node is FoodCarcass:
		EventBus.ui_toast.emit("Carcass depleted", 1.5)
	elif node is WaterSource:
		EventBus.ui_toast.emit("Water depleted", 1.5)


func _apply_needs_damage(delta: float) -> void:
	var damage := needs.get_passive_damage() * delta
	if damage > 0.0:
		take_damage(damage, "needs")


func take_damage(amount: float, cause: String = "unknown") -> void:
	if is_dead:
		return
	health -= amount
	if amount > 0.0:
		EventBus.wolf_damaged.emit(self, amount)
	if health <= 0.0:
		_die(cause)


func _die(cause: String) -> void:
	is_dead = true
	set_process(false)
	modulate = Color(0.4, 0.4, 0.4, 0.5)
	EventBus.wolf_died.emit(self, cause)


func get_metabolism() -> float:
	return stats.metabolism


func get_hunger_decay_mult() -> float:
	return stats.hunger_decay_mult


func get_thirst_decay_mult() -> float:
	return stats.thirst_decay_mult
