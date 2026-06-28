class_name EvolutionResolver
extends RefCounted


static func roll_child(parent_node_id: String, partner_genes: WolfGenes) -> String:
	var tree := EvolutionRegistry.get_evolution_tree("wolf")
	if tree == null:
		return "wolf_base"

	var node: EvolutionNode = tree.nodes.get(parent_node_id)
	if node == null:
		return tree.root_node_id

	var candidates: Array[String] = node.child_ids
	if candidates.is_empty():
		return parent_node_id

	var weights: Array[float] = []
	var total := 0.0
	for child_id: String in candidates:
		var weight := float(node.child_base_weights.get(child_id, 1.0))
		if partner_genes != null:
			weight *= float(partner_genes.branch_weights.get(child_id, 1.0))
		weights.append(weight)
		total += weight

	if total <= 0.0:
		return candidates[0]

	var roll := randf() * total
	var accum := 0.0
	for i in candidates.size():
		accum += weights[i]
		if roll <= accum:
			return candidates[i]
	return candidates.back()


static func get_mate_preview(parent_node_id: String, partner_genes: WolfGenes, limit: int = 3) -> PackedStringArray:
	var tree := EvolutionRegistry.get_evolution_tree("wolf")
	if tree == null:
		return PackedStringArray()
	var node: EvolutionNode = tree.nodes.get(parent_node_id)
	if node == null or node.child_ids.is_empty():
		return PackedStringArray()

	var scored: Array = []
	for child_id: String in node.child_ids:
		var weight := float(node.child_base_weights.get(child_id, 1.0))
		if partner_genes != null:
			weight *= float(partner_genes.branch_weights.get(child_id, 1.0))
		scored.append({"weight": weight, "name": get_display_name(child_id)})
	scored.sort_custom(func(a, b): return a["weight"] > b["weight"])

	var names: PackedStringArray = []
	for i in mini(limit, scored.size()):
		names.append(scored[i]["name"])
	return names


static func build_offspring_stats(parent, partner_genes: WolfGenes, child_node_id: String) -> WolfStats:
	var tree := EvolutionRegistry.get_evolution_tree("wolf")
	var stats: WolfStats = parent.stats.duplicate_stats()
	if partner_genes != null:
		stats.apply_stat_bias(partner_genes.stat_bias)
	if tree == null:
		return stats
	var node: EvolutionNode = tree.nodes.get(child_node_id)
	if node != null:
		stats.apply_deltas(node.stat_deltas)
	return stats


static func is_apex(node_id: String) -> bool:
	var tree := EvolutionRegistry.get_evolution_tree("wolf")
	if tree == null:
		return false
	var node: EvolutionNode = tree.nodes.get(node_id)
	return node != null and node.is_apex


static func get_display_name(node_id: String) -> String:
	var tree := EvolutionRegistry.get_evolution_tree("wolf")
	var node: EvolutionNode = tree.nodes.get(node_id)
	if node == null:
		return node_id
	return node.display_name
