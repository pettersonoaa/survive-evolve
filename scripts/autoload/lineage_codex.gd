extends Node

const CODEX_PATH := "user://lineage_codex.json"

var discovered_node_ids: Array[String] = []


func _ready() -> void:
	_load()
	EventBus.evolution_applied.connect(_on_evolution_applied)
	EventBus.lineage_complete.connect(_on_lineage_complete)
	EventBus.game_over.connect(_on_game_over)


func record_node(node_id: String) -> void:
	if node_id.is_empty() or node_id in discovered_node_ids:
		return
	discovered_node_ids.append(node_id)
	_save()


func get_discovered_count() -> int:
	return discovered_node_ids.size()


func get_total_count() -> int:
	var tree := EvolutionRegistry.get_evolution_tree("wolf")
	if tree == null:
		return 34
	return tree.nodes.size()


func get_display_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var tree := EvolutionRegistry.get_evolution_tree("wolf")
	if tree == null:
		return entries
	for node_id in discovered_node_ids:
		if not tree.nodes.has(node_id):
			continue
		var node: EvolutionNode = tree.nodes[node_id]
		entries.append({"id": node_id, "name": node.display_name})
	entries.sort_custom(func(a, b): return a["name"] < b["name"])
	return entries


const BRANCH_ROOTS := {
	"keen_nose": "Senses",
	"long_legs": "Mobility",
	"thick_hide": "Physique",
	"lean_body": "Metabolism",
	"pack_call": "Pack",
}

const BRANCH_ORDER := ["Senses", "Mobility", "Physique", "Metabolism", "Pack", "Other"]


func get_codex_sections() -> Array[Dictionary]:
	var tree := EvolutionRegistry.get_evolution_tree("wolf")
	if tree == null:
		return []
	var buckets: Dictionary = {}
	for branch in BRANCH_ORDER:
		buckets[branch] = []

	for node_id in tree.nodes:
		var node: EvolutionNode = tree.nodes[node_id]
		if node_id == "wolf_base":
			continue
		var branch := _branch_for_node(tree, node_id)
		if not buckets.has(branch):
			buckets[branch] = []
		buckets[branch].append({
			"id": node_id,
			"name": node.display_name,
			"discovered": node_id in discovered_node_ids,
			"apex": node.is_apex,
		})

	var sections: Array[Dictionary] = []
	for branch in BRANCH_ORDER:
		if not buckets.has(branch) or buckets[branch].is_empty():
			continue
		var entries: Array = buckets[branch]
		entries.sort_custom(func(a, b): return a["name"] < b["name"])
		sections.append({"branch": branch, "entries": entries})
	return sections


func _branch_for_node(tree: EvolutionTree, node_id: String) -> String:
	var current := node_id
	var guard := 0
	while current != "wolf_base" and current != "" and guard < 12:
		if BRANCH_ROOTS.has(current):
			return BRANCH_ROOTS[current]
		current = _parent_of(tree, current)
		guard += 1
	return "Other"


func _parent_of(tree: EvolutionTree, node_id: String) -> String:
	for parent_id in tree.nodes:
		var parent: EvolutionNode = tree.nodes[parent_id]
		if node_id in parent.child_ids:
			return parent_id
	return ""


func _on_evolution_applied(_parent: Node, node_id: String, _display_name: String) -> void:
	record_node(node_id)


func _on_lineage_complete(_generation: int, apex_name: String) -> void:
	for trait_name in GameState.lineage.traits_seen:
		_record_trait_name(trait_name)


func _on_game_over(_reason: String) -> void:
	for trait_name in GameState.lineage.traits_seen:
		_record_trait_name(trait_name)


func _record_trait_name(trait_name: String) -> void:
	var tree := EvolutionRegistry.get_evolution_tree("wolf")
	if tree == null:
		return
	for node_id in tree.nodes:
		var node: EvolutionNode = tree.nodes[node_id]
		if node.display_name == trait_name:
			record_node(node_id)
			return


func _load() -> void:
	if not FileAccess.file_exists(CODEX_PATH):
		return
	var file := FileAccess.open(CODEX_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		discovered_node_ids.assign(parsed.get("discovered", []))


func _save() -> void:
	var file := FileAccess.open(CODEX_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"discovered": discovered_node_ids}, "\t"))
