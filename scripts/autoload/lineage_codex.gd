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
