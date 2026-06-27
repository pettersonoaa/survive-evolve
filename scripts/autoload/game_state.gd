extends Node

var lineage := LineageRecord.new()
var player_wolf: Node2D = null
var living_heirs: Array[Node2D] = []
var gestation_active: bool = false
var gestation_time_left: float = 0.0
var pending_offspring: Dictionary = {}
var pending_succession_after_gestation: bool = false
var modal_ui_open: bool = false


func reset_for_new_run() -> void:
	lineage = LineageRecord.new()
	player_wolf = null
	living_heirs.clear()
	gestation_active = false
	gestation_time_left = 0.0
	pending_offspring = {}
	pending_succession_after_gestation = false
	modal_ui_open = false


func register_heir(wolf: Node2D) -> void:
	if wolf not in living_heirs:
		living_heirs.append(wolf)


func unregister_heir(wolf: Node2D) -> void:
	living_heirs.erase(wolf)


func get_living_heirs() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for heir in living_heirs:
		if is_instance_valid(heir) and not heir.is_dead:
			result.append(heir)
	return result


func prune_dead_heirs() -> void:
	var kept: Array[Node2D] = []
	for heir in living_heirs:
		if is_instance_valid(heir) and not heir.is_dead:
			kept.append(heir)
	living_heirs = kept
