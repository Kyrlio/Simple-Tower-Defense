extends CanvasLayer
class_name HUD

@onready var gold_label: Label = $MarginContainer/GoldLabel

func _ready() -> void:
	GoldManager.gold_changed.connect(_update_gold_label)
	_update_gold_label(GoldManager.gold)


func _update_gold_label(amount: int) -> void:
	gold_label.text = "Gold: " + str(amount)
