extends Area2D
class_name Enemy

@export var stats: EnemyStats
@export var hit_particles_scene: PackedScene = preload("uid://dtr5lw5ocrg3p")
@export var death_particles_scene: PackedScene = preload("uid://d4fjkvjerbdpm")

@export_group("Animation Settings")
## Facteur d'influence de l'augmentation de vitesse sur l'animation (ex: 0.35 = l'animation n'accélère que de 35% de la hausse de vitesse)
@export var anim_speed_influence: float = 0.35
## Plafond maximal de vitesse d'animation
@export var max_anim_speed_scale: float = 1.75

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var hit_flash_anim_player: AnimationPlayer = get_node_or_null("HitFlashAnimPlayer")
@onready var sprite: Sprite2D = get_node_or_null("Visuals/Sprite2D")
@onready var attack_timer: Timer = $AttackTimer

var path_follow: PathFollow2D
var cur_hp: float
var is_attacking_castle: bool = false
var is_dead: bool = false
var base_speed: float = 0.0
var difficulty_factor: float = 1.0

# Hitstop
var hitstop_frames: int = 0
var hitstop_amount: int = 1

# Ralentissement (Slow / Freeze)
var slow_multiplier: float = 1.0
var slow_time_remaining: float = 0.0

# Poison (DoT)
var poison_damage_per_tick: float = 0.0
var poison_time_remaining: float = 0.0
var poison_tick_interval: float = 0.5
var poison_tick_timer: float = 0.0

# Transitions visuelles
var status_tween: Tween


func _ready() -> void:
	add_to_group("enemy")
	if stats:
		cur_hp = stats.hp
		attack_timer.wait_time = stats.attack_speed
		if base_speed <= 0.0:
			base_speed = stats.speed
	update_animation_speed()
	update_debug_label()


func setup(new_path_follow: PathFollow2D) -> void:
	path_follow = new_path_follow
	path_follow.loop = false
	path_follow.rotates = false


func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Hitstop
	if hitstop_frames > 0:
		hitstop_frames -= 1
		if hitstop_frames <= 0:
			stop_hitstop()
		return
	
	# Gestion du ralentissement
	if slow_time_remaining > 0.0:
		slow_time_remaining -= delta
		if slow_time_remaining <= 0.0:
			_remove_slow()
	
	# Gestion du poison (DoT)
	if poison_time_remaining > 0.0 and not is_dead:
		poison_time_remaining -= delta
		poison_tick_timer -= delta
		if poison_tick_timer <= 0.0:
			poison_tick_timer = poison_tick_interval
			take_damage(poison_damage_per_tick, "poison")
			
		if is_dead or poison_time_remaining <= 0.0:
			_remove_poison()
	
	if is_dead:
		return
	
	if is_instance_valid(path_follow) and stats:
		if not is_attacking_castle:
			path_follow.progress += get_current_speed() * delta
			global_position = path_follow.global_position
			
			if path_follow.progress_ratio >= 0.99:
				reached_castle()


func reached_castle() -> void:
	is_attacking_castle = true
	attack_timer.timeout.connect(_on_attack_tick)


func _on_attack_tick() -> void:
	var castle: Castle = get_tree().get_first_node_in_group("castle")
	if is_instance_valid(castle):
		if animation_player and animation_player.has_animation("attack"):
			animation_player.play("attack")
		castle.take_damage(stats.attack_damage)
	else:
		if attack_timer:
			attack_timer.stop()


func take_damage(amount: float, damage_type: String = "physical") -> void:
	if is_dead:
		return
		
	var resist: float = 0.0
	if stats:
		match damage_type:
			"physical": resist = stats.physical_resist
			"fire": resist = stats.fire_resist
			"ice": resist = stats.ice_resist
			"poison": resist = stats.poison_resist
			"lightning": resist = stats.lightning_resist
	
	resist = minf(resist, 1.0)
	var final_damage: float = maxf(0.0, amount * (1.0 - resist))
	
	cur_hp -= final_damage
	_damage_effects()
	spawn_hit_particles()
	update_debug_label()
	
	if cur_hp <= 0 and not is_dead:
		die()


func apply_scale_difficulty(factor: float) -> void:
	if stats:
		if base_speed <= 0.0:
			base_speed = stats.speed
		stats = stats.duplicate()
		stats.hp = clampf(stats.hp * factor, stats.hp, stats.max_hp)
		stats.speed = stats.speed * (1.0 + (factor - 1.0) * 0.2)
		cur_hp = stats.hp
		difficulty_factor = factor
		update_animation_speed()
		update_debug_label()


func get_current_speed() -> float:
	if not stats:
		return 0.0
	return stats.speed * slow_multiplier


func apply_slow(factor: float, duration: float) -> void:
	if is_dead:
		return
	
	# Immunité au gel si résistance glace >= 1.0 (100%)
	if stats and stats.ice_resist >= 1.0:
		return
	
	# Conserver le ralentissement le plus fort et rafraîchir la durée
	slow_multiplier = minf(slow_multiplier, clampf(factor, 0.05, 1.0))
	slow_time_remaining = maxf(slow_time_remaining, duration)
	
	_update_status_visuals()
	update_animation_speed()
	update_debug_label()


