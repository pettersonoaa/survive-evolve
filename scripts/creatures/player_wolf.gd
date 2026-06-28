extends Wolf
class_name PlayerWolf


func _ready() -> void:
	is_player_controlled = true
	body_color = Color(0.55, 0.55, 0.58)
	current_node_id = "wolf_base"
	trait_display_name = "Grey Wolf"
	super._ready()
