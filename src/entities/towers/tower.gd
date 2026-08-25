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
var upgrade_levels: Dictionary = {}


func _ready() -> void:
	reload_timer.wait_time = shoot_reload_time
	
	# Isolation de la ressource de collision par instance pour éviter d'impacter les autres tours
	var detection_area = get_node_or_null("EnemyDetectionArea")
	if detection_area:
		var col = detection_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if col and col.shape:
			col.shape = col.shape.duplicate()
	
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
	return "Standard defensive tower."


# --- Système d'Améliorations (Upgrades) ---

func get_upgrade_level(upgrade_id: String) -> int:
	return upgrade_levels.get(upgrade_id, 0)


func get_upgrade_cost(upgrade_id: String) -> int:
	match upgrade_id:
		"damage": return _calc_cost(30, 1.35, "damage")
		"reload_speed": return _calc_cost(35, 1.35, "reload_speed")
		"range": return _calc_cost(25, 1.35, "range")
		"arrow_speed": return _calc_cost(20, 1.30, "arrow_speed")
		"explosion_radius": return _calc_cost(40, 1.35, "explosion_radius")
		"max_targets": return _calc_cost(50, 1.45, "max_targets")
		"slow_power": return _calc_cost(45, 1.35, "slow_power")
		"slow_duration": return _calc_cost(35, 1.30, "slow_duration")
		"poison_damage": return _calc_cost(40, 1.35, "poison_damage")
		"poison_duration": return _calc_cost(35, 1.30, "poison_duration")
		"max_bounces": return _calc_cost(55, 1.45, "max_bounces")
		"bounce_range": return _calc_cost(35, 1.35, "bounce_range")
		_:
			for upg in get_available_upgrades():
				if upg["id"] == upgrade_id:
					return upg["cost"]
	return 0


func can_upgrade(upgrade_id: String) -> bool:
	return GoldManager.gold >= get_upgrade_cost(upgrade_id)


func upgrade(upgrade_id: String) -> bool:
	var cost = get_upgrade_cost(upgrade_id)
	if cost <= 0:
		return false
		
	if not GoldManager.spend_gold(cost):
		return false
	
	# Augmentation du niveau d'amélioration propre à cette instance
	upgrade_levels[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	
	# Application des effets sur les statistiques
	_apply_upgrade(upgrade_id)
	
	# Effet de punch visuel sur la tour améliorée
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(self, "scale", Vector2(1.18, 1.18), 0.08)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
	
	SoundManager.play_tower_upgraded(global_position)
	GameEvents.tower_upgraded.emit(self)
	return true


func _apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"damage":
			if "damage" in self:
				set("damage", get("damage") * 1.2)
			elif "base_damage" in self:
				set("base_damage", get("base_damage") * 1.2)
		"reload_speed":
			shoot_reload_time = maxf(0.05, shoot_reload_time * 0.9)
			if reload_timer:
				reload_timer.wait_time = shoot_reload_time
				if reload_timer.time_left > shoot_reload_time:
					reload_timer.start(shoot_reload_time)
		"range":
			var col = get_node_or_null("EnemyDetectionArea/CollisionShape2D") as CollisionShape2D
			if col and col.shape is CircleShape2D:
				(col.shape as CircleShape2D).radius *= 1.15
			if range_indicator:
				range_indicator._update_dimensions()
		_:
			_apply_custom_upgrade(upgrade_id)


func _apply_custom_upgrade(_upgrade_id: String) -> void:
	pass


func get_available_upgrades() -> Array[Dictionary]:
	var upgrades: Array[Dictionary] = []
	
	# 1. Damage (+20%)
	var dmg = get_damage_value()
	var next_dmg = dmg * 1.1
	upgrades.append({
		"id": "damage",
		"name": "Damage",
		"level": get_upgrade_level("damage"),
		"cost": _calc_cost(50, 1.8, "damage"),
		"current_text": _format_num(dmg),
		"next_text": "+20% (" + _format_num(next_dmg) + ")",
	})
	
	# 2. Reload Speed (-10% reload time)
	var r_time = get_reload_time()
	var next_r_time = maxf(0.05, r_time * 0.95)
	var cur_spd = get_attack_speed()
	var next_spd = 1.0 / next_r_time
	upgrades.append({
		"id": "reload_speed",
		"name": "Reload Speed",
		"level": get_upgrade_level("reload_speed"),
		"cost": _calc_cost(45, 1.8, "reload_speed"),
		"current_text": "%0.2fs (%0.1f/s)" % [r_time, cur_spd],
		"next_text": "-10%% (%0.2fs)" % next_r_time,
	})
	
	# 3. Range (+15%)
	var rng = get_detection_range()
	var next_rng = rng * 1.05
	upgrades.append({
		"id": "range",
		"name": "Range",
		"level": get_upgrade_level("range"),
		"cost": _calc_cost(35, 1.35, "range"),
		"current_text": "%d px" % int(rng),
		"next_text": "+15%% (%d px)" % int(next_rng),
	})
	
	# Améliorations personnalisées par sous-classe
	_append_custom_upgrades(upgrades)
	
	return upgrades


func _append_custom_upgrades(_upgrades: Array[Dictionary]) -> void:
	pass


func _calc_cost(base: int, mult: float, id: String) -> int:
	return roundi(base * pow(mult, get_upgrade_level(id)))


func _format_num(val: float) -> String:
	return ("%0.1f" % val) if val != int(val) else ("%d" % int(val))
