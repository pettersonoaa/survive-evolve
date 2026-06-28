extends Node2D


func _ready() -> void:
	GameState.reset_for_new_run()
	call_deferred("_bind_player_wolf")


func _bind_player_wolf() -> void:
	if GameState.player_wolf != null and is_instance_valid(GameState.player_wolf):
		return
	var player := $WorldContent/YSort/PlayerWolf
	if player != null and is_instance_valid(player):
		GameState.player_wolf = player
