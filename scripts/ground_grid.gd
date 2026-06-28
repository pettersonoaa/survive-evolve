extends Node2D
## Procedural ground tiles until a real TileMap / painted terrain exists.


@export var tile_size := 64
@export var extent := 48

const COLOR_A := Color(0.16, 0.21, 0.13, 1.0)
const COLOR_B := Color(0.13, 0.17, 0.11, 1.0)


func _draw() -> void:
	for x in range(-extent, extent):
		for y in range(-extent, extent):
			var color := COLOR_A if (x + y) % 2 == 0 else COLOR_B
			var origin := Vector2(x, y) * float(tile_size)
			draw_rect(Rect2(origin, Vector2(tile_size, tile_size)), color)
