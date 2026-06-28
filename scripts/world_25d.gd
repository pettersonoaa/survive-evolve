extends Node2D


func _ready() -> void:
	add_to_group("world_root")
	var load_save := LineageSave.should_load_on_start()
	LineageSave.clear_skip_load_once()
	if load_save:
		call_deferred("_load_saved_run")
	else:
		GameState.reset_for_new_run()
		call_deferred("_bind_player_wolf")


func _load_saved_run() -> void:
	LineageSave.load_into_world(self)


func _bind_player_wolf() -> void:
	if GameState.player_wolf != null and is_instance_valid(GameState.player_wolf):
		return
	var player := $WorldContent/YSort/PlayerWolf
	if player != null and is_instance_valid(player):
		GameState.player_wolf = player
