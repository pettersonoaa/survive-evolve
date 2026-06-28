extends Node

const SEASONS := ["spring", "summer", "autumn", "winter"]
const SEASON_LABELS := {
	"spring": "Spring",
	"summer": "Summer",
	"autumn": "Autumn",
	"winter": "Winter",
}
const SEASON_NEEDS_MULT := {
	"spring": 0.92,
	"summer": 1.05,
	"autumn": 1.0,
	"winter": 1.18,
}

var _timer := 0.0


func _ready() -> void:
	add_to_group("season_manager")
	GameState.current_season = "spring"


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= GameConstants.SEASON_CYCLE_SECONDS:
		_timer = 0.0
		_advance_season()


func get_needs_mult() -> float:
	return SEASON_NEEDS_MULT.get(GameState.current_season, 1.0)


func get_display_name() -> String:
	return SEASON_LABELS.get(GameState.current_season, "Spring")


func _advance_season() -> void:
	var idx := SEASONS.find(GameState.current_season)
	if idx < 0:
		idx = 0
	idx = (idx + 1) % SEASONS.size()
	GameState.current_season = SEASONS[idx]
	EventBus.season_changed.emit(GameState.current_season)
	EventBus.ui_toast.emit("Season: %s" % get_display_name(), 2.5)
