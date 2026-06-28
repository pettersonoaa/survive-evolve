extends CanvasModulate

var _time := 0.12


func _ready() -> void:
	add_to_group("day_night_cycle")


func _process(delta: float) -> void:
	_time += delta / GameConstants.DAY_CYCLE_SECONDS
	if _time > 1.0:
		_time -= 1.0
	var sun := (cos(_time * TAU) + 1.0) * 0.5
	var brightness := lerpf(0.42, 1.0, sun)
	color = Color(brightness, brightness * 0.96, brightness * 0.88, 1.0)
