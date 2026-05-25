class_name UpgradeDef extends Resource

enum ApplyType { ADDITIVE, INSTANT }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var max_level: int = 3
@export var base_value: float = 0.0
@export var value_per_level: float = 1.0
@export var apply_type: ApplyType = ApplyType.ADDITIVE

func get_value_at_level(level: int) -> float:
	return base_value + value_per_level * level
