extends Area2D
class_name Enemy

@export var stats: EnemyStats
@export var hit_particles_scene: PackedScene = preload("uid://dtr5lw5ocrg3p")
@export var death_particles_scene: PackedScene = preload("uid://d4fjkvjerbdpm")

@export_group("Reward Settings")
## Facteur d'influence de la difficulté sur le gain d'or à la mort (ex: 0.08 = +8% du facteur de diff en or)
@export var gold_scale_influence: float = 0.15

@export_group("Speed Settings")
## Plafond maximal absolu de vitesse de déplacement pour l'ennemi
@export var max_speed: float = 80.0

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
var hitstop_amount: int = 2

# Ralentissement (Slow / Freeze)
var slow_multiplier: float = 1.0
var slow_time_remaining: float = 0.0
var slow_sources: Dictionary = {} # source_id (int) -> { "factor": float, "duration": float, "time_left": float }

# Poison (DoT)
var poison_damage_per_tick: float = 0.0
var poison_time_remaining: float = 0.0
var poison_tick_interval: float = 0.5
var poison_tick_timer: float = 0.0
var poison_sources: Dictionary = {} # source_id (int) -> { "damage_per_tick": float, "duration": float, "time_left": float, "tick_interval": float }

# Particle Throttling (Anti-lag late game)
static var _last_hit_fx_frame: int = -1
static var _hit_fx_count_this_frame: int = 0
const MAX_HIT_FX_PER_FRAME: int = 3

static var _last_death_fx_frame: int = -1
static var _death_fx_count_this_frame: int = 0
const MAX_DEATH_FX_PER_FRAME: int = 3

# Transitions visuelles
var status_tween: Tween

# Culling hors écran (Dirty Rectangles / Performance)
var is_on_screen: bool = true
var screen_notifier: VisibleOnScreenNotifier2D = null


func _ready() -> void:
	add_to_group("enemy")
	if stats:
		cur_hp = stats.hp
		attack_timer.wait_time = stats.attack_speed
		if base_speed <= 0.0:
			base_speed = minf(stats.speed, max_speed)
	
	_setup_screen_culling()
	update_animation_speed()
	
	Data.enemy_debug_labels_toggled.connect(_on_enemy_debug_labels_toggled)
	_apply_debug_label_visibility(Data.show_enemy_debug_labels)
	update_debug_label()


func _setup_screen_culling() -> void:
	screen_notifier = get_node_or_null("VisibleOnScreenNotifier2D")
	if not screen_notifier:
		screen_notifier = VisibleOnScreenNotifier2D.new()
		screen_notifier.name = "VisibleOnScreenNotifier2D"
		screen_notifier.rect = Rect2(-32, -32, 64, 64)
		add_child(screen_notifier)
		
	screen_notifier.screen_entered.connect(_on_screen_entered)
	screen_notifier.screen_exited.connect(_on_screen_exited)
	# Par défaut au spawn, on garde l'ennemi visible et actif
	is_on_screen = true


func _on_screen_entered() -> void:
	is_on_screen = true
	if is_instance_valid(sprite):
		sprite.visible = true
	if is_instance_valid(animation_player):
		animation_player.active = true
	_update_status_visuals()
	update_animation_speed()
	update_debug_label()


func _on_screen_exited() -> void:
	is_on_screen = false
	_apply_off_screen_state()


func _apply_off_screen_state() -> void:
	if is_instance_valid(sprite):
		sprite.visible = false
	if is_instance_valid(animation_player):
		animation_player.active = false


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
	if not slow_sources.is_empty():
		var has_expired_slow: bool = false
		var max_time: float = 0.0
		for src_id in slow_sources:
			var data: Dictionary = slow_sources[src_id]
			data["time_left"] -= delta
			if data["time_left"] <= 0.0:
				has_expired_slow = true
			else:
				max_time = maxf(max_time, data["time_left"])
		
		if has_expired_slow:
			var to_remove: Array = []
			for src_id in slow_sources:
				if slow_sources[src_id]["time_left"] <= 0.0:
					to_remove.append(src_id)
			for src_id in to_remove:
				slow_sources.erase(src_id)
			_recalculate_slow()
			_update_status_visuals()
			update_animation_speed()
			update_debug_label()
		else:
			slow_time_remaining = max_time
	elif slow_time_remaining > 0.0:
		_remove_slow()
	
	# Gestion du poison (DoT)
	if not poison_sources.is_empty() and not is_dead:
		var has_expired_poison: bool = false
		var max_time: float = 0.0
		for src_id in poison_sources:
			var data: Dictionary = poison_sources[src_id]
			data["time_left"] -= delta
			if data["time_left"] <= 0.0:
				has_expired_poison = true
			else:
				max_time = maxf(max_time, data["time_left"])
		
		if has_expired_poison:
			var to_remove: Array = []
			for src_id in poison_sources:
				if poison_sources[src_id]["time_left"] <= 0.0:
					to_remove.append(src_id)
			for src_id in to_remove:
				poison_sources.erase(src_id)
			_recalculate_poison()
			_update_status_visuals()
		
		if not poison_sources.is_empty():
			poison_time_remaining = max_time
			poison_tick_timer -= delta
			if poison_tick_timer <= 0.0:
				poison_tick_timer = poison_tick_interval
				take_damage(poison_damage_per_tick, "poison")
				
		if is_dead or poison_sources.is_empty():
			_remove_poison()
	elif poison_time_remaining > 0.0:
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
	
	if final_damage > 0.0:
		SoundManager.play_hit(global_position)
	
	if cur_hp <= 0 and not is_dead:
		die()


