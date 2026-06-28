extends Node

var lineage := LineageRecord.new()
var player_wolf: Node2D = null
var living_heirs: Array[Node2D] = []
var active_gestations: Array = []
var pending_succession_after_gestation: bool = false
var modal_ui_open: bool = false
var run_seed: int = 0
var current_season: String = "spring"


var gestation_active: bool:
	get:
		return not active_gestations.is_empty()
	set(value):
		if not value:
			active_gestations.clear()


var gestation_time_left: float:
	get:
		if active_gestations.is_empty():
			return 0.0
		var min_time: float = active_gestations[0].time_left
		for entry in active_gestations:
			min_time = minf(min_time, entry.time_left)
		return min_time
	set(value):
		if not active_gestations.is_empty():
			active_gestations[0].time_left = value


var gestation_partner: PartnerWolf:
	get:
		if active_gestations.is_empty():
			return null
		return active_gestations[0].partner as PartnerWolf
	set(_value):
		pass


var pending_offspring: Dictionary:
	get:
		if active_gestations.is_empty():
			return {}
		return active_gestations[0].pending
	set(value):
		if active_gestations.is_empty():
			active_gestations.append({
				"time_left": GameConstants.GESTATION_SECONDS,
				"partner": null,
				"pending": value,
			})
		else:
			active_gestations[0].pending = value


func reset_for_new_run() -> void:
	lineage = LineageRecord.new()
	player_wolf = null
	living_heirs.clear()
	active_gestations.clear()
	pending_succession_after_gestation = false
	modal_ui_open = false
	run_seed = 0
	current_season = "spring"


func register_heir(wolf: Node2D) -> void:
	if wolf not in living_heirs:
		living_heirs.append(wolf)


func unregister_heir(wolf: Node2D) -> void:
	living_heirs.erase(wolf)


func get_living_heirs() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for heir in living_heirs:
		if is_instance_valid(heir) and not heir.is_dead:
			result.append(heir)
	return result


func prune_dead_heirs() -> void:
	var kept: Array[Node2D] = []
	for heir in living_heirs:
		if is_instance_valid(heir) and not heir.is_dead:
			kept.append(heir)
	living_heirs = kept


func is_partner_gestating(partner: PartnerWolf) -> bool:
	if partner == null:
		return false
	for entry in active_gestations:
		if entry.get("partner") == partner:
			return true
	return false


func add_gestation(partner: PartnerWolf, pending: Dictionary) -> void:
	active_gestations.append({
		"time_left": GameConstants.GESTATION_SECONDS,
		"partner": partner,
		"pending": pending,
	})


func remove_gestation(entry: Dictionary) -> void:
	active_gestations.erase(entry)


func retarget_gestation_parent(from_wolf, to_wolf) -> void:
	for entry in active_gestations:
		var pending: Dictionary = entry.get("pending", {})
		if pending.get("parent") == from_wolf:
			pending["parent"] = to_wolf


func get_pack_size() -> int:
	var count := 0
	if player_wolf != null and is_instance_valid(player_wolf) and not player_wolf.is_dead:
		count += 1
	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if node is PartnerWolf and is_instance_valid(node) and not node.is_dead:
			count += 1
	count += get_dependent_pup_count()
	return count


func get_dependent_pup_count() -> int:
	var count := 0
	for heir in get_living_heirs():
		if heir is SonWolf:
			var son := heir as SonWolf
			if son.is_pack_dependent():
				count += 1
	return count


func get_pack_members(include_player: bool = false) -> Array[Wolf]:
	var members: Array[Wolf] = []
	if include_player and player_wolf is Wolf and is_instance_valid(player_wolf):
		var player := player_wolf as Wolf
		if not player.is_dead:
			members.append(player)
	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if node is PartnerWolf and is_instance_valid(node) and not node.is_dead:
			members.append(node as Wolf)
	for heir in get_living_heirs():
		if heir is SonWolf and (heir as SonWolf).is_pack_dependent():
			members.append(heir as Wolf)
	return members
