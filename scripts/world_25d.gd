extends Node2D

const _WorldGenerator = preload("res://scripts/systems/world_generator.gd")


func _ready() -> void:
	add_to_group("world_root")
	var load_save := LineageSave.should_load_on_start()
	LineageSave.clear_skip_load_once()
	if load_save:
		call_deferred("_load_saved_run")
	else:
		GameState.reset_for_new_run()
		GameState.run_seed = randi()
		call_deferred("_setup_new_run")


func _setup_new_run() -> void:
	LineageMeta.record_run_started()
	_bind_player_wolf()
	_WorldGenerator.scatter(self, GameState.run_seed)
	call_deferred("_apply_world_scaling")
	call_deferred("_apply_meta_bonuses")


func _apply_meta_bonuses() -> void:
	var wolf := GameState.player_wolf
	if wolf == null or not wolf.has_node("NeedsComponent"):
		return
	var needs: NeedsComponent = wolf.get_node("NeedsComponent")
	var bonus := LineageMeta.get_starting_refill()
	if bonus > 0.0:
		needs.eat(bonus)
		needs.drink(bonus)
		EventBus.ui_toast.emit("Lineage memory: +%.0f needs (tier %s)" % [
			bonus, LineageMeta.get_milestone_name()
		], 2.8)


func _load_saved_run() -> void:
	LineageSave.load_into_world(self)
	call_deferred("_ensure_predators_on_continue")
	call_deferred("_apply_world_scaling")


func _ensure_predators_on_continue() -> void:
	var seed_val := GameState.run_seed
	if seed_val == 0:
		seed_val = hash("continue_predators_%d" % GameState.lineage.generation)
	_WorldGenerator.ensure_predators(self, seed_val)


func _apply_world_scaling() -> void:
	for node in get_tree().get_nodes_in_group("difficulty_scaler"):
		node.call("_apply_scaling")


func _bind_player_wolf() -> void:
	if GameState.player_wolf != null and is_instance_valid(GameState.player_wolf):
		return
	var player := $WorldContent/YSort/PlayerWolf
	if player != null and is_instance_valid(player):
		GameState.player_wolf = player
