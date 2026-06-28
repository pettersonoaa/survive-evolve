extends Node

const BASE_DAMAGE := 12.0
const BASE_SPEED_MULT := 0.9
const _WorldGenerator = preload("res://scripts/systems/world_generator.gd")


func _ready() -> void:
	add_to_group("difficulty_scaler")
	EventBus.succession_started.connect(func(_a, _b): _apply_scaling())
	EventBus.mate_completed.connect(func(_a, _b, _c): _apply_scaling())
	call_deferred("_apply_scaling")


func _apply_scaling() -> void:
	var gen := GameState.lineage.generation
	var pack := GameState.get_pack_size()
	var damage_mult := 1.0 + float(gen) * GameConstants.GENERATION_DAMAGE_SCALE
	damage_mult += float(maxi(pack - 2, 0)) * 0.04
	var speed_mult := 1.0 + float(gen) * GameConstants.GENERATION_SPEED_SCALE
	speed_mult += float(maxi(pack - 2, 0)) * 0.02
	for node in get_tree().get_nodes_in_group("predator_wolf"):
		if node is PredatorWolf:
			var predator := node as PredatorWolf
			predator.contact_damage = BASE_DAMAGE * damage_mult
			predator.chase_speed_mult = BASE_SPEED_MULT + float(gen) * GameConstants.GENERATION_SPEED_SCALE + float(maxi(pack - 2, 0)) * 0.02

	var world := get_tree().get_first_node_in_group("world_root") as Node2D
	if world != null:
		var seed_val := GameState.run_seed
		if seed_val == 0:
			seed_val = hash("pack_predators_%d_%d" % [pack, gen])
		_WorldGenerator.ensure_predators(world, seed_val)
