extends PanelContainer
class_name TowerInfoPanel

@onready var icon_rect: TextureRect = %TowerIcon
@onready var name_label: Label = %TowerName
@onready var close_button: Button = %CloseButton
@onready var damage_val: Label = %DamageValue
@onready var reload_val: Label = %ReloadValue
@onready var speed_val: Label = %SpeedValue
@onready var range_val: Label = %RangeValue
@onready var special_val: Label = %SpecialValue

var current_tower: Tower = null
var tween: Tween
var is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	modulate.a = 0.0
	
	close_button.pressed.connect(_on_close_pressed)
	GameEvents.tower_inspected.connect(_on_tower_inspected)
	GameEvents.tower_uninspected.connect(_on_tower_uninspected)


func _on_tower_inspected(tower: Tower) -> void:
	if not is_instance_valid(tower):
		_on_tower_uninspected()
		return
		
	current_tower = tower
	_update_info(tower)
	
	if not is_open:
		_open_panel()
	else:
		_punch_effect()


func _on_tower_uninspected() -> void:
	if not is_open:
		return
	_close_panel()


func _on_close_pressed() -> void:
	GameEvents.tower_uninspected.emit()


func _update_info(tower: Tower) -> void:
	name_label.text = tower.get_tower_name()
	
	var icon = tower.get_tower_icon()
	if icon:
		icon_rect.texture = icon
		icon_rect.visible = true
	else:
		icon_rect.visible = false
	
	var dmg = tower.get_damage_value()
	damage_val.text = ("%0.1f" % dmg) if dmg != int(dmg) else ("%d" % int(dmg))
	
	var r_time = tower.get_reload_time()
	reload_val.text = "%0.1fs" % r_time
	
	var spd = tower.get_attack_speed()
	speed_val.text = ("%0.1f/s" % spd) if spd != int(spd) else ("%d/s" % int(spd))
	
	var rng = tower.get_detection_range()
	range_val.text = "%d px" % int(rng)
	
	var special_desc = tower.get_special_description()
	if special_desc != "":
		special_val.text = special_desc
		special_val.get_parent().visible = true
	else:
		special_val.get_parent().visible = false


func _open_panel() -> void:
	is_open = true
	visible = true
	
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.15).from(0.0)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).from(Vector2(0.92, 0.92))
	tween.chain().tween_callback(func():
		if is_open:
			modulate.a = 1.0
			scale = Vector2.ONE
	)


func _punch_effect() -> void:
	modulate.a = 1.0
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.08)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)


func _close_panel() -> void:
	is_open = false
	current_tower = null
	
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		if not is_open:
			visible = false
	)