func apply_scale_difficulty(factor: float) -> void:
	if stats:
		if base_speed <= 0.0:
			base_speed = minf(stats.speed, max_speed)
		stats = stats.duplicate()
		stats.hp = maxf(1.0, stats.hp * factor)
		stats.speed = minf(stats.speed * (1.0 + (factor - 1.0) * 0.2), max_speed)
		var influence: float = Data.get_wave_setting("gold_scale_influence", gold_scale_influence) if Data else gold_scale_influence
		stats.gold_reward = maxi(1, roundi(stats.gold_reward * (1.0 + (factor - 1.0) * influence)))
		cur_hp = stats.hp
		difficulty_factor = factor
		update_animation_speed()
		update_debug_label()


func get_current_speed() -> float:
	if not stats:
		return 0.0
	return minf(stats.speed, max_speed) * slow_multiplier


func apply_slow(factor: float, duration: float, source: Object = null) -> void:
	if is_dead:
		return
	
	# Immunité au gel si résistance glace >= 1.0 (100%)
	if stats and stats.ice_resist >= 1.0:
		return
	
	var source_id: int = source.get_instance_id() if is_instance_valid(source) else 0
	var clamped_factor: float = clampf(factor, 0.05, 1.0)
	
	slow_sources[source_id] = {
		"factor": clamped_factor,
		"duration": duration,
		"time_left": duration
	}
	
	_recalculate_slow()
	_update_status_visuals()
	update_animation_speed()
	update_debug_label()


func _recalculate_slow() -> void:
	if slow_sources.is_empty():
		slow_time_remaining = 0.0
		slow_multiplier = 1.0
		return
	
	var reductions: Array[float] = []
	var max_time: float = 0.0
	for src_id in slow_sources:
		var s_data: Dictionary = slow_sources[src_id]
		var red: float = 1.0 - s_data["factor"]
		reductions.append(red)
		max_time = maxf(max_time, s_data["time_left"])
	
	reductions.sort_custom(func(a, b): return a > b)
	
	# Ralentissement principal : 100% de la réduction la plus forte
	var total_reduction: float = reductions[0]
	
	# Ralentissements cumulés : +25% de la valeur de base de chaque autre tour
	for i in range(1, reductions.size()):
		total_reduction += reductions[i] * 0.25
	
	slow_time_remaining = max_time
	# Plancher de sécurité à 0.1 (10% de vitesse) pour éviter que les ennemis s'arrêtent totalement (speed = 0)
	slow_multiplier = clampf(1.0 - total_reduction, 0.1, 1.0)


func _remove_slow() -> void:
	slow_sources.clear()
	slow_time_remaining = 0.0
	slow_multiplier = 1.0
	_update_status_visuals()
	update_animation_speed()
	update_debug_label()


func apply_poison(damage_per_tick: float, duration: float, tick_interval: float = 0.5, source: Object = null) -> void:
	if is_dead:
		return
	
	# Immunité au poison si résistance poison >= 1.0 (100%)
	if stats and stats.poison_resist >= 1.0:
		return
	
	var source_id: int = source.get_instance_id() if is_instance_valid(source) else 0
	
	poison_sources[source_id] = {
		"damage_per_tick": damage_per_tick,
		"duration": duration,
		"time_left": duration,
		"tick_interval": maxf(0.1, tick_interval)
	}
	
	_recalculate_poison()
	
	if poison_tick_timer <= 0.0 or poison_tick_timer > poison_tick_interval:
		poison_tick_timer = poison_tick_interval
	
	_update_status_visuals()


