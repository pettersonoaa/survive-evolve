extends Area2D
class_name WaterSource

@export var drink_amount: float = 40.0

var depleted: bool = false


func _ready() -> void:
	add_to_group("interact_handlers")
	body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node2D) -> void:
	pass


func handle_interact(player) -> bool:
	if depleted or player == null:
		return false
	if not InteractUtils.is_in_interact_range(player, self):
		return false
	player.needs.drink(drink_amount)
	EventBus.consume_water.emit(player, drink_amount)
	depleted = true
	modulate = Color(0.5, 0.5, 0.5, 0.35)
	EventBus.resource_depleted.emit(self)
	return true
