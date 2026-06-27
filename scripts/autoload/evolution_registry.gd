extends Node

const PARTNER_PRESETS := {
	"forest_wolf": {
		"tag": "Forest blood",
		"color": Color(0.42, 0.42, 0.45),
		"branch_weights": {
			"keen_nose": 2.5, "night_vision": 2.0, "lean_body": 1.8, "scavenger": 1.5,
			"long_legs": 0.6, "pack_call": 0.7, "sprinter": 0.5,
		},
		"stat_bias": {"hunger_decay": 0.9, "move_speed": 0.95},
	},
	"plains_wolf": {
		"tag": "Plains blood",
		"color": Color(0.58, 0.44, 0.32),
		"branch_weights": {
			"long_legs": 2.5, "sprinter": 2.0, "pack_call": 1.8, "flank_instinct": 1.5,
			"keen_nose": 0.6, "lean_body": 0.7, "scavenger": 0.5,
		},
		"stat_bias": {"move_speed": 1.1, "metabolism": 1.05},
	},
	"tundra_wolf": {
		"tag": "Tundra blood",
		"color": Color(0.93, 0.94, 0.96),
		"branch_weights": {
			"thick_hide": 2.5, "lean_body": 2.0, "iron_gut": 2.0, "winter_coat": 2.2,
			"fast_metabolism": 1.6, "scavenger": 1.5, "mountain_goat": 1.8, "den_keeper": 1.5,
			"sprinter": 0.4, "pack_call": 0.5, "flank_instinct": 0.6, "burst_hunter": 0.5,
		},
		"stat_bias": {"max_health": 1.1, "hunger_decay": 0.88, "thirst_decay": 0.92},
	},
}

var _trees: Dictionary = {}


func _ready() -> void:
	_trees["wolf"] = WolfTreeBuilder.build()


func get_evolution_tree(species_id: String) -> EvolutionTree:
	return _trees.get(species_id)


func make_partner_genes(archetype_id: String) -> WolfGenes:
	var preset: Dictionary = PARTNER_PRESETS.get(archetype_id, PARTNER_PRESETS["forest_wolf"])
	var genes := WolfGenes.new()
	genes.archetype_id = archetype_id
	genes.display_tag = preset["tag"]
	genes.branch_weights = preset["branch_weights"].duplicate()
	genes.stat_bias = preset["stat_bias"].duplicate()
	return genes


func get_partner_color(archetype_id: String) -> Color:
	var preset: Dictionary = PARTNER_PRESETS.get(archetype_id, PARTNER_PRESETS["forest_wolf"])
	return preset["color"]
