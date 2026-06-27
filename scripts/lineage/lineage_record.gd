class_name LineageRecord
extends RefCounted

var generation: int = 0
var is_game_over: bool = false
var traits_seen: Array[String] = []


func record_trait(trait_name: String) -> void:
	if trait_name not in traits_seen:
		traits_seen.append(trait_name)
