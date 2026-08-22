extends Node2D
class_name Tower

@export var shoot_reload_time: float = 1.0

@onready var reload_timer: Timer = $ReloadTimer
@onready var range_indicator: Node2D = get_node_or_null("RangeIndicator")
@onready var click_area: Area2D = get_node_or_null("ClickArea")

var enemies: Array
var stats: TowerStats = null
var is_selected: bool = false
var is_preview: bool = false


func _ready() -> void:
	reload_timer.wait_time = shoot_reload_time
	
	if not is_preview:
		if not is_in_group("towers"):
			add_to_group("towers")
		scale = Vector2.ZERO
		var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(self, "scale", Vector2(1, 1), 0.8)
		
		GameEvents.tower_inspected.connect(_on_tower_inspected)
		GameEvents.tower_uninspected.connect(_on_tower_uninspected)
		
		if click_area:
			click_area.input_event.connect(_on_click_area_input_event)


func _physics_process(_delta: float) -> void:
	pass


func _on_enemy_detection_area_area_entered(area: Area2D) -> void:
	if area not in enemies:
		enemies.append(area)


func _on_enemy_detection_area_area_exited(area: Area2D) -> void:
	if area in enemies:
		enemies.erase(area)


func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_preview:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Si on est en train de poser une tour, on ne sélectionne pas
		for pm in get_tree().get_nodes_in_group("placement_manager"):
			if "is_placing" in pm and pm.is_placing:
				return
		get_viewport().set_input_as_handled()
		select()


func select() -> void:
	GameEvents.tower_inspected.emit(self)


func set_selected(selected: bool) -> void:
	is_selected = selected
	if range_indicator:
		range_indicator.set_active(selected)


func _on_tower_inspected(inspected_tower: Tower) -> void:
	if inspected_tower == self:
		set_selected(true)
	else:
		set_selected(false)


func _on_tower_uninspected() -> void:
	set_selected(false)


func get_tower_name() -> String:
	if stats and stats.tower_name != "":
		return stats.tower_name
	return name.replace("@", "").capitalize()


func get_tower_icon() -> Texture2D:
	if stats and stats.tower_icon:
		return stats.tower_icon
	var base_sprite = get_node_or_null("Visuals/BaseTower") as Sprite2D
	if base_sprite:
		return base_sprite.texture
	return null


func get_damage_value() -> float:
	if "damage" in self:
		return float(get("damage"))
	elif "base_damage" in self:
		return float(get("base_damage"))
	return 0.0


func get_reload_time() -> float:
	if reload_timer and reload_timer.wait_time > 0:
		return reload_timer.wait_time
	return shoot_reload_time


func get_attack_speed() -> float:
	var r_time = get_reload_time()
	if r_time > 0:
		return 1.0 / r_time
	return 0.0


func get_detection_range() -> float:
	var col = get_node_or_null("EnemyDetectionArea/CollisionShape2D") as CollisionShape2D
	if col and col.shape is CircleShape2D:
		return (col.shape as CircleShape2D).radius
	return 56.0


func get_special_description() -> String:
	return "Tour défensive standard."
