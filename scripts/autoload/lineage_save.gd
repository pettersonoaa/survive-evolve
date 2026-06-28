extends Node

const SAVE_PATH := "user://lineage_save.json"
const SAVE_VERSION := 1
const AUTOSAVE_INTERVAL := 45.0

var _skip_load_once := false
var _autosave_timer := 0.0

@onready var _son_scene: PackedScene = preload("res://scenes/creatures/son_wolf.tscn")


func _ready() -> void:
	EventBus.mate_completed.connect(func(_p, _part, _son): save_run())
	EventBus.succession_started.connect(func(_from, _to): save_run())
	EventBus.wolf_died.connect(_on_wolf_died)


func _process(delta: float) -> void:
	if GameState.player_wolf == null or GameState.lineage.is_game_over:
		return
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_run()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_run()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func should_load_on_start() -> bool:
	if _skip_load_once or not has_save():
		return false
	for arg in OS.get_cmdline_args():
		if arg.contains("integration_runner") or arg.contains("gestation_succession"):
			return false
	return true


func mark_new_run() -> void:
	delete_save()
	_skip_load_once = true


func clear_skip_load_once() -> void:
	_skip_load_once = false


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


func save_run() -> void:
	if GameState.lineage.is_game_over:
		return
	var player := GameState.player_wolf
	if player == null or not is_instance_valid(player) or not player is Wolf:
		return
	var wolf := player as Wolf
	if wolf.is_dead:
		return

	var world := get_tree().get_first_node_in_group("world_root")
	var world_content_pos := Vector2.ZERO
	if world != null:
		var world_content := world.get_node_or_null("WorldContent") as Node2D
		if world_content != null:
			world_content_pos = world_content.position

	var heirs_data: Array = []
	for heir in GameState.get_living_heirs():
		if heir is Wolf and is_instance_valid(heir):
			heirs_data.append(_serialize_wolf(heir as Wolf))

	var data := {
		"version": SAVE_VERSION,
		"lineage": {
			"generation": GameState.lineage.generation,
			"traits_seen": GameState.lineage.traits_seen.duplicate(),
		},
		"player": _serialize_wolf(wolf),
		"heirs": heirs_data,
		"world_content": {"x": world_content_pos.x, "y": world_content_pos.y},
		"gestation": _serialize_gestation(),
	}
	var json := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("LineageSave: could not write %s" % SAVE_PATH)
		return
	file.store_string(json)


func load_into_world(world: Node2D) -> void:
	var data := _read_save()
	if data.is_empty():
		GameState.reset_for_new_run()
		return

	GameState.reset_for_new_run()
	var lineage_data: Dictionary = data.get("lineage", {})
	GameState.lineage.generation = int(lineage_data.get("generation", 0))
	GameState.lineage.traits_seen.assign(lineage_data.get("traits_seen", []))

	var ysort := world.get_node_or_null("WorldContent/YSort") as Node2D
	var player := world.get_node_or_null("WorldContent/YSort/PlayerWolf") as Wolf
	if player == null or ysort == null:
		push_error("LineageSave: world nodes missing for load")
		return

	_apply_wolf_data(player, data.get("player", {}))
	player.is_player_controlled = true
	player.is_heir = false
	GameState.player_wolf = player

	var world_content := world.get_node_or_null("WorldContent") as Node2D
	if world_content != null:
		var wc: Dictionary = data.get("world_content", {})
		world_content.position = Vector2(float(wc.get("x", 0.0)), float(wc.get("y", 0.0)))

	for heir_data in data.get("heirs", []):
		if not heir_data is Dictionary:
			continue
		var son: SonWolf = _son_scene.instantiate() as SonWolf
		ysort.add_child(son)
		_apply_wolf_data(son, heir_data)
		son.global_position = Vector2(
			float(heir_data.get("pos_x", 0.0)),
			float(heir_data.get("pos_y", 0.0))
		)

	_apply_gestation(data.get("gestation", {}))
	EventBus.ui_toast.emit("Lineage restored from save", 2.5)


func _on_wolf_died(wolf, _cause: String) -> void:
	if wolf == GameState.player_wolf:
		save_run()


