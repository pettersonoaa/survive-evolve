class_name NeedsComponent
extends Node

@export var hunger: float = 100.0
@export var thirst: float = 100.0
@export var hunger_decay_per_sec: float = 1.5
@export var thirst_decay_per_sec: float = 2.0
@export var starve_damage_per_sec: float = 5.0
@export var dehydrate_damage_per_sec: float = 8.0

var _hunger_warned := false
var _thirst_warned := false


func _process(delta: float) -> void:
	var wolf := get_parent()
	var metabolism := 1.0
	if wolf != null and wolf.has_method("get_metabolism"):
		metabolism = wolf.get_metabolism()
	var hunger_mult := 1.0
	var thirst_mult := 1.0
	if wolf != null and wolf.has_method("get_hunger_decay_mult"):
		hunger_mult = wolf.get_hunger_decay_mult()
	if wolf != null and wolf.has_method("get_thirst_decay_mult"):
		thirst_mult = wolf.get_thirst_decay_mult()

	var decay_scale := 1.0
	if wolf != null:
		if wolf.get("is_player_controlled"):
			decay_scale *= GameConstants.PLAYER_NEEDS_DECAY_MULT
			decay_scale *= 1.0 + float(GameState.lineage.generation) * GameConstants.GENERATION_NEEDS_SCALE
			if GameState.gestation_active:
				decay_scale *= 0.35
		elif wolf.get_script() != null:
			var script_path: String = wolf.get_script().resource_path
			if script_path.ends_with("son_wolf.gd") and wolf.is_heir:
				decay_scale *= GameConstants.HEIR_NEEDS_DECAY_MULT
				if InteractUtils.den_covers(wolf.get_tree(), wolf.global_position):
					decay_scale *= GameConstants.DEN_NEEDS_DECAY_MULT

	hunger = maxf(hunger - hunger_decay_per_sec * metabolism * hunger_mult * decay_scale * delta, 0.0)
	thirst = maxf(thirst - thirst_decay_per_sec * metabolism * thirst_mult * decay_scale * delta, 0.0)

	if hunger <= 25.0 and not _hunger_warned:
		_hunger_warned = true
		EventBus.wolf_needs_critical.emit(wolf, "hunger")
	if thirst <= 25.0 and not _thirst_warned:
		_thirst_warned = true
		EventBus.wolf_needs_critical.emit(wolf, "thirst")
	if hunger > 25.0:
		_hunger_warned = false
	if thirst > 25.0:
		_thirst_warned = false


func get_passive_damage() -> float:
	var damage := 0.0
	if hunger <= 0.0:
		damage += starve_damage_per_sec
	if thirst <= 0.0:
		damage += dehydrate_damage_per_sec
	return damage


func eat(amount: float) -> void:
	hunger = clampf(hunger + amount, 0.0, 100.0)


func drink(amount: float) -> void:
	thirst = clampf(thirst + amount, 0.0, 100.0)


func is_fed_for_mate() -> bool:
	if not GameConstants.MATE_REQUIRES_FED:
		return true
	return hunger > 50.0 and thirst > 50.0


func is_starving() -> bool:
	return hunger <= 0.0


func is_dehydrated() -> bool:
	return thirst <= 0.0


func refill() -> void:
	hunger = 100.0
	thirst = 100.0
