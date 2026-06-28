extends Control

const WORLD_SCENE := preload("res://scenes/world.tscn")

@onready var _continue_btn: Button = $Panel/ContinueButton
@onready var _new_btn: Button = $Panel/NewButton
@onready var _codex_btn: Button = $Panel/CodexButton
@onready var _subtitle: Label = $Panel/Subtitle
@onready var _codex_panel: Control = $CodexPanel


func _ready() -> void:
	_continue_btn.visible = LineageSave.has_save()
	_refresh_subtitle()
	_continue_btn.pressed.connect(_on_continue_pressed)
	_new_btn.pressed.connect(_on_new_pressed)
	_codex_btn.pressed.connect(_on_codex_pressed)


func _refresh_subtitle() -> void:
	var codex_line := "Codex: %d / %d traits" % [
		LineageCodex.get_discovered_count(),
		LineageCodex.get_total_count(),
	]
	var meta_line := "Meta: %s · best Gen %d" % [
		LineageMeta.get_milestone_name(),
		LineageMeta.best_generation,
	]
	if LineageSave.has_save():
		_subtitle.text = "Generation %d saved\n%s\n%s" % [_peek_generation(), codex_line, meta_line]
	else:
		_subtitle.text = "No saved lineage\n%s\n%s" % [codex_line, meta_line]


func _on_codex_pressed() -> void:
	if _codex_panel.has_method("open"):
		_codex_panel.open()


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