func _serialize_gestation() -> Dictionary:
	if not GameState.gestation_active:
		return {"active": false}
	var pending: Dictionary = GameState.pending_offspring
	var partner_archetype := ""
	if pending.get("partner") is PartnerWolf:
		var partner := pending["partner"] as PartnerWolf
		if partner.genes != null:
			partner_archetype = partner.genes.archetype_id
	var stats_dict := {}
	if pending.get("stats") is WolfStats:
		stats_dict = _serialize_stats(pending["stats"] as WolfStats)
	return {
		"active": true,
		"time_left": GameState.gestation_time_left,
		"pending": {
			"node_id": str(pending.get("node_id", "wolf_base")),
			"trait_name": str(pending.get("trait_name", "")),
			"stats": stats_dict,
			"partner_archetype": partner_archetype,
		},
	}


func _apply_gestation(data: Dictionary) -> void:
	if not data.get("active", false):
		return
	var pending_data: Dictionary = data.get("pending", {})
	var partner_archetype: String = pending_data.get("partner_archetype", "forest_wolf")
	var partner: PartnerWolf = null
	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if node is PartnerWolf and (node as PartnerWolf).genes.archetype_id == partner_archetype:
			partner = node as PartnerWolf
			break
	if partner == null:
		for node in get_tree().get_nodes_in_group("partner_wolf"):
			if node is PartnerWolf:
				partner = node as PartnerWolf
				break
	if partner == null:
		return

	var stats := _stats_from_dict(pending_data.get("stats", {}))
	var node_id: String = pending_data.get("node_id", "wolf_base")
	GameState.pending_offspring = {
		"stats": stats,
		"node_id": node_id,
		"trait_name": pending_data.get("trait_name", EvolutionResolver.get_display_name(node_id)),
		"partner": partner,
		"partner_genes": partner.genes,
		"parent": GameState.player_wolf,
	}
	GameState.gestation_active = true
	GameState.gestation_time_left = float(data.get("time_left", 0.0))
	GameState.gestation_partner = partner


func _serialize_wolf(wolf: Wolf) -> Dictionary:
	return {
		"current_node_id": wolf.current_node_id,
		"trait_display_name": wolf.trait_display_name,
		"health": wolf.health,
		"hunger": wolf.needs.hunger,
		"thirst": wolf.needs.thirst,
		"stats": _serialize_stats(wolf.stats),
		"pos_x": wolf.global_position.x,
		"pos_y": wolf.global_position.y,
	}


func _apply_wolf_data(wolf: Wolf, data: Dictionary) -> void:
	if data.is_empty():
		return
	wolf.current_node_id = str(data.get("current_node_id", "wolf_base"))
	wolf.trait_display_name = str(data.get("trait_display_name", "Grey Wolf"))
	wolf.stats = _stats_from_dict(data.get("stats", {}))
	wolf.health = float(data.get("health", wolf.stats.max_health))
	if wolf.needs != null:
		wolf.needs.hunger = float(data.get("hunger", 100.0))
		wolf.needs.thirst = float(data.get("thirst", 100.0))
	if wolf.is_node_ready():
		wolf._apply_body_sprite()
		wolf._update_geometry()


func _serialize_stats(stats: WolfStats) -> Dictionary:
	if stats == null:
		return {}
	return {
		"max_health": stats.max_health,
		"move_speed": stats.move_speed,
		"bite_damage": stats.bite_damage,
		"metabolism": stats.metabolism,
		"hunger_decay_mult": stats.hunger_decay_mult,
		"thirst_decay_mult": stats.thirst_decay_mult,
	}


func _stats_from_dict(data: Dictionary) -> WolfStats:
	var stats := WolfStats.new()
	stats.max_health = float(data.get("max_health", 100.0))
	stats.move_speed = float(data.get("move_speed", 220.0))
	stats.bite_damage = float(data.get("bite_damage", 10.0))
	stats.metabolism = float(data.get("metabolism", 1.0))
	stats.hunger_decay_mult = float(data.get("hunger_decay_mult", 1.0))
	stats.thirst_decay_mult = float(data.get("thirst_decay_mult", 1.0))
	return stats


func _read_save() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}
