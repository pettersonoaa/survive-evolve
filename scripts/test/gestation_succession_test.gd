extends Node

## Reproduces gen-2 gestation crash: parent dies during gestation, heir promoted, birth finishes.

const PASS := "GESTATION_FIX_PASS"
const FAIL := "GESTATION_FIX_FAIL"

var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_run()
	_report()


func _run() -> void:
	var lineage_manager := get_tree().get_first_node_in_group("lineage_manager")
	var run_manager := get_tree().get_first_node_in_group("run_manager")
	if lineage_manager == null or run_manager == null:
		_fail("managers missing")
		return

	# Gen0 mates -> first gestation
	var partner: PartnerWolf = null
	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if node is PartnerWolf and not node.is_dead:
			partner = node
			break
	if partner == null:
		_fail("no partner")
		return
	partner.global_position = GameState.player_wolf.global_position + Vector2(40, 0)
	if not lineage_manager.try_mate(GameState.player_wolf, partner):
		_fail("first mate failed")
		return

	# First gestation -> son1
	while GameState.gestation_active and GameState.gestation_time_left > 0.0:
		lineage_manager._process(1.0)
		await get_tree().process_frame

	var heirs := GameState.get_living_heirs()
	if heirs.is_empty():
		_fail("son1 not born")
		return
	var son1 := heirs[0] as SonWolf

	# Gen0 mates again while son1 lives
	GameState.gestation_active = false
	GameState.gestation_time_left = 0.0
	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if node is PartnerWolf and not node.is_dead:
			partner = node
			break
	if partner == null:
		_fail("no partner")
		return
	partner.global_position = GameState.player_wolf.global_position + Vector2(40, 0)
	if not lineage_manager.try_mate(GameState.player_wolf, partner):
		_fail("second mate failed")
		return

	var stale_parent = GameState.pending_offspring["parent"]
	var gen0 = GameState.player_wolf

	# Reach ~1s left before succession (user-reported crash window)
	while GameState.gestation_active and GameState.gestation_time_left > 1.05:
		lineage_manager._process(0.5)
		await get_tree().process_frame

	if not GameState.gestation_active or GameState.gestation_time_left > 1.05:
		_fail("expected gestation ~1s left before succession, got %.2f" % GameState.gestation_time_left)
		return

	# Gen0 dies, player picks son1 — frees gen0 while gestation still active
	gen0.take_damage(9999.0, "test")
	await get_tree().process_frame
	if not gen0.is_dead:
		_fail("gen0 should be dead")
		return

	run_manager.promote_heir(son1, gen0)
	await get_tree().process_frame

	if is_instance_valid(stale_parent):
		_fail("stale gestation parent should be freed after succession")

	var pending_parent = GameState.pending_offspring.get("parent")
	if not is_instance_valid(pending_parent) or pending_parent != GameState.player_wolf:
		_fail("gestation parent not retargeted to promoted heir after succession")

	while GameState.gestation_active:
		lineage_manager._process(0.1)
		await get_tree().process_frame

	if GameState.get_living_heirs().size() < 2:
		_fail("second son not registered after gestation finish")


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
