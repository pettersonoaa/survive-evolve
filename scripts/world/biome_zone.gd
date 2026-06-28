extends Area2D
class_name BiomeZone

@export var biome_id: String = "forest"
@export var display_name: String = "Forest"
@export var zone_radius: float = 280.0

var _player_inside := false


func _ready() -> void:
	add_to_group("biome_zone")


func _process(_delta: float) -> void:
	var player := GameState.player_wolf
	if player == null or not is_instance_valid(player):
		return
	var inside := global_position.distance_to(player.global_position) <= zone_radius
	if inside and not _player_inside:
		_player_inside = true
		EventBus.ui_toast.emit("Entered %s biome" % display_name, 2.0)
	elif not inside and _player_inside:
		_player_inside = false


func contains_point(global_pos: Vector2) -> bool:
	return global_position.distance_to(global_pos) <= zone_radius


func get_hunger_decay_mult() -> float:
	match biome_id:
		"tundra":
			return 1.08
		"desert":
			return 1.05
		"forest":
			return 0.95
		"plains":
			return 1.02
		_:
			return 1.0


func get_thirst_decay_mult() -> float:
	match biome_id:
		"tundra":
			return 1.0
		"desert":
			return 1.18
		"forest":
			return 0.98
		"plains":
			return 0.96
		_:
			return 1.0
