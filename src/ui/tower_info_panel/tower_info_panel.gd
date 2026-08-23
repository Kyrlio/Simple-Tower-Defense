extends PanelContainer
class_name TowerInfoPanel

enum Tab { STATS, UPGRADES }

@onready var name_label: Label = %TowerName
@onready var close_button: Button = %CloseButton
@onready var stats_tab_btn: Button = %StatsTabButton
@onready var upgrades_tab_btn: Button = %UpgradesTabButton
@onready var stats_container: Control = %StatsContainer
@onready var upgrades_container: Control = %UpgradesContainer
@onready var damage_val: Label = %DamageValue
@onready var reload_val: Label = %ReloadValue
@onready var speed_val: Label = %SpeedValue
@onready var range_val: Label = %RangeValue
@onready var special_val: Label = %SpecialValue
@onready var upgrades_list: VBoxContainer = %UpgradesList

const UPGRADE_ROW_SCENE = preload("res://src/ui/tower_info_panel/upgrade_row.tscn")

var current_tower: Tower = null
var current_tab: Tab = Tab.STATS
var tween: Tween
var is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	modulate.a = 0.0
	
	close_button.pressed.connect(_on_close_pressed)
	stats_tab_btn.pressed.connect(func(): set_tab(Tab.STATS))
	upgrades_tab_btn.pressed.connect(func(): set_tab(Tab.UPGRADES))
	GameEvents.tower_inspected.connect(_on_tower_inspected)
	GameEvents.tower_uninspected.connect(_on_tower_uninspected)
	GameEvents.tower_upgraded.connect(_on_tower_upgraded)
	GoldManager.gold_changed.connect(_on_gold_changed)
	
	set_tab(Tab.STATS)


func set_tab(tab: Tab) -> void:
	current_tab = tab
	stats_container.visible = (tab == Tab.STATS)
	upgrades_container.visible = (tab == Tab.UPGRADES)
	
	var active_color = Color(0.0, 0.596, 0.863, 1.0)
	var inactive_color = Color(0.102, 0.098, 0.196, 1.0)
	
	stats_tab_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if tab == Tab.STATS else Color(0.85, 0.85, 0.85, 0.7)
	upgrades_tab_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if tab == Tab.UPGRADES else Color(0.85, 0.85, 0.85, 0.7)
	
	#stats_tab_btn.add_theme_color_override("font_color", active_color if tab == Tab.STATS else inactive_color)
	#upgrades_tab_btn.add_theme_color_override("font_color", active_color if tab == Tab.UPGRADES else inactive_color)



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


func _on_tower_upgraded(tower: Tower) -> void:
	if is_open and current_tower == tower:
		_update_info(tower)


func _on_gold_changed(current_gold: int) -> void:
	if is_open and is_instance_valid(upgrades_list):
		for child in upgrades_list.get_children():
			if child is UpgradeRow:
				child.update_gold_state(current_gold)


func _on_upgrade_requested(upgrade_id: String) -> void:
	if not current_tower or not is_instance_valid(current_tower):
		return
	if current_tower.upgrade(upgrade_id):
		_punch_effect()


func _update_info(tower: Tower) -> void:
	name_label.text = tower.get_tower_name()
	
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
		
	_populate_upgrades(tower)


func _populate_upgrades(tower: Tower) -> void:
	if not upgrades_list:
		return
		
	var upgrades = tower.get_available_upgrades()
	var current_children = upgrades_list.get_children()
	
	# Réutilisation des nœuds existants (Pooling) pour un rendu instantané à 0ms
	for i in range(upgrades.size()):
		var row: UpgradeRow
		if i < current_children.size():
			row = current_children[i] as UpgradeRow
			row.visible = true
		else:
			row = UPGRADE_ROW_SCENE.instantiate() as UpgradeRow
			upgrades_list.add_child(row)
			row.upgrade_requested.connect(_on_upgrade_requested)
		row.setup(upgrades[i])
	
	# Masquer les lignes excédentaires si la tour en a moins
	for i in range(upgrades.size(), current_children.size()):
		current_children[i].visible = false




func _open_panel() -> void:
	is_open = true
	visible = true
	
	$AnimationPlayer.play("show")
	
	#if tween:
		#tween.kill()
	#tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	#tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	#tween.tween_property(self, "modulate:a", 1.0, 0.15).from(0.0)
	#tween.tween_property(self, "offset_transform_scale", Vector2(1.0, 1.0), 0.15).from(Vector2(0.92, 0.92))
	#tween.chain().tween_callback(func():
		#if is_open:
			#modulate.a = 1.0
			#offset_transform_scale = Vector2.ONE
	#)


func _punch_effect() -> void:
	modulate.a = 1.0
	
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "offset_transform_scale", Vector2(1.04, 1.04), 0.08)
	tween.tween_property(self, "offset_transform_scale", Vector2(1.0, 1.0), 0.12)


func _close_panel() -> void:
	is_open = false
	current_tower = null
	
	$AnimationPlayer.play("hide")
	
	#if tween:
		#tween.kill()
	#tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	#tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	#tween.tween_property(self, "modulate:a", 0.0, 0.15)
	#tween.tween_callback(func():
		#if not is_open:
			#visible = false
	#)
