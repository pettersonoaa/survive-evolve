class_name WolfSpriteFactory
extends RefCounted

## Procedural top-down wolf pixels until real Aseprite sheets (STEP-20).


static func create(body_color: Color, body_size: Vector2) -> ImageTexture:
	var w := maxi(int(body_size.x), 12)
	var h := maxi(int(body_size.y), 16)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var dark := body_color.darkened(0.35)
	var light := body_color.lightened(0.15)
	var cx := w / 2

	# Feet row
	for x in range(cx - 2, cx + 3):
		_paint(img, x, h - 1, dark)

	# Body
	for y in range(h / 3, h - 1):
		var half := int(lerpf(2.0, float(w) * 0.45, float(y) / float(h)))
		for x in range(cx - half, cx + half + 1):
			var c := light if x == cx else body_color
			_paint(img, x, y, c)

	# Head
	var head_y := h / 4
	for y in range(head_y, h / 3 + 2):
		for x in range(cx - 2, cx + 3):
			_paint(img, x, y, body_color)
	_paint(img, cx - 2, head_y, dark)
	_paint(img, cx + 2, head_y, dark)

	# Ears
	_paint(img, cx - 2, head_y - 1, dark)
	_paint(img, cx + 2, head_y - 1, dark)

	# Tail
	_paint(img, cx + int(w * 0.35), h / 2, dark)
	_paint(img, cx + int(w * 0.4), h / 2 - 1, body_color.darkened(0.2))

	var tex := ImageTexture.create_from_image(img)
	return tex


static func _paint(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, color)
