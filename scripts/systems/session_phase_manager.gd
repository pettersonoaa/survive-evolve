extends Node

const MID_REFILL := 12.0
const LATE_REFILL := 8.0

var _last_phase := "Early"


func _ready() -> void:
	add_to_group("session_phase_manager")


func _process(_delta: float) -> void:
	if GameState.player_wolf == null or GameState.lineage.is_game_over:
		return
	var phase := _current_phase()
	if phase == _last_phase:
		return
	_last_phase = phase
	_on_phase_entered(phase)


func _current_phase() -> String:
	var seconds := GameState.run_elapsed_seconds
	if seconds >= GameConstants.SESSION_MID_SECONDS:
		return "Late"
	if seconds >= GameConstants.SESSION_EARLY_SECONDS:
		return "Mid"
	return "Early"


func _on_phase_entered(phase: String) -> void:
	if phase == "Mid" and not GameState.session_mid_rewarded:
		GameState.session_mid_rewarded = true
		LineageMeta.record_mid_session()
		_grant_refill(MID_REFILL)
		EventBus.ui_toast.emit("Mid run — survival bonus +%.0f needs" % MID_REFILL, 2.8)
	elif phase == "Late" and not GameState.session_late_rewarded:
		GameState.session_late_rewarded = true
		LineageMeta.record_late_session()
		_grant_refill(LATE_REFILL)
		EventBus.ui_toast.emit("Late run — veteran bonus +%.0f needs" % LATE_REFILL, 2.8)


func _grant_refill(amount: float) -> void:
	var wolf := GameState.player_wolf
	if wolf == null or not wolf.has_node("NeedsComponent"):
		return
	var needs: NeedsComponent = wolf.get_node("NeedsComponent")
	needs.eat(amount)
	needs.drink(amount)
