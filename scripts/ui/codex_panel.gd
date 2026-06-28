extends Control

@onready var _list: RichTextLabel = $Panel/Margin/VBox/TraitList
@onready var _summary: Label = $Panel/Margin/VBox/Summary


func _ready() -> void:
	visible = false
	$Panel/Margin/VBox/CloseButton.pressed.connect(hide)


func open() -> void:
	refresh()
	visible = true


func refresh() -> void:
	var discovered := LineageCodex.get_discovered_count()
	var total := LineageCodex.get_total_count()
	_summary.text = "Traits discovered: %d / %d" % [discovered, total]
	var lines: PackedStringArray = []
	for entry in LineageCodex.get_display_entries():
		lines.append("• %s" % entry["name"])
	if lines.is_empty():
		_list.text = "No traits recorded yet.\nMate and evolve across runs to fill the codex."
	else:
		_list.text = "\n".join(lines)
