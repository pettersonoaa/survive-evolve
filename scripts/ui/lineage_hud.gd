extends Control

@onready var _gen_label: Label = $Panel/GenLabel
@onready var _trait_label: Label = $Panel/TraitLabel
@onready var _heir_label: Label = $Panel/HeirLabel
@onready var _threat_label: Label = $Panel/ThreatLabel
@onready var _session_label: Label = $Panel/SessionLabel
@onready var _gestation_label: Label = $Panel/GestationLabel

var _flash_time := 0.0


func _ready() -> void:
	EventBus.mate_completed.connect(_on_mate_completed)
	EventBus.wolf_needs_critical.connect(_on_needs_critical)
	EventBus.consume_food.connect(func(_w, a): EventBus.ui_toast.emit("+%.0f Hunger" % a, 1.2))
	EventBus.consume_water.connect(func(_w, a): EventBus.ui_toast.emit("+%.0f Thirst" % a, 1.2))


func _process(delta: float) -> void:
	var wolf := GameState.player_wolf
	if wolf != null and is_instance_valid(wolf):
		_gen_label.text = "Gen: %d" % GameState.lineage.generation
		_trait_label.text = "Trait: %s" % wolf.trait_display_name
		GameState.prune_dead_heirs()
		_heir_label.text = "Heirs: %d (pups %d)" % [GameState.living_heirs.size(), GameState.get_dependent_pup_count()]
		_threat_label.text = "Threat: %s (pack %d)" % [_threat_tier(), GameState.get_pack_size()]
		_session_label.text = "Run: %s" % _format_session(GameState.run_elapsed_seconds)
	if GameState.gestation_active:
		var parts: PackedStringArray = []
		for entry in GameState.active_gestations:
			var partner: PartnerWolf = entry.get("partner") as PartnerWolf
			var tag := partner.genes.display_tag if partner != null else "?"
			parts.append("%s %ds" % [tag, int(ceil(entry.time_left))])
		_gestation_label.text = "Gestation: %s" % ", ".join(parts)
		_gestation_label.visible = true
	else:
		_gestation_label.visible = false


func _on_mate_completed(_parent: Node, _partner: Node, son: Node) -> void:
	if son is Wolf:
		var w: Wolf = son as Wolf
		var tag := ""
		if w.partner_genes_at_birth != null:
			tag = w.partner_genes_at_birth.display_tag
		EventBus.ui_toast.emit("Son ready: %s (%s)" % [w.trait_display_name, tag], 2.5)


func _on_needs_critical(wolf: Node, need: String) -> void:
	if wolf == GameState.player_wolf:
		if need == "hunger":
			EventBus.ui_toast.emit("Low hunger — find food!", 2.0)
		else:
			EventBus.ui_toast.emit("Low thirst — find water!", 2.0)
		return
	if wolf is Wolf and not wolf.is_dead:
		var label := "Pack member"
		if wolf is PartnerWolf:
			label = (wolf as PartnerWolf).genes.display_tag
		elif wolf is SonWolf:
			label = "Pup %s" % wolf.trait_display_name
		if need == "hunger":
			EventBus.ui_toast.emit("%s is starving!" % label, 2.0)
		else:
			EventBus.ui_toast.emit("%s is thirsty!" % label, 2.0)


func _threat_tier() -> String:
	var pressure := GameState.lineage.generation + maxi(GameState.get_pack_size() - 2, 0)
	if pressure < 2:
		return "Calm"
	if pressure < 5:
		return "Tense"
	if pressure < 8:
		return "Harsh"
	return "Deadly"


func _format_session(seconds: float) -> String:
	var total := maxi(int(seconds), 0)
	var minutes := total / 60
	var secs := total % 60
	var phase := "Early"
	if seconds >= GameConstants.SESSION_MID_SECONDS:
		phase = "Late"
	elif seconds >= GameConstants.SESSION_EARLY_SECONDS:
		phase = "Mid"
	return "%dm %02ds (%s)" % [minutes, secs, phase]
