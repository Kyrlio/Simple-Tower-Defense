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
	damage_upgrade_base_cost = 80
	damage_upgrade_cost_mult = 1.35
	reload_upgrade_base_cost = 75
	reload_upgrade_cost_mult = 1.25
	range_upgrade_base_cost = 50
	range_upgrade_cost_mult = 1.30


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if current_target:
		weapon.look_at(current_target.global_position)


func _shoot() -> void:
	if not projectile:
		return
	if not _is_target_valid(current_target):
		_update_current_target()
	if not current_target:
		return
	
	var instance: PoisonBall = ProjectilePool.spawn_projectile(projectile) as PoisonBall
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
	instance.shoot(muzzle.global_position, weapon.rotation)
	SoundManager.play_shoot("poison_wizard", muzzle.global_position)


func _on_reload_timer_timeout() -> void:
	if not _is_target_valid(current_target):
		_update_current_target()
	if current_target and projectile:
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
		"cost": _calc_cost(150, 1.5, "poison_damage"),
		"current_text": "%0.1f /tick" % cur_pdmg,
		"next_text": "%0.1f /tick (+25%%)" % next_pdmg,
	})
	
	var next_dur = poison_duration * 1.2
	upgrades.append({
		"id": "poison_duration",
		"name": "Poison Duration",
		"level": get_upgrade_level("poison_duration"),
		"cost": _calc_cost(160, 1.3, "poison_duration"),
		"current_text": "%0.1fs" % poison_duration,
		"next_text": "%0.1fs (+20%%)" % next_dur,
	})


func _apply_custom_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"poison_damage":
			poison_damage_ratio *= 1.25
		"poison_duration":
			poison_duration *= 1.2
