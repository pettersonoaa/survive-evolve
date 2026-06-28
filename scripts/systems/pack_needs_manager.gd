extends Node


func _ready() -> void:
	add_to_group("pack_needs_manager")
	EventBus.consume_food.connect(_on_consume_food)
	EventBus.consume_water.connect(_on_consume_water)


func _on_consume_food(_player, amount: float) -> void:
	_feed_pack(amount, true)


func _on_consume_water(_player, amount: float) -> void:
	_feed_pack(amount, false)


func _feed_pack(amount: float, is_food: bool) -> void:
	var share := amount * GameConstants.PACK_FEED_SHARE
	for member in GameState.get_pack_members(false):
		if member.needs == null:
			continue
		if is_food:
			member.needs.eat(share)
		else:
			member.needs.drink(share)
