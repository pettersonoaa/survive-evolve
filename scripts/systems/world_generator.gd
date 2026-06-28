class_name WorldGenerator
extends RefCounted

const SCATTER_RADIUS := 1500.0
const _PredatorScene := preload("res://scenes/creatures/predator_wolf.tscn")


static func scatter(world: Node2D, seed_val: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var ysort := world.get_node_or_null("WorldContent/YSort") as Node2D
	if ysort == null:
		return

	ensure_predators(world, seed_val)

	for child in ysort.get_children():
		if child is FoodCarcass:
			_reset_resource(child as FoodCarcass)
			child.global_position = _random_point(rng)
		elif child is WaterSource:
			_reset_resource(child as WaterSource)
			child.global_position = _random_point(rng)
		elif child is PreyAnimal:
			if not (child as PreyAnimal).is_dead:
				child.global_position = _random_point(rng)
		elif child is PartnerWolf:
			child.global_position = _partner_point(rng, world, child as PartnerWolf)
		elif child is PredatorWolf:
			child.global_position = _random_point(rng, 320.0)
		elif child.name.begins_with("Tree") or child.name.begins_with("Rock"):
			child.global_position = _random_point(rng, 200.0)

	if world.has_node("WorldContent"):
		(world.get_node("WorldContent") as Node2D).position = Vector2.ZERO


static func ensure_predators(world: Node2D, seed_val: int) -> void:
	var ysort := world.get_node_or_null("WorldContent/YSort") as Node2D
	if ysort == null:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var living := 0
	var name_index := 0
	for child in ysort.get_children():
		if child is PredatorWolf:
			living += 1
			name_index = maxi(name_index, _predator_name_index(child.name))

	var target := _predator_target_count()
	while living < target:
		name_index += 1
		var predator := _PredatorScene.instantiate() as PredatorWolf
		predator.name = _predator_name(name_index)
		ysort.add_child(predator)
		predator.global_position = _random_point(rng, 320.0)
		living += 1


static func _predator_target_count() -> int:
	var gen_bonus := int(GameState.lineage.generation / 2)
	var pack_bonus := maxi(GameState.get_pack_size() - 1, 0) * GameConstants.PREDATOR_PER_PACK_MEMBER
	return mini(GameConstants.PREDATOR_BASE_COUNT + gen_bonus + pack_bonus, GameConstants.PREDATOR_MAX_COUNT)


static func _predator_name_index(node_name: String) -> int:
	if not node_name.begins_with("Predator"):
		return 0
	var suffix := node_name.trim_prefix("Predator")
	if suffix.is_valid_int():
		return int(suffix)
	if suffix.length() == 1:
		return suffix.unicode_at(0) - "A".unicode_at(0) + 1
	return 0


static func _predator_name(index: int) -> String:
	if index >= 1 and index <= 26:
		return "Predator%s" % char(ord("A") + index - 1)
	return "Predator%d" % index


static func _reset_resource(node: Node) -> void:
	if node is FoodCarcass:
		(node as FoodCarcass).depleted = false
	elif node is WaterSource:
		(node as WaterSource).depleted = false
	node.modulate = Color(1, 1, 1, 1)


static func _random_point(rng: RandomNumberGenerator, min_radius: float = 120.0) -> Vector2:
	var angle := rng.randf() * TAU
	var dist := rng.randf_range(min_radius, SCATTER_RADIUS)
	return Vector2(cos(angle), sin(angle)) * dist


static func _partner_point(rng: RandomNumberGenerator, world: Node2D, partner: PartnerWolf) -> Vector2:
	var archetype := partner.archetype_id
	for biome in world.get_tree().get_nodes_in_group("biome_zone"):
		if biome.get("biome_id") == _archetype_biome(archetype):
			var center: Vector2 = biome.global_position
			var radius: float = biome.get("zone_radius") if biome.get("zone_radius") else 200.0
			var offset := Vector2(rng.randf_range(-radius * 0.5, radius * 0.5), rng.randf_range(-radius * 0.5, radius * 0.5))
			return center + offset
	return _random_point(rng)


static func _archetype_biome(archetype_id: String) -> String:
	match archetype_id:
		"tundra_wolf":
			return "tundra"
		"desert_wolf":
			return "desert"
		"plains_wolf":
			return "forest"
		_:
			return "forest"
