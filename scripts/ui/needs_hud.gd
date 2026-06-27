extends Control

const COLOR_HEALTH_OK := Color(0.35, 0.82, 0.42)
const COLOR_HEALTH_WARN := Color(0.95, 0.75, 0.2)
const COLOR_HEALTH_CRIT := Color(0.92, 0.28, 0.28)
const COLOR_HUNGER_OK := Color(0.78, 0.52, 0.22)
const COLOR_HUNGER_WARN := Color(0.95, 0.55, 0.15)
const COLOR_HUNGER_CRIT := Color(0.85, 0.2, 0.15)
const COLOR_THIRST_OK := Color(0.28, 0.55, 0.95)
const COLOR_THIRST_WARN := Color(0.35, 0.7, 0.95)
const COLOR_THIRST_CRIT := Color(0.15, 0.35, 0.85)
const COLOR_BAR_BG := Color(0.12, 0.12, 0.14, 0.92)

@onready var _health_label: Label = $Panel/HealthLabel
@onready var _hunger_label: Label = $Panel/HungerLabel
@onready var _thirst_label: Label = $Panel/ThirstLabel
@onready var _health: ProgressBar = $Panel/HealthBar
@onready var _hunger: ProgressBar = $Panel/HungerBar
@onready var _thirst: ProgressBar = $Panel/ThirstBar

var _damage_flash := 0.0
var _health_fill := StyleBoxFlat.new()
var _hunger_fill := StyleBoxFlat.new()
var _thirst_fill := StyleBoxFlat.new()


func _ready() -> void:
	EventBus.wolf_damaged.connect(_on_damaged)
	_setup_bar(_health, _health_fill)
	_setup_bar(_hunger, _hunger_fill)
	_setup_bar(_thirst, _thirst_fill)


func _setup_bar(bar: ProgressBar, fill_style: StyleBoxFlat) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = COLOR_BAR_BG
	bg.set_corner_radius_all(5)
	bg.set_border_width_all(1)
	bg.border_color = Color(0.35, 0.35, 0.38)
	fill_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill_style)
	bar.show_percentage = false


func _process(delta: float) -> void:
	var wolf := GameState.player_wolf
	if wolf == null or not is_instance_valid(wolf):
		return

	var health_pct: float = wolf.health / wolf.stats.max_health * 100.0
	var hunger_pct: float = wolf.needs.hunger
	var thirst_pct: float = wolf.needs.thirst

	_health.value = health_pct
	_hunger.value = hunger_pct
	_thirst.value = thirst_pct

	_health_label.text = _bar_text("Health", health_pct, _state_for(health_pct))
	_hunger_label.text = _bar_text("Hunger", hunger_pct, _state_for(hunger_pct))
	_thirst_label.text = _bar_text("Thirst", thirst_pct, _state_for(thirst_pct))

	_set_fill_color(_health_fill, health_pct, COLOR_HEALTH_OK, COLOR_HEALTH_WARN, COLOR_HEALTH_CRIT)
	_set_fill_color(_hunger_fill, hunger_pct, COLOR_HUNGER_OK, COLOR_HUNGER_WARN, COLOR_HUNGER_CRIT)
	_set_fill_color(_thirst_fill, thirst_pct, COLOR_THIRST_OK, COLOR_THIRST_WARN, COLOR_THIRST_CRIT)

	if _damage_flash > 0.0:
		_damage_flash -= delta
		_health_fill.bg_color = COLOR_HEALTH_CRIT.lightened(0.15)
	else:
		_set_fill_color(_health_fill, health_pct, COLOR_HEALTH_OK, COLOR_HEALTH_WARN, COLOR_HEALTH_CRIT)


func _bar_text(name: String, value: float, state: String) -> String:
	return "%s: %.1f%% — %s" % [name, value, state]


func _state_for(value: float) -> String:
	if value <= 25.0:
		return "CRITICAL"
	if value <= 50.0:
		return "LOW"
	return "OK"


func _set_fill_color(style: StyleBoxFlat, value: float, ok: Color, warn: Color, crit: Color) -> void:
	if value <= 25.0:
		style.bg_color = crit
	elif value <= 50.0:
		style.bg_color = warn
	else:
		style.bg_color = ok


func _on_damaged(wolf: Node, _amount: float) -> void:
	if wolf == GameState.player_wolf:
		_damage_flash = 0.3
