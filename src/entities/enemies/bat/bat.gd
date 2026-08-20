extends Area2D
class_name Bat

@export var stats: EnemyStats
@export var hit_particles_scene: PackedScene = preload("uid://dtr5lw5ocrg3p")
@export var death_particles_scene: PackedScene = preload("uid://d4fjkvjerbdpm")
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_flash_anim_player: AnimationPlayer = $HitFlashAnimPlayer
@onready var sprite: Sprite2D = $Visuals/Sprite2D

var path_follow: PathFollow2D
var cur_hp: float
var is_attacking_castle: bool = false
var attack_timer: Timer

# Hitstops
var hitstop_frames: int = 0
var hitstop_amount: int = 3


func _ready() -> void:
	if stats:
		cur_hp = stats.hp
	
	update_debug_label()


func setup(new_path_follow: PathFollow2D) -> void:
	path_follow = new_path_follow
	path_follow.loop = false
	path_follow.rotates = false


func _physics_process(delta: float) -> void:
	# Hitstop
	if hitstop_frames > 0:
		hitstop_frames -= 1
		if hitstop_frames <= 0:
			stop_hitstop()
		return
	
	if is_instance_valid(path_follow) and stats:
		if not is_attacking_castle:
			path_follow.progress += stats.speed * delta
			global_position = path_follow.global_position
		
			if path_follow.progress_ratio >= 0.99:
				reached_castle()


func reached_castle() -> void:
	is_attacking_castle = true
	print("Bat a atteint chateau et attaque")
	
	attack_timer = Timer.new()
	attack_timer.wait_time = stats.attack_speed
	attack_timer.autostart = true
	attack_timer.timeout.connect(_on_attack_tick)
	add_child(attack_timer)
	#TODO Juice : animation + sfx


func _on_attack_tick() -> void:
	var castle: Castle = get_tree().get_first_node_in_group("castle")
	if is_instance_valid(castle):
		castle.take_damage(stats.attack_damage)
	else:
		# Castle destroyed
		if attack_timer:
			attack_timer.stop()


func take_damage(amount: float, damage_type: String = "physical") -> void:
	var final_damage: float = amount
	
	match damage_type:
		"physical": final_damage *= (1.0 - stats.physical_resist)
		"ice": final_damage *= (1.0 - stats.ice_resist)
		"poison": final_damage *= (1.0 - stats.poison_resist)
		"lightning": final_damage *= (1.0 - stats.lightning_resist)
	
	cur_hp -= final_damage
	_damage_effects()
	spawn_hit_particles()
	update_debug_label()
	
	if cur_hp <= 0:
		die()


func apply_scale_difficulty(factor: float) -> void:
	if stats:
		stats = stats.duplicate()
		stats.hp = clampf(stats.hp * factor, stats.hp, stats.max_hp)
		#stats.max_hp = max(stats.max_hp, stats.max_hp * factor)
		stats.speed = stats.speed * (1.0 + (factor - 1.0) * 0.2)
		cur_hp = stats.hp
		update_debug_label()


func update_debug_label() -> void:
	$Label.text = "speed: " + str(stats.speed) + "\nmax_hp: " + str(stats.max_hp) \
			+ "\nhp: " + str(stats.hp) + "\ncur_hp: " + str(cur_hp)


func spawn_hit_particles() -> void:
	var instance: GPUParticles2D = hit_particles_scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = global_position


func spawn_death_particles() -> void:
	var instance: GPUParticles2D = death_particles_scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = global_position


func start_hitstop() -> void:
	animation_player.pause()
	hit_flash_anim_player.pause()
	hitstop_frames = hitstop_amount


func stop_hitstop() -> void:
	animation_player.play()
	hit_flash_anim_player.play()
	hitstop_frames = 0


func die() -> void:
	if attack_timer:
		attack_timer.queue_free()
	
	_damage_effects()
	GoldManager.add_gold(stats.gold_reward)
	spawn_death_particles()
	if is_instance_valid(path_follow):
		path_follow.queue_free.call_deferred()


func _damage_effects() -> void:
	hit_flash_anim_player.play("hit_flash")


func _on_area_entered(projectile: Area2D) -> void:
	if projectile.is_in_group("projectile"):
		if projectile.has_method("try_hit"):
			if projectile.try_hit(self):
				take_damage(projectile.damage)
		else:
			take_damage(projectile.damage)
			projectile.queue_free()
