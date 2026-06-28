extends Node

const FOOD_SCENE := preload("res://scenes/resources/food_carcass.tscn")
const WATER_SCENE := preload("res://scenes/resources/water_source.tscn")

var _pending: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("resource_respawn_manager")
	EventBus.resource_depleted.connect(_on_resource_depleted)


func _process(delta: float) -> void:
	var ysort := _get_ysort()
	if ysort == null:
		return
	var finished: Array[int] = []
	for i in _pending.size():
		_pending[i]["timer"] -= delta
		if _pending[i]["timer"] > 0.0:
			continue
		_spawn_resource(ysort, _pending[i])
		finished.append(i)
	for i in range(finished.size() - 1, -1, -1):
		_pending.remove_at(finished[i])


func _on_resource_depleted(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var kind := "food" if node is FoodCarcass else "water" if node is WaterSource else ""
	if kind.is_empty():
		return
	var pos := (node as Node2D).global_position
	node.queue_free()
	_pending.append({
		"kind": kind,
		"timer": GameConstants.RESOURCE_RESPAWN_SECONDS,
		"position": pos,
	})


func _spawn_resource(ysort: Node2D, entry: Dictionary) -> void:
	var jitter := Vector2(randf_range(-48.0, 48.0), randf_range(-48.0, 48.0))
	var pos: Vector2 = entry["position"] + jitter
	if entry["kind"] == "food":
		var node := FOOD_SCENE.instantiate() as FoodCarcass
		ysort.add_child(node)
		node.global_position = pos
	elif entry["kind"] == "water":
		var node := WATER_SCENE.instantiate() as WaterSource
		ysort.add_child(node)
		node.global_position = pos


func _get_ysort() -> Node2D:
	var world := get_tree().get_first_node_in_group("world_root")
	if world == null:
		return null
	return world.get_node_or_null("WorldContent/YSort") as Node2D
