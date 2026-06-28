extends Control

const WORLD_SCENE := preload("res://scenes/world.tscn")

@onready var _continue_btn: Button = $Panel/ContinueButton
@onready var _new_btn: Button = $Panel/NewButton
@onready var _subtitle: Label = $Panel/Subtitle


func _ready() -> void:
	_continue_btn.visible = LineageSave.has_save()
	_subtitle.text = "Generation %d saved" % _peek_generation() if LineageSave.has_save() else "No saved lineage"
	_continue_btn.pressed.connect(_on_continue_pressed)
	_new_btn.pressed.connect(_on_new_pressed)


func _on_continue_pressed() -> void:
	if not LineageSave.has_save():
		return
	LineageSave.request_load()
	get_tree().change_scene_to_packed(WORLD_SCENE)


func _on_new_pressed() -> void:
	LineageSave.mark_new_run()
	get_tree().change_scene_to_packed(WORLD_SCENE)


func _peek_generation() -> int:
	var data := LineageSave.peek_save()
	var lineage: Dictionary = data.get("lineage", {})
	return int(lineage.get("generation", 0))
