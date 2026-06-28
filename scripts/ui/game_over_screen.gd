extends Control

@onready var _title: Label = $Panel/Title
@onready var _reason: Label = $Panel/Reason
@onready var _restart: Button = $Panel/RestartButton

var _mode := ""


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_restart.pressed.connect(_on_restart_pressed)


func show_game_over(reason: String, cause: String) -> void:
	_mode = "fail"
	visible = true
	_title.text = "Lineage ended"
	var traits := ", ".join(GameState.lineage.traits_seen) if GameState.lineage.traits_seen.size() > 0 else "none"
	match reason:
		"no_heir":
			_reason.text = "No living heir.\nCause: %s\nGeneration: %d\nTraits seen: %s" % [
				cause, GameState.lineage.generation, traits
			]
		_:
			_reason.text = "%s\nTraits seen: %s" % [reason, traits]


func show_lineage_complete(apex_name: String) -> void:
	_mode = "win"
	visible = true
	_title.text = "Lineage complete!"
	var traits := ", ".join(GameState.lineage.traits_seen)
	_reason.text = "Apex: %s\nGeneration: %d\nTraits seen: %s" % [
		apex_name, GameState.lineage.generation, traits
	]


func _on_restart_pressed() -> void:
	get_tree().paused = false
	LineageSave.mark_new_run()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
