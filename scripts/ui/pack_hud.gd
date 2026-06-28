extends Control

const COLOR_HUNGER_OK := Color(0.78, 0.52, 0.22)
const COLOR_HUNGER_WARN := Color(0.95, 0.55, 0.15)
const COLOR_HUNGER_CRIT := Color(0.85, 0.2, 0.15)
const COLOR_THIRST_OK := Color(0.28, 0.55, 0.95)
const COLOR_THIRST_WARN := Color(0.35, 0.7, 0.95)
const COLOR_THIRST_CRIT := Color(0.15, 0.35, 0.85)
const COLOR_BAR_BG := Color(0.12, 0.12, 0.14, 0.92)

@onready var _rows: VBoxContainer = $Panel/Scroll/Rows
@onready var _title: Label = $Panel/Title

var _refresh_timer := 0.0
var _last_pack_key := ""


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer > 0.0:
		return
	_refresh_timer = 0.25
	var key := _pack_key()
	if key != _last_pack_key:
		_last_pack_key = key
		_rebuild_rows()
	else:
		_update_bar_values()


func _pack_key() -> String:
	var parts: PackedStringArray = []
	for member in GameState.get_pack_members(false):
		if member.needs != null:
			parts.append("%s:%.0f:%.0f" % [member.get_instance_id(), member.needs.hunger, member.needs.thirst])
	return "|".join(parts)


func _rebuild_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()

	var members := GameState.get_pack_members(false)
	_title.text = "Pack (%d) — gestating partners + pups" % GameState.get_pack_size()
	if members.is_empty():
		var empty := Label.new()
		empty.text = "No pack members yet"
		_rows.add_child(empty)
		return

	for member in members:
		_rows.add_child(_make_row(member))


func _update_bar_values() -> void:
	var members := GameState.get_pack_members(false)
	var idx := 0
	for child in _rows.get_children():
		if not child is VBoxContainer or idx >= members.size():
			continue
		var member := members[idx]
		idx += 1
		if member.needs == null or child.get_child_count() < 3:
			continue
		var hunger := child.get_child(1) as ProgressBar
		var thirst := child.get_child(2) as ProgressBar
		if hunger != null:
			_style_bar(hunger, member.needs.hunger, COLOR_HUNGER_OK, COLOR_HUNGER_WARN, COLOR_HUNGER_CRIT)
		if thirst != null:
			_style_bar(thirst, member.needs.thirst, COLOR_THIRST_OK, COLOR_THIRST_WARN, COLOR_THIRST_CRIT)


func _make_row(member: Wolf) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var label := Label.new()
	label.text = _member_name(member)
	box.add_child(label)

	var hunger := ProgressBar.new()
	hunger.min_value = 0.0
	hunger.max_value = 100.0
	hunger.custom_minimum_size = Vector2(0, 10)
	hunger.show_percentage = false
	_style_bar(hunger, member.needs.hunger, COLOR_HUNGER_OK, COLOR_HUNGER_WARN, COLOR_HUNGER_CRIT)
	box.add_child(hunger)

	var thirst := ProgressBar.new()
	thirst.min_value = 0.0
	thirst.max_value = 100.0
	thirst.custom_minimum_size = Vector2(0, 10)
	thirst.show_percentage = false
	_style_bar(thirst, member.needs.thirst, COLOR_THIRST_OK, COLOR_THIRST_WARN, COLOR_THIRST_CRIT)
	box.add_child(thirst)

	return box


func _member_name(member: Wolf) -> String:
	if member is PartnerWolf:
		return (member as PartnerWolf).genes.display_tag
	if member is SonWolf:
		var son := member as SonWolf
		return "%s: %s" % [son.get_life_stage_label(), member.trait_display_name]
	return member.trait_display_name


func _style_bar(bar: ProgressBar, value: float, ok: Color, warn: Color, crit: Color) -> void:
	bar.value = clampf(value, 0.0, 100.0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = COLOR_BAR_BG
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.set_corner_radius_all(2)
	if value <= 25.0:
		fill.bg_color = crit
	elif value <= 50.0:
		fill.bg_color = warn
	else:
		fill.bg_color = ok
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
