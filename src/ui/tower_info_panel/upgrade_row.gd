extends VBoxContainer
class_name UpgradeRow

signal upgrade_requested(upgrade_id: String)

@onready var title_label: Label = %TitleLabel
@onready var details_label: Label = %DetailsLabel
@onready var buy_button: Button = %BuyButton

var upgrade_id: String = ""
var cost: int = 0


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)


func setup(upgrade_data: Dictionary) -> void:
	upgrade_id = upgrade_data["id"]
	cost = upgrade_data["cost"]
	var level = upgrade_data["level"]
	var name_text = upgrade_data["name"]
	title_label.text = "%s (Lv.%d)" % [name_text, level]
	details_label.text = "%s -> %s" % [upgrade_data["current_text"], upgrade_data["next_text"]]
	buy_button.text = "%d" % cost
	
	update_gold_state(GoldManager.gold)


func update_gold_state(current_gold: int) -> void:
	if current_gold < cost:
		buy_button.disabled = true
		buy_button.modulate = Color(1, 1, 1, 0.5)
	else:
		buy_button.disabled = false
		buy_button.modulate = Color(1, 1, 1, 1.0)


func _on_buy_pressed() -> void:
	upgrade_requested.emit(upgrade_id)
