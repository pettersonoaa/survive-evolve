extends Control

@onready var _label: Label = $Label

var _step := 0
var _fade := 0.0


func _ready() -> void:
	EventBus.consume_food.connect(func(_w, _a): _advance(1))
	EventBus.consume_water.connect(func(_w, _a): _advance(1))
	EventBus.mate_started.connect(func(_p, _part): _advance(2))
	EventBus.wolf_died.connect(_on_death)


func _process(delta: float) -> void:
	if _fade > 0.0:
		_fade -= delta
		if _fade <= 0.0 and _step < 3:
			_label.modulate.a = 0.85


func _advance(min_step: int) -> void:
	if _step >= 3:
		return
	_step = maxi(_step, min_step)
	_update_text()
	_fade = 10.0


func _on_death(wolf, _cause: String) -> void:
	if wolf == GameState.player_wolf:
		_step = 3
		_label.text = "Choose an heir to continue your lineage."
		_fade = 12.0


func _update_text() -> void:
	match _step:
		0:
			_label.text = "WASD move. Find brown food and blue water — press E."
		1:
			_label.text = "Find a partner (blood tag). Both need >50% needs. Press E to mate."
		2:
			_label.text = "Gestation 60s — needs drain slower. Stay fed!"
		3:
			_label.text = "Choose an heir to continue your lineage."
