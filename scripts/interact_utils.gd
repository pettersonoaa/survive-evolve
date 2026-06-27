class_name InteractUtils
extends RefCounted


static func distance_to(player: Node2D, target: Node2D) -> float:
	return player.global_position.distance_to(target.global_position)


static func is_in_interact_range(player: Node2D, target: Node2D) -> bool:
	if distance_to(player, target) <= GameConstants.INTERACT_RANGE:
		return true
	if target is Area2D:
		var area := target as Area2D
		for child in area.get_children():
			if child is CollisionShape2D:
				var shape_node := child as CollisionShape2D
				if shape_node.shape is CircleShape2D:
					var radius: float = (shape_node.shape as CircleShape2D).radius
					var reach := radius + GameConstants.INTERACT_RANGE * 0.35
					if distance_to(player, target) <= reach:
						return true
	return false


static func is_in_approach_range(player: Node2D, target: Node2D) -> bool:
	return distance_to(player, target) <= GameConstants.APPROACH_HINT_RANGE
