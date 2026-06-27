class_name WolfTreeBuilder
extends RefCounted


static func build() -> EvolutionTree:
	var tree := EvolutionTree.new()
	tree.species_id = "wolf"
	tree.root_node_id = "wolf_base"

	var defs: Array[Dictionary] = [
		{"id": "wolf_base", "name": "Grey Wolf", "deltas": {}, "children": ["keen_nose", "long_legs", "thick_hide", "lean_body", "pack_call"], "apex": false},
		{"id": "keen_nose", "name": "Keen Nose", "deltas": {"hunger_decay": -0.15}, "children": ["blood_tracker", "night_vision"], "weights": {"blood_tracker": 1.3}, "apex": false},
		{"id": "long_legs", "name": "Long Legs", "deltas": {"move_speed": 25}, "children": ["sprinter", "padded_paws"], "weights": {"sprinter": 1.3}, "apex": false},
		{"id": "thick_hide", "name": "Thick Hide", "deltas": {"max_health": 20}, "children": ["bone_crusher", "iron_gut"], "weights": {"bone_crusher": 1.2}, "apex": false},
		{"id": "lean_body", "name": "Lean Body", "deltas": {"metabolism": 0.85, "move_speed": 10}, "children": ["fast_metabolism", "scavenger"], "apex": false},
		{"id": "pack_call", "name": "Pack Call", "deltas": {"bite_damage": 3}, "children": ["flank_instinct", "rally_howl"], "apex": false},
		{"id": "blood_tracker", "name": "Blood Tracker", "deltas": {"hunger_decay": -0.1}, "children": ["ambush_predator", "trail_runner"], "apex": false},
		{"id": "night_vision", "name": "Night Vision", "deltas": {"move_speed": 5}, "children": ["silent_stalker"], "apex": false},
		{"id": "sprinter", "name": "Sprinter", "deltas": {"move_speed": 20, "metabolism": 1.1}, "children": ["burst_hunter", "marathon_wolf"], "apex": false},
		{"id": "padded_paws", "name": "Padded Paws", "deltas": {"move_speed": 8}, "children": ["mountain_goat"], "apex": false},
		{"id": "bone_crusher", "name": "Bone Crusher", "deltas": {"bite_damage": 8}, "children": ["jaw_lock", "ram_head"], "apex": false},
		{"id": "iron_gut", "name": "Iron Gut", "deltas": {"max_health": 10}, "children": ["toxin_resist"], "apex": false},
		{"id": "fast_metabolism", "name": "Fast Metabolism", "deltas": {"metabolism": 0.9, "thirst_decay": -0.1}, "children": ["winter_coat"], "apex": false},
		{"id": "scavenger", "name": "Scavenger", "deltas": {"hunger_decay": -0.2}, "children": ["carrion_feast"], "apex": false},
		{"id": "flank_instinct", "name": "Flank Instinct", "deltas": {"bite_damage": 5}, "children": ["pincer_bite"], "apex": false},
		{"id": "rally_howl", "name": "Rally Howl", "deltas": {"max_health": 8}, "children": ["pack_frenzy"], "apex": false},
		{"id": "ambush_predator", "name": "Ambush Predator", "deltas": {"bite_damage": 6, "move_speed": 5}, "children": ["ghost_hunter"], "apex": false},
		{"id": "trail_runner", "name": "Trail Runner", "deltas": {"move_speed": 15}, "children": ["wind_chaser"], "apex": false},
		{"id": "silent_stalker", "name": "Silent Stalker", "deltas": {"bite_damage": 4}, "children": ["ghost_hunter"], "apex": false},
		{"id": "burst_hunter", "name": "Burst Hunter", "deltas": {"move_speed": 25, "metabolism": 1.15}, "children": ["wind_chaser"], "apex": false},
		{"id": "marathon_wolf", "name": "Marathon Wolf", "deltas": {"move_speed": 12, "max_health": 5}, "children": ["wind_chaser"], "apex": false},
		{"id": "mountain_goat", "name": "Mountain Goat", "deltas": {"move_speed": 10, "max_health": 15}, "children": ["wind_chaser"], "apex": false},
		{"id": "jaw_lock", "name": "Jaw Lock", "deltas": {"bite_damage": 12}, "children": ["war_wolf"], "apex": false},
		{"id": "ram_head", "name": "Ram Head", "deltas": {"max_health": 15, "bite_damage": 5}, "children": ["war_wolf"], "apex": false},
		{"id": "toxin_resist", "name": "Toxin Resist", "deltas": {"max_health": 12}, "children": ["den_keeper"], "apex": false},
		{"id": "winter_coat", "name": "Winter Coat", "deltas": {"hunger_decay": -0.15, "thirst_decay": -0.1}, "children": ["den_keeper"], "apex": false},
		{"id": "carrion_feast", "name": "Carrion Feast", "deltas": {"hunger_decay": -0.25}, "children": ["den_keeper"], "apex": false},
		{"id": "pincer_bite", "name": "Pincer Bite", "deltas": {"bite_damage": 7}, "children": ["war_wolf", "alpha_instinct"], "apex": false},
		{"id": "pack_frenzy", "name": "Pack Frenzy", "deltas": {"bite_damage": 6, "move_speed": 8}, "children": ["alpha_instinct"], "apex": false},
		{"id": "ghost_hunter", "name": "Ghost Hunter", "deltas": {"bite_damage": 10, "move_speed": 10}, "children": ["apex_stalker"], "apex": false},
		{"id": "wind_chaser", "name": "Wind Chaser", "deltas": {"move_speed": 20, "metabolism": 1.05}, "children": ["apex_stalker"], "apex": false},
		{"id": "war_wolf", "name": "War Wolf", "deltas": {"bite_damage": 15, "max_health": 20}, "children": ["apex_brute"], "apex": false},
		{"id": "den_keeper", "name": "Den Keeper", "deltas": {"max_health": 25, "hunger_decay": -0.2}, "children": ["apex_sovereign"], "apex": false},
		{"id": "alpha_instinct", "name": "Alpha Instinct", "deltas": {"bite_damage": 8, "max_health": 18}, "children": ["apex_sovereign"], "apex": false},
		{"id": "apex_stalker", "name": "Apex Stalker", "deltas": {"bite_damage": 12, "move_speed": 15, "hunger_decay": -0.1}, "children": [], "apex": true},
		{"id": "apex_brute", "name": "Apex Brute", "deltas": {"bite_damage": 25, "max_health": 40}, "children": [], "apex": true},
		{"id": "apex_sovereign", "name": "Apex Sovereign", "deltas": {"max_health": 35, "bite_damage": 10, "metabolism": 0.8}, "children": [], "apex": true},
	]

	for def: Dictionary in defs:
		var node := EvolutionNode.new()
		node.id = def["id"]
		node.display_name = def["name"]
		node.stat_deltas = def["deltas"]
		node.child_ids.assign(def["children"])
		node.is_apex = def["apex"]
		if def.has("weights"):
			for key: String in def["weights"]:
				node.child_base_weights[key] = def["weights"][key]
		tree.nodes[node.id] = node

	return tree
