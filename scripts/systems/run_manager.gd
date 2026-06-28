extends Node

@onready var _heir_picker: Control = $"../UI/HeirPicker"
@onready var _game_over: Control = $"../UI/GameOverScreen"


func _ready() -> void:
	add_to_group("run_manager")
	EventBus.wolf_died.connect(_on_wolf_died)


func _on_wolf_died(wolf, cause: String) -> void:
	if GameState.lineage.is_game_over:
		return

	if wolf != GameState.player_wolf:
		if wolf.is_heir:
			GameState.unregister_heir(wolf)
		elif wolf is PartnerWolf and GameState.gestation_partner == wolf:
			GameState.gestation_partner = null
		return

	var heirs := GameState.get_living_heirs()
	var at_apex := EvolutionResolver.is_apex(wolf.current_node_id)

	if at_apex and not heirs.is_empty():
		_end_run_win(wolf.trait_display_name)
		return

	if heirs.is_empty():
		if GameState.gestation_active:
			GameState.pending_succession_after_gestation = true
			EventBus.ui_toast.emit("You died — offspring incoming...", 3.0)
			return
		_end_run_fail(cause)
		return

	_open_heir_picker(heirs, wolf)


func _open_heir_picker(heirs: Array, from_wolf) -> void:
	GameState.modal_ui_open = true
	get_tree().paused = true
	if _heir_picker.has_method("open_picker"):
		_heir_picker.open_picker(heirs, from_wolf)


func end_run_fail(cause: String) -> void:
	_end_run_fail(cause)


func _end_run_fail(cause: String) -> void:
	GameState.lineage.is_game_over = true
	GameState.modal_ui_open = true
	get_tree().paused = true
	EventBus.game_over.emit("no_heir")
	if _game_over.has_method("show_game_over"):
		_game_over.show_game_over("no_heir", cause)


func _end_run_win(apex_name: String) -> void:
	GameState.lineage.is_game_over = true
	GameState.modal_ui_open = true
	get_tree().paused = true
	EventBus.lineage_complete.emit(GameState.lineage.generation, apex_name)
	if _game_over.has_method("show_lineage_complete"):
		_game_over.show_lineage_complete(apex_name)


func promote_heir(heir: SonWolf, from_wolf) -> void:
	get_tree().paused = false
	GameState.modal_ui_open = false
	heir.promote_to_player()
	if is_instance_valid(from_wolf):
		from_wolf.queue_free()
	EventBus.succession_started.emit(from_wolf, heir)
	EventBus.ui_toast.emit("You are now %s (Gen %d)" % [heir.trait_display_name, GameState.lineage.generation], 3.0)
