extends Node

const BASE_DAMAGE := 12.0
const BASE_SPEED_MULT := 0.9


func _ready() -> void:
	add_to_group("difficulty_scaler")
	EventBus.succession_started.connect(func(_a, _b): _apply_scaling())
	EventBus.mate_completed.connect(func(_a, _b, _c): _apply_scaling())
	call_deferred("_apply_scaling")


func _apply_scaling() -> void:
	var gen := GameState.lineage.generation
	var damage_mult := 1.0 + float(gen) * GameConstants.GENERATION_DAMAGE_SCALE
	var speed_mult := 1.0 + float(gen) * GameConstants.GENERATION_SPEED_SCALE
	for node in get_tree().get_nodes_in_group("predator_wolf"):
		if node is PredatorWolf:
			var predator := node as PredatorWolf
			predator.contact_damage = BASE_DAMAGE * damage_mult
			predator.chase_speed_mult = BASE_SPEED_MULT + float(gen) * GameConstants.GENERATION_SPEED_SCALE
