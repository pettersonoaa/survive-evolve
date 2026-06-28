extends Area2D
class_name FoodCarcass

@export var food_amount: float = 35.0

var depleted: bool = false


func _ready() -> void:
	add_to_group("interact_handlers")


func handle_interact(player) -> bool:
	if depleted or player == null:
		return false
	if not InteractUtils.is_in_interact_range(player, self):
		return false
	player.needs.eat(food_amount)
	EventBus.consume_food.emit(player, food_amount)
	depleted = true
	modulate = Color(0.5, 0.5, 0.5, 0.35)
	EventBus.resource_depleted.emit(self)
	return true
