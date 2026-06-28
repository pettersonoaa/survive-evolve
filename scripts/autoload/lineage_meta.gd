extends Node

const META_PATH := "user://lineage_meta.json"

const MILESTONE_NAMES := ["None", "Scout", "Hunter", "Alpha"]

var runs_started: int = 0
var runs_failed: int = 0
var runs_completed: int = 0
var best_generation: int = 0
var runs_reached_mid: int = 0
var runs_reached_late: int = 0


func _ready() -> void:
	_load()
	EventBus.game_over.connect(_on_game_over)
	EventBus.lineage_complete.connect(_on_lineage_complete)


func record_run_started() -> void:
	runs_started += 1
	_save()


func record_failure(generation: int) -> void:
	runs_failed += 1
	best_generation = maxi(best_generation, generation)
	_save()


func record_victory(generation: int) -> void:
	runs_completed += 1
	best_generation = maxi(best_generation, generation)
	_save()


func record_mid_session() -> void:
	runs_reached_mid += 1
	_save()


func record_late_session() -> void:
	runs_reached_late += 1
	_save()


func get_session_starting_bonus() -> float:
	var bonus := 0.0
	if runs_reached_mid > 0:
		bonus += 4.0
	if runs_reached_late > 0:
		bonus += 8.0
	return bonus


func get_milestone_tier() -> int:
	var discovered := LineageCodex.get_discovered_count()
	if discovered >= 20:
		return 3
	if discovered >= 12:
		return 2
	if discovered >= 5:
		return 1
	return 0


func get_milestone_name() -> String:
	return MILESTONE_NAMES[get_milestone_tier()]


func get_needs_decay_mult() -> float:
	match get_milestone_tier():
		3:
			return 0.94
		2:
			return 0.97
		1:
			return 0.98
		_:
			return 1.0


func get_starting_refill() -> float:
	var total := 0.0
	match get_milestone_tier():
		3:
			total += 18.0
		2:
			total += 10.0
		1:
			total += 5.0
	return total + get_session_starting_bonus()


func get_summary_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append("Runs: %d started · %d failed · %d apex wins" % [runs_started, runs_failed, runs_completed])
	lines.append("Best generation: %d" % best_generation)
	lines.append("Meta tier: %s (%d traits)" % [get_milestone_name(), LineageCodex.get_discovered_count()])
	if runs_reached_mid > 0 or runs_reached_late > 0:
		lines.append("Session veteran: %d mid · %d late runs" % [runs_reached_mid, runs_reached_late])
	return lines


func _on_game_over(_reason: String) -> void:
	record_failure(GameState.lineage.generation)


func _on_lineage_complete(generation: int, _apex_name: String) -> void:
	record_victory(generation)


func _load() -> void:
	if not FileAccess.file_exists(META_PATH):
		return
	var file := FileAccess.open(META_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		runs_started = int(parsed.get("runs_started", 0))
		runs_failed = int(parsed.get("runs_failed", 0))
		runs_completed = int(parsed.get("runs_completed", 0))
		best_generation = int(parsed.get("best_generation", 0))
		runs_reached_mid = int(parsed.get("runs_reached_mid", 0))
		runs_reached_late = int(parsed.get("runs_reached_late", 0))


func _save() -> void:
	var file := FileAccess.open(META_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"runs_started": runs_started,
		"runs_failed": runs_failed,
		"runs_completed": runs_completed,
		"best_generation": best_generation,
		"runs_reached_mid": runs_reached_mid,
		"runs_reached_late": runs_reached_late,
	}, "\t"))
