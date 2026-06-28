extends Control

var _from_wolf = null


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func open_picker(heirs: Array, from_wolf) -> void:
	_from_wolf = from_wolf
	visible = true
	var list := $Panel/VBox
	for child in list.get_children():
		child.queue_free()
	$Panel/TitleLabel.text = "Your wolf died — choose your heir"
	for i in heirs.size():
		var heir: SonWolf = heirs[i] as SonWolf
		if heir == null:
			continue
		var btn := Button.new()
		btn.text = "%s — %s" % [heir.get_life_stage_label(), heir.trait_display_name]
		btn.pressed.connect(_on_heir_chosen.bind(heir))
		list.add_child(btn)


func _on_heir_chosen(heir: SonWolf) -> void:
	visible = false
	var heirs := GameState.get_living_heirs()
	if heir not in heirs or heir.is_dead:
		EventBus.ui_toast.emit("Heir no longer available", 2.0)
		if heirs.is_empty():
			var run_manager := get_tree().get_first_node_in_group("run_manager")
			if run_manager != null:
				run_manager.end_run_fail("heirs_lost")
		return
	var run_manager := get_tree().get_first_node_in_group("run_manager")
	if run_manager != null and run_manager.has_method("promote_heir"):
		run_manager.promote_heir(heir, _from_wolf)
