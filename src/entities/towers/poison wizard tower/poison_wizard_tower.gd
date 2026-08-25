extends Tower
class_name PoisonWizardTower

@export var projectile: PackedScene
@export var damage: float = 1.0
@export var speed: float = 125.0

@export_group("Poison Settings")
## Ratio/pourcentage des dégâts de base de la tour appliqués à chaque tick de poison (ex: 0.5 = 50% des dégâts de base)
@export_range(0.05, 2.0, 0.05) var poison_damage_ratio: float = 0.5
## Durée totale du poison en secondes
@export var poison_duration: float = 3.0
## Intervalle entre chaque tick de dégâts de poison en secondes
@export var poison_tick_interval: float = 0.5

@onready var weapon: Sprite2D = $Visuals/Weapon
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var muzzle: Marker2D = $Visuals/Weapon/Muzzle


func _setup_upgrade_costs() -> void:
	damage_upgrade_base_cost = 180
	damage_upgrade_cost_mult = 1.35
	reload_upgrade_base_cost = 180
	reload_upgrade_cost_mult = 1.35
	range_upgrade_base_cost = 140
	range_upgrade_cost_mult = 1.30


func _physics_process(_delta: float) -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	
	if enemies.size() > 0:
		weapon.look_at(enemies[0].global_position)


func _shoot() -> void:
	if not projectile or enemies.is_empty():
		return
	
	var instance: PoisonBall = projectile.instantiate() as PoisonBall
	if not instance:
		return
	
	instance.damage = damage
	instance.speed = speed
	instance.poison_damage = damage * poison_damage_ratio
	instance.poison_duration = poison_duration
	instance.poison_tick_interval = poison_tick_interval
	instance.source_tower = self
	var cur_range = get_detection_range()
	instance.lifetime = maxf(2.0, (cur_range * 1.3) / maxf(1.0, speed))
	
	var projectile_node: Node2D = get_tree().current_scene.get_node_or_null("Projectiles")
	if projectile_node:
		projectile_node.add_child(instance)
	else:
		get_tree().current_scene.add_child(instance)
	
	instance.shoot(muzzle.global_position, weapon.rotation)
	SoundManager.play_shoot("poison_wizard", muzzle.global_position)


func _on_reload_timer_timeout() -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	
	if enemies.size() > 0 and projectile:
		if animation_player and animation_player.has_animation("shoot"):
			animation_player.play("shoot")
		_shoot()


func get_special_description() -> String:
	var p_dmg = damage * poison_damage_ratio
	return "Poison : %0.1f dmg/%0.1fs (%0.1fs)" % [p_dmg, poison_tick_interval, poison_duration]


func _append_custom_upgrades(upgrades: Array[Dictionary]) -> void:
	var cur_pdmg = damage * poison_damage_ratio
	var next_pdmg = damage * (poison_damage_ratio * 1.25)
	upgrades.append({
		"id": "poison_damage",
		"name": "Poison Damage",
		"level": get_upgrade_level("poison_damage"),
		"cost": _calc_cost(160, 1.35, "poison_damage"),
		"current_text": "%0.1f /tick" % cur_pdmg,
		"next_text": "%0.1f /tick (+25%%)" % next_pdmg,
	})
	
	var next_dur = poison_duration * 1.2
	upgrades.append({
		"id": "poison_duration",
		"name": "Poison Duration",
		"level": get_upgrade_level("poison_duration"),
		"cost": _calc_cost(140, 1.30, "poison_duration"),
		"current_text": "%0.1fs" % poison_duration,
		"next_text": "%0.1fs (+20%%)" % next_dur,
	})


func _apply_custom_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"poison_damage":
			poison_damage_ratio *= 1.25
		"poison_duration":
			poison_duration *= 1.2
