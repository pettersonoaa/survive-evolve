extends Entity25D
class_name Wolf

@export var stats: WolfStats
@export var is_player_controlled: bool = false
@export var is_heir: bool = false
@export var current_node_id: String = "wolf_base"
@export var trait_display_name: String = "Grey Wolf"

var health: float = 100.0
var is_dead: bool = false
var partner_genes_at_birth: WolfGenes = null

@onready var needs: NeedsComponent = $NeedsComponent


func _ready() -> void:
	if stats == null:
		stats = WolfStats.new()
	health = stats.max_health
	body_size = Vector2(26.0, 42.0) if not is_heir else Vector2(20.0, 32.0)
	if trait_display_name.is_empty():
		trait_display_name = EvolutionResolver.get_display_name(current_node_id)
	super._ready()


func _process(delta: float) -> void:
	if is_dead:
		return
	super._process(delta)
	if is_player_controlled:
		_handle_movement(delta)
	_apply_needs_damage(delta)


func _handle_movement(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		return
	var world_content := get_tree().get_first_node_in_group("world_content") as Node2D
	if world_content != null:
		world_content.position -= direction.normalized() * stats.move_speed * delta
		global_position = Vector2.ZERO
	else:
		global_position += direction.normalized() * stats.move_speed * delta


func _apply_needs_damage(delta: float) -> void:
	var damage := needs.get_passive_damage() * delta
	if damage > 0.0:
		take_damage(damage, "needs")


func take_damage(amount: float, cause: String = "unknown") -> void:
	if is_dead:
		return
	health -= amount
	if amount > 0.0:
		EventBus.wolf_damaged.emit(self, amount)
	if health <= 0.0:
		_die(cause)


func _die(cause: String) -> void:
	is_dead = true
	set_process(false)
	modulate = Color(0.4, 0.4, 0.4, 0.5)
	EventBus.wolf_died.emit(self, cause)


func get_metabolism() -> float:
	return stats.metabolism


func get_hunger_decay_mult() -> float:
	return stats.hunger_decay_mult


func get_thirst_decay_mult() -> float:
	return stats.thirst_decay_mult
