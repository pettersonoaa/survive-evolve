class_name EvolutionNode
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var stat_deltas: Dictionary = {}
@export var child_ids: Array[String] = []
@export var child_base_weights: Dictionary = {}
@export var is_apex: bool = false
