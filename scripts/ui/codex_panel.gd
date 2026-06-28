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
	_summary.text = "Traits: %d / %d · Meta tier: %s" % [
		discovered, total, LineageMeta.get_milestone_name(),
	]
	var lines: PackedStringArray = []
	for section in LineageCodex.get_codex_sections():
		lines.append("[b]%s[/b]" % section["branch"])
		for entry in section["entries"]:
			var label: String = entry["name"]
			if not entry["discovered"]:
				label = "???"
			if entry.get("apex", false) and entry["discovered"]:
				label += " (apex)"
			lines.append("  • %s" % label)
		lines.append("")
	if lines.is_empty():
		_list.text = "No traits recorded yet.\nMate and evolve across runs to fill the codex."
	else:
		_list.text = "\n".join(lines)
