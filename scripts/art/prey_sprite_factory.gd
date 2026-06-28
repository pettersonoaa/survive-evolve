class_name PreySpriteFactory
extends RefCounted

## Procedural top-down deer pixels until real art sheets.


static func create(body_color: Color, body_size: Vector2) -> ImageTexture:
	var w := maxi(int(body_size.x), 10)
	var h := maxi(int(body_size.y), 14)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var dark := body_color.darkened(0.3)
	var light := body_color.lightened(0.12)
	var cx := w / 2

	# Legs
	for leg_x in [cx - 3, cx + 3]:
		for y in range(h - 4, h):
			_paint(img, leg_x, y, dark)

	# Body
	for y in range(h / 3, h - 3):
		var half := int(lerpf(2.0, float(w) * 0.42, float(y) / float(h)))
		for x in range(cx - half, cx + half + 1):
			_paint(img, x, y, light if x == cx else body_color)

	# Head + neck
	for y in range(h / 5, h / 3 + 1):
		for x in range(cx - 2, cx + 1):
			_paint(img, x, y, body_color)
	_paint(img, cx - 2, h / 5 - 1, dark)
	_paint(img, cx - 1, h / 5 - 1, dark)

	var tex := ImageTexture.create_from_image(img)
	return tex


static func _paint(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, color)
