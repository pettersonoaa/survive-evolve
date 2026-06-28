extends Control

const COLOR_PLAYER := Color(0.9, 0.9, 0.95)
const COLOR_PARTNER := Color(0.55, 0.75, 0.95)
const COLOR_PUP := Color(0.75, 0.85, 0.55)
const COLOR_ROGUE := Color(0.95, 0.35, 0.3)
const COLOR_PREDATOR := Color(0.85, 0.25, 0.25)
const COLOR_PREY := Color(0.85, 0.7, 0.45)
const COLOR_TERRITORY := Color(0.45, 0.65, 0.45, 0.35)

@onready var _season_label: Label = $Panel/SeasonLabel


func _ready() -> void:
	EventBus.season_changed.connect(func(_s): queue_redraw())
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if _season_label != null:
		var season_mgr := get_tree().get_first_node_in_group("season_manager")
		if season_mgr != null and season_mgr.has_method("get_display_name"):
			_season_label.text = season_mgr.get_display_name()
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 4.0
	draw_circle(center, radius, Color(0.08, 0.1, 0.08, 0.88))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.35, 0.38, 0.32), 1.5)

	var player := GameState.player_wolf
	if player == null or not is_instance_valid(player):
		return

	var origin: Vector2 = player.global_position
	_draw_territory_ring(center, origin, radius)
	_draw_entities(center, origin, radius)


func _draw_territory_ring(center: Vector2, origin: Vector2, map_radius: float) -> void:
	var territory := get_tree().get_first_node_in_group("territory_manager")
	if territory == null or not territory.has_method("get_center"):
		return
	var den_center: Vector2 = territory.get_center()
	var rel := den_center - origin
	if rel.length() > GameConstants.MINIMAP_RADIUS + GameConstants.TERRITORY_RADIUS:
		return
	var scale := map_radius / GameConstants.MINIMAP_RADIUS
	var dot := center + rel * scale
	var ring_r := GameConstants.TERRITORY_RADIUS * scale
	draw_arc(dot, ring_r, 0.0, TAU, 32, COLOR_TERRITORY, 2.0)


func _draw_entities(center: Vector2, origin: Vector2, map_radius: float) -> void:
	_plot_dot(center, origin, origin, map_radius, COLOR_PLAYER, 4.0)

	for node in get_tree().get_nodes_in_group("partner_wolf"):
		if node is PartnerWolf and is_instance_valid(node) and not node.is_dead:
			_plot_dot(center, origin, node.global_position, map_radius, COLOR_PARTNER, 3.0)

	for heir in GameState.get_living_heirs():
		if heir is SonWolf and is_instance_valid(heir) and not heir.is_dead:
			var son := heir as SonWolf
			var col := COLOR_ROGUE if son.is_hostile() else (COLOR_PUP if son.is_pack_dependent() else Color(0.7, 0.72, 0.78))
			_plot_dot(center, origin, son.global_position, map_radius, col, 3.0)

	for node in get_tree().get_nodes_in_group("predator_wolf"):
		if node is PredatorWolf and is_instance_valid(node) and not node.is_dead:
			_plot_dot(center, origin, node.global_position, map_radius, COLOR_PREDATOR, 2.5)

	for node in get_tree().get_nodes_in_group("prey_animal"):
		if is_instance_valid(node) and not node.get("is_dead"):
			_plot_dot(center, origin, node.global_position, map_radius, COLOR_PREY, 2.0)


func _plot_dot(
	center: Vector2,
	origin: Vector2,
	world_pos: Vector2,
	map_radius: float,
	color: Color,
	dot_radius: float,
) -> void:
	var rel := world_pos - origin
	if rel.length() > GameConstants.MINIMAP_RADIUS:
		return
	var scale := map_radius / GameConstants.MINIMAP_RADIUS
	var dot := center + rel * scale
	draw_circle(dot, dot_radius, color)
