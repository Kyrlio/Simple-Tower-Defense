extends CanvasLayer
class_name HUD

@onready var gold_label: Label = $MarginContainer/GoldLabel
@onready var health_bar: ProgressBar = $MarginContainer/HealthBar

func _ready() -> void:
	GoldManager.gold_changed.connect(_update_gold_label)
	GameEvents.castle_health_changed.connect(_on_castle_health_changed)
	GameEvents.game_over.connect(_on_game_over)
	_update_gold_label(GoldManager.gold)


func _update_gold_label(amount: int) -> void:
	gold_label.text = "Gold: " + str(amount)


func _on_castle_health_changed(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(health_bar, "value", current, 0.3)
	
	var health_ratio: float = float(current) / float(max_health)
	if health_ratio > 0.6:
		health_bar.modulate = Color(0.2, 1.0, 0.2)
	elif health_ratio > 0.25:
		health_bar.modulate = Color(1.0, 0.6, 0.0)
	else:
		health_bar.modulate = Color(1.0, 0.2, 0.2)


func _on_game_over() -> void:
	print("Game Over")
