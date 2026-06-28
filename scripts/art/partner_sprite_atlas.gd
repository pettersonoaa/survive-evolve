class_name PartnerSpriteAtlas
extends RefCounted

const SHEET_PATH := "res://assets/sprites/partner/partner_sheet.png"


static func build_sprite_frames(body_color: Color, body_size: Vector2) -> SpriteFrames:
	if ResourceLoader.exists(SHEET_PATH):
		var sheet := load(SHEET_PATH) as Texture2D
		if sheet != null:
			return WolfSpriteAtlas.build_sprite_frames_from_sheet(sheet, body_size)
	return WolfSpriteAtlas.build_sprite_frames(body_color, body_size)
