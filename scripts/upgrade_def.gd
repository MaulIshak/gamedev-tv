class_name UpgradeDef extends Resource

enum ApplyType { ADDITIVE, INSTANT }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var max_level: int = 3
@export var base_value: float = 0.0
@export var value_per_level: float = 1.0
@export var apply_type: ApplyType = ApplyType.ADDITIVE

@export_group("Icon")
@export var icon_texture: Texture2D
@export var icon_region: Rect2i = Rect2i(0, 0, 0, 0)

func get_value_at_level(level: int) -> float:
	return base_value + value_per_level * level


func get_icon_texture() -> Texture2D:
	if icon_texture == null:
		return null
	if icon_region.size.x <= 0 or icon_region.size.y <= 0:
		return icon_texture

	var atlas := AtlasTexture.new()
	atlas.atlas = icon_texture
	atlas.region = Rect2(icon_region)
	return atlas
