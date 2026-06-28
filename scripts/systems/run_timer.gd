extends Node


func _ready() -> void:
	add_to_group("run_timer")


func _process(delta: float) -> void:
	if GameState.player_wolf == null or GameState.lineage.is_game_over:
		return
	GameState.run_elapsed_seconds += delta
