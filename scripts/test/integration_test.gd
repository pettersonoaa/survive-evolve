extends Node

## Headless integration checks — run:
## godot --path . --headless res://scenes/test/integration_runner.tscn

const PASS := "INTEGRATION_PASS"
const FAIL := "INTEGRATION_FAIL"

var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_run_tests()
	_report()


func _run_tests() -> void:
	_test_player_exists()
	_test_needs_decay()
	_test_mate_without_fed_gate()
	_test_heir_promotion_and_son_mate()
	_test_predator_bite()
	_test_prey_hunt()
	_test_den_spawn()
	_test_lineage_save()


func _test_player_exists() -> void:
	var player := GameState.player_wolf
	if player == null or not is_instance_valid(player):
		_fail("player_wolf missing on start")


func _test_needs_decay() -> void:
	var player := GameState.player_wolf as Wolf
	if player == null:
		return
	var hunger_before: float = player.needs.hunger
	for _i in 30:
		await get_tree().process_frame
	if player.needs.hunger >= hunger_before:
		_fail("player hunger did not decay (before=%.2f after=%.2f)" % [hunger_before, player.needs.hunger])


func _test_mate_without_fed_gate() -> void:
	var player := GameState.player_wolf
	if player == null:
		return
	player.needs.hunger = 5.0
	player.needs.thirst = 5.0
	var partner: PartnerWolf = null
	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if node is PartnerWolf:
			partner = node
			break
	if partner == null:
		_fail("no partner wolf in scene")
		return
	partner.global_position = player.global_position + Vector2(40, 0)
	var manager := get_tree().get_first_node_in_group("lineage_manager")
	if manager == null:
		_fail("lineage_manager missing")
		return
	if not manager.try_mate(player, partner):
		_fail("try_mate failed with low needs while MATE_REQUIRES_FED is false")
	if not GameState.gestation_active:
		_fail("gestation should start after successful mate")


func _test_heir_promotion_and_son_mate() -> void:
	var lineage_manager := get_tree().get_first_node_in_group("lineage_manager")
	if lineage_manager == null:
		_fail("lineage_manager missing")
		return
	if not GameState.gestation_active:
		_fail("gestation not active before forced birth")
		return
	while GameState.gestation_active and GameState.gestation_time_left > 0.0:
		lineage_manager._process(1.0)
		await get_tree().process_frame
	var heirs := GameState.get_living_heirs()
	if heirs.is_empty():
		_fail("no heir after forced gestation")
		return
	var heir := heirs[0] as SonWolf
	if heir == null:
		_fail("heir is not a SonWolf")
		return
	var run_manager := get_tree().get_first_node_in_group("run_manager")
	if run_manager == null:
		_fail("run_manager missing")
		return
	var from_player = GameState.player_wolf
	run_manager.promote_heir(heir, from_player)
	if GameState.player_wolf is PlayerWolf:
		_fail("promote_heir left PlayerWolf as active player")
		return
	if not GameState.player_wolf.is_player_controlled:
		_fail("promoted heir not player controlled")
	var hunger_before: float = GameState.player_wolf.needs.hunger
	for _i in 15:
		await get_tree().process_frame
	if GameState.player_wolf.needs.hunger >= hunger_before:
		_fail("promoted heir hunger did not decay")
	GameState.gestation_active = false
	GameState.gestation_time_left = 0.0
	var partner: PartnerWolf = null
	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if node is PartnerWolf and not node.is_dead:
			partner = node
			break
	if partner == null:
		_fail("no partner for son mate test")
		return
	partner.global_position = GameState.player_wolf.global_position + Vector2(40, 0)
	if not lineage_manager.try_mate(GameState.player_wolf, partner):
		_fail("promoted son cannot mate with partner")


func _test_predator_bite() -> void:
	var player := GameState.player_wolf as Wolf
	if player == null:
		return
	var predator: PredatorWolf = null
	for node in get_tree().get_nodes_in_group("predator_wolf"):
		if node is PredatorWolf and is_instance_valid(node) and not node.is_dead:
			predator = node
			break
	if predator == null:
		_fail("no living predator in scene")
		return
	predator.global_position = player.global_position + Vector2(30, 0)
	var hp_before: float = predator.health
	if not player._try_attack(predator):
		_fail("player bite failed on adjacent predator")
	if predator.health >= hp_before:
		_fail("predator took no damage from bite")


func _test_prey_hunt() -> void:
	var player := GameState.player_wolf as Wolf
	if player == null:
		return
	var prey: Node = null
	for node in get_tree().get_nodes_in_group("prey_animal"):
		if is_instance_valid(node) and not node.get("is_dead"):
			prey = node
			break
	if prey == null:
		_fail("no living prey in scene")
		return
	prey.global_position = player.global_position + Vector2(28, 0)
	player._attack_cooldown = 0.0
	var hp_before: float = prey.health
	if not player._try_attack(prey):
		_fail("player bite failed on adjacent prey")
	if prey.health >= hp_before:
		_fail("prey took no damage from bite")
	prey.health = 0.0
	prey._die()
	await get_tree().process_frame
	var carcass_count := 0
	for node in get_tree().get_nodes_in_group("interact_handlers"):
		if node is FoodCarcass and not (node as FoodCarcass).depleted:
			carcass_count += 1
	if carcass_count < 1:
		_fail("prey death did not spawn a carcass")


func _test_den_spawn() -> void:
	var den: Node2D = InteractUtils.find_den(get_tree())
	if den == null:
		_fail("wolf den missing from world")
		return
	var lineage_manager := get_tree().get_first_node_in_group("lineage_manager")
	if lineage_manager == null:
		_fail("lineage_manager missing for den test")
		return
	if not GameState.gestation_active:
		_fail("gestation not active for den spawn test")
		return
	while GameState.gestation_active and GameState.gestation_time_left > 0.0:
		lineage_manager._process(1.0)
		await get_tree().process_frame
	var heirs := GameState.get_living_heirs()
	if heirs.is_empty():
		_fail("no heir spawned at den")
		return
	var heir := heirs[heirs.size() - 1]
	if not den.has_method("contains_wolf") or not den.contains_wolf(heir):
		_fail("heir not spawned inside den safe zone")


func _test_lineage_save() -> void:
	var player := GameState.player_wolf as Wolf
	if player == null:
		_fail("lineage save test: no player")
		return
	LineageSave.save_run()
	if not LineageSave.has_save():
		_fail("lineage save test: file not written")
		return
	var data := LineageSave._read_save()
	if int(data.get("version", 0)) != 1:
		_fail("lineage save test: bad version")
		return
	var player_data: Dictionary = data.get("player", {})
	if player_data.get("current_node_id", "") == "":
		_fail("lineage save test: player node id missing")
	if float(player_data.get("hunger", -1.0)) < 0.0:
		_fail("lineage save test: player hunger missing")
	LineageSave.delete_save()


func _fail(msg: String) -> void:
	_failures.append(msg)
	push_error(msg)


func _report() -> void:
	if _failures.is_empty():
		print(PASS)
		get_tree().quit(0)
	else:
		print(FAIL)
		for f in _failures:
			print("  - ", f)
		get_tree().quit(1)