func _remove_slow() -> void:
	slow_time_remaining = 0.0
	slow_multiplier = 1.0
	_update_status_visuals()
	update_animation_speed()
	update_debug_label()


func apply_poison(damage_per_tick: float, duration: float, tick_interval: float = 0.5) -> void:
	if is_dead:
		return
	
	# Immunité au poison si résistance poison >= 1.0 (100%)
	if stats and stats.poison_resist >= 1.0:
		return
	
	poison_damage_per_tick = maxf(poison_damage_per_tick, damage_per_tick)
	poison_time_remaining = maxf(poison_time_remaining, duration)
	poison_tick_interval = maxf(0.1, tick_interval)
	if poison_tick_timer <= 0.0 or poison_tick_timer > poison_tick_interval:
		poison_tick_timer = poison_tick_interval
	
	_update_status_visuals()


func _remove_poison() -> void:
	poison_time_remaining = 0.0
	poison_damage_per_tick = 0.0
	poison_tick_timer = 0.0
	_update_status_visuals()


func _update_status_visuals() -> void:
	if is_dead or not is_instance_valid(sprite):
		return
	
	if status_tween and status_tween.is_valid():
		status_tween.kill()
	
	var is_slowed: bool = slow_time_remaining > 0.0
	var is_poisoned: bool = poison_time_remaining > 0.0
	
	var target_color: Color = Color.WHITE
	if is_slowed and is_poisoned:
		target_color = Color(0.55, 0.95, 0.85, 1.0)
	elif is_slowed:
		target_color = Color(0.55, 0.8, 1.0, 1.0)
	elif is_poisoned:
		target_color = Color(0.65, 1.0, 0.6, 1.0)
	
	if target_color == Color.WHITE:
		status_tween = create_tween()
		status_tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	else:
		sprite.modulate = target_color


func update_animation_speed() -> void:
	if is_instance_valid(animation_player) and base_speed > 0.0 and stats:
		var speed_ratio: float = get_current_speed() / base_speed
		var calculated_anim_speed: float = 1.0 + (speed_ratio - 1.0) * anim_speed_influence
		animation_player.speed_scale = clampf(calculated_anim_speed, 0.1, max_anim_speed_scale)


func update_debug_label() -> void:
	var label: Label = get_node_or_null("Label")
	if label and stats:
		label.text = "speed: %.1f\nmax_hp: %.1f\nhp: %.1f\ncur_hp: %.1f" % [
			get_current_speed(),
			stats.max_hp,
			stats.hp,
			cur_hp
		]


func spawn_hit_particles() -> void:
	if hit_particles_scene:
		var instance: GPUParticles2D = hit_particles_scene.instantiate()
		get_tree().current_scene.add_child(instance)
		instance.global_position = global_position


func spawn_death_particles() -> void:
	if death_particles_scene:
		var instance: GPUParticles2D = death_particles_scene.instantiate()
		get_tree().current_scene.add_child(instance)
		instance.global_position = global_position


func start_hitstop() -> void:
	if is_dead:
		return
	if is_instance_valid(animation_player):
		animation_player.pause()
	if is_instance_valid(hit_flash_anim_player):
		hit_flash_anim_player.pause()
	hitstop_frames = hitstop_amount


func stop_hitstop() -> void:
	if is_instance_valid(animation_player):
		animation_player.play()
	if is_instance_valid(hit_flash_anim_player):
		hit_flash_anim_player.play()
	hitstop_frames = 0


func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	hitstop_frames = 0
	slow_time_remaining = 0.0
	slow_multiplier = 1.0
	poison_time_remaining = 0.0
	poison_damage_per_tick = 0.0
	poison_tick_timer = 0.0
	
	if status_tween and status_tween.is_valid():
		status_tween.kill()
	if is_instance_valid(hit_flash_anim_player):
		hit_flash_anim_player.stop()
	
	if attack_timer:
		attack_timer.queue_free()
	
	GoldManager.add_gold(stats.gold_reward)
	spawn_death_particles()
	if is_instance_valid(path_follow):
		path_follow.queue_free.call_deferred()


func _damage_effects() -> void:
	if is_dead:
		return
	if is_instance_valid(hit_flash_anim_player):
		hit_flash_anim_player.play("hit_flash")


func _on_area_entered(projectile: Area2D) -> void:
	if projectile.is_in_group("projectile"):
		var dmg_type: String = projectile.damage_type if "damage_type" in projectile else "physical"
		if projectile.has_method("try_hit"):
			if projectile.try_hit(self):
				take_damage(projectile.damage, dmg_type)
		else:
			take_damage(projectile.damage, dmg_type)
			if projectile.has_method("on_hit_target"):
				projectile.on_hit_target(self)
			projectile.queue_free()
