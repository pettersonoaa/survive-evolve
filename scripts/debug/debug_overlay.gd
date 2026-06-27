extends CanvasLayer

@onready var _hint: Label = $Hint


func _ready() -> void:
	if not OS.is_debug_build():
		visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	var player := GameState.player_wolf
	if player == null:
		return
	if event.is_action_pressed("debug_kill"):
		player.take_damage(9999.0, "debug")
	elif event.is_action_pressed("debug_refill"):
		player.needs.refill()
	elif event.is_action_pressed("debug_mate"):
		var manager := get_tree().get_first_node_in_group("lineage_manager")
		if manager != null:
			manager.force_mate_debug()
