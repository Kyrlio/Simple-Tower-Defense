extends Button
class_name TowerAnchorButton

@export var tower_stats: TowerStats

@onready var icon_rect: TextureRect = $IconRect
@onready var cost_label: Label = $CostLabel
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	if tower_stats:
		name = tower_stats.tower_name
		name_label.text = tower_stats.tower_name
		cost_label.text = str(tower_stats.cost)
		
		var temp_instance = tower_stats.tower_scene.instantiate()
		var sprite = temp_instance.get_node_or_null("Visuals/BaseTower") as Sprite2D
		if sprite:
			icon_rect.texture = sprite.texture
		temp_instance.queue_free()
		
		GoldManager.gold_changed.connect(_on_gold_changed)
		_on_gold_changed(GoldManager.gold)


func _pressed() -> void:
	GameEvents.tower_selected.emit(tower_stats)



func _on_gold_changed(current_gold: int) -> void:
	if current_gold < tower_stats.cost:
		disabled = true
		modulate.a = 0.5
	else:
		disabled = false
		modulate.a = 1.0
