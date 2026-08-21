extends Button
class_name TowerAnchorButton

@export var tower_stats: TowerStats

@onready var icon_rect: TextureRect = $IconRect
@onready var cost_label: Label = $CostLabel
@onready var name_label: Label = $NameLabel


var tween: Tween


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if tower_stats:
		name = tower_stats.tower_name
		name_label.text = tower_stats.tower_name
		cost_label.text = str(tower_stats.cost)
		
		if tower_stats.tower_icon:
			icon_rect.texture = tower_stats.tower_icon
		else:
			var temp_instance = tower_stats.tower_scene.instantiate()
			var sprite = temp_instance.get_node_or_null("Visuals/BaseTower") as Sprite2D
			if sprite:
				icon_rect.texture = sprite.texture
			temp_instance.queue_free()
		
		GoldManager.gold_changed.connect(_on_gold_changed)
		_on_gold_changed(GoldManager.gold)


func _pressed() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "offset_transform_scale", Vector2(1.2, 1.2), 0.65).from(Vector2(0.8, 0.8))
	GameEvents.tower_selected.emit(tower_stats)


func _on_gold_changed(current_gold: int) -> void:
	if current_gold < tower_stats.cost:
		disabled = true
		modulate.a = 0.5
	else:
		disabled = false
		modulate.a = 1.0


func _on_mouse_entered() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "offset_transform_scale", Vector2(1.2, 1.2), 0.2)


func _on_mouse_exited() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "offset_transform_scale", Vector2(1.0, 1.0), 0.4)
