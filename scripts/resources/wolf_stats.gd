class_name WolfStats
extends Resource

@export var max_health: float = 100.0
@export var move_speed: float = 220.0
@export var bite_damage: float = 10.0
@export var metabolism: float = 1.0
@export var hunger_decay_mult: float = 1.0
@export var thirst_decay_mult: float = 1.0


func duplicate_stats() -> WolfStats:
	var copy := WolfStats.new()
	copy.max_health = max_health
	copy.move_speed = move_speed
	copy.bite_damage = bite_damage
	copy.metabolism = metabolism
	copy.hunger_decay_mult = hunger_decay_mult
	copy.thirst_decay_mult = thirst_decay_mult
	return copy


func apply_deltas(deltas: Dictionary) -> void:
	for key: String in deltas:
		var value: Variant = deltas[key]
		match key:
			"max_health":
				max_health += float(value)
			"move_speed":
				move_speed += float(value)
			"bite_damage":
				bite_damage += float(value)
			"metabolism":
				metabolism *= float(value)
			"hunger_decay":
				hunger_decay_mult *= 1.0 + float(value)
			"thirst_decay":
				thirst_decay_mult *= 1.0 + float(value)


func apply_stat_bias(bias: Dictionary) -> void:
	for key: String in bias:
		var mult: float = float(bias[key])
		match key:
			"max_health":
				max_health *= mult
			"move_speed":
				move_speed *= mult
			"metabolism":
				metabolism *= mult
			"hunger_decay":
				hunger_decay_mult *= mult
			"thirst_decay":
				thirst_decay_mult *= mult