func _recalculate_poison() -> void:
	if poison_sources.is_empty():
		poison_damage_per_tick = 0.0
		poison_time_remaining = 0.0
		poison_tick_interval = 0.5
		return
	
	var damages: Array[float] = []
	var max_time: float = 0.0
	var min_interval: float = 0.5
	for src_id in poison_sources:
		var p_data: Dictionary = poison_sources[src_id]
		damages.append(p_data["damage_per_tick"])
		max_time = maxf(max_time, p_data["time_left"])
		min_interval = minf(min_interval, p_data["tick_interval"])
	
	damages.sort_custom(func(a, b): return a > b)
	
	# Dégâts de poison principaux : 100% de la source la plus puissante
	var total_dmg: float = damages[0]
	
	# Dégâts cumulés : +25% des dégâts de base de chaque autre tour
	for i in range(1, damages.size()):
		total_dmg += damages[i] * 0.25
	
	poison_damage_per_tick = total_dmg
	poison_time_remaining = max_time
	poison_tick_interval = maxf(0.1, min_interval)


func _remove_poison() -> void:
	poison_sources.clear()
	poison_time_remaining = 0.0
	poison_damage_per_tick = 0.0
	poison_tick_timer = 0.0
	_update_status_visuals()


func _update_status_visuals() -> void:
	if is_dead or not is_instance_valid(sprite) or not is_on_screen:
		return
	
	if status_tween and status_tween.is_valid():
		status_tween.kill()
	
	var is_slowed: bool = not slow_sources.is_empty() and slow_time_remaining > 0.0
	var is_poisoned: bool = not poison_sources.is_empty() and poison_time_remaining > 0.0
	
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


func _on_enemy_debug_labels_toggled(show_labels: bool) -> void:
	_apply_debug_label_visibility(show_labels)


func _apply_debug_label_visibility(show_labels: bool) -> void:
	var label: Label = get_node_or_null("Label")
	if label:
		label.visible = show_labels
		if show_labels:
			update_debug_label()


func update_debug_label() -> void:
	if not is_on_screen:
		return
	var label: Label = get_node_or_null("Label")
	if label and label.visible and stats:
		label.text = "speed: %.1f\nhp: %.1f\ncur_hp: %.1f" % [
			get_current_speed(),
			stats.hp,
			cur_hp
		]


func spawn_hit_particles() -> void:
	if Data.deactivate_particles or not is_on_screen:
		return
	var cur_frame := Engine.get_process_frames()
	if _last_hit_fx_frame != cur_frame:
		_last_hit_fx_frame = cur_frame
		_hit_fx_count_this_frame = 0
	if _hit_fx_count_this_frame >= MAX_HIT_FX_PER_FRAME:
		return
	_hit_fx_count_this_frame += 1
	
	if hit_particles_scene and is_inside_tree() and get_tree() and get_tree().current_scene:
		var instance: GPUParticles2D = hit_particles_scene.instantiate()
		instance.global_position = global_position
		get_tree().current_scene.add_child(instance)
		instance.restart()
		instance.emitting = true


func spawn_death_particles() -> void:
	if Data.deactivate_particles or not is_on_screen:
		return
	var cur_frame := Engine.get_process_frames()
	if _last_death_fx_frame != cur_frame:
		_last_death_fx_frame = cur_frame
		_death_fx_count_this_frame = 0
	if _death_fx_count_this_frame >= MAX_DEATH_FX_PER_FRAME:
		return
	_death_fx_count_this_frame += 1
	
	if death_particles_scene and is_inside_tree() and get_tree() and get_tree().current_scene:
		var instance: GPUParticles2D = death_particles_scene.instantiate()
		instance.global_position = global_position
		get_tree().current_scene.add_child(instance)
		instance.restart()
		instance.emitting = true




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
	_remove_slow()
	_remove_poison()
	
	if status_tween and status_tween.is_valid():
		status_tween.kill()
	if is_instance_valid(hit_flash_anim_player):
		hit_flash_anim_player.stop()
	
	if attack_timer:
		attack_timer.queue_free()
	
	SoundManager.play_enemy_death(global_position)
	GoldManager.add_gold(stats.gold_reward)
	spawn_death_particles()
	if is_instance_valid(path_follow):
		path_follow.queue_free.call_deferred()


func _damage_effects() -> void:
	if is_dead or not is_on_screen:
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
			if projectile.has_method("release"):
				projectile.release()
			else:
				projectile.queue_free()
