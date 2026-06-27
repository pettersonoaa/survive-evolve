extends Wolf
class_name PartnerWolf

@export var archetype_id: String = "forest_wolf"

@export var wander_speed := 48.0
var _wander_dir := Vector2.RIGHT
var _wander_timer := 0.0
var genes: WolfGenes


func _ready() -> void:
	is_player_controlled = false
	genes = EvolutionRegistry.make_partner_genes(archetype_id)
	body_color = EvolutionRegistry.get_partner_color(archetype_id)
	add_to_group("interact_handlers")
	add_to_group("partner_wolf")
	super._ready()
	needs.set_process(false)
	needs.refill()
	_add_tag_label()
	_wander_timer = randf_range(2.0, 4.0)


func _add_tag_label() -> void:
	var label := Label.new()
	label.text = genes.display_tag
	label.position = Vector2(-46, -58)
	label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.88))
	add_child(label)


func _apply_needs_damage(_delta: float) -> void:
	pass


func _process(delta: float) -> void:
	if is_dead:
		return
	super._process(delta)
	var player := GameState.player_wolf
	if player != null and is_instance_valid(player) and not player.is_dead:
		if global_position.distance_to(player.global_position) < GameConstants.PARTNER_IDLE_RANGE:
			return
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.0, 4.0)
		_wander_dir = Vector2.RIGHT.rotated(randf() * TAU)
	global_position += _wander_dir * wander_speed * delta


func handle_interact(player) -> bool:
	if is_dead or player != GameState.player_wolf:
		return false
	if not InteractUtils.is_in_interact_range(player, self):
		return false
	var manager := get_tree().get_first_node_in_group("lineage_manager")
	if manager != null and manager.has_method("try_mate"):
		return manager.try_mate(player, self)
	return false
