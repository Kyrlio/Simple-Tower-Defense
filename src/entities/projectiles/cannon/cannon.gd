extends Projectile
class_name Cannon

@export var explosion_effect: PackedScene
@export var explosion_effect2: PackedScene

@export_group("Physics")
## Hauteur maximale de l'arche de la trajectoire parabolique (plus la valeur est élevée, plus la cloche est haute)
@export var arc_height: float = 120.0
## Temps total en secondes pour atteindre la cible (ralentit ou accélère le vol du boulet)
@export var flight_duration: float = 1.2
## Le filtre de collision d'ennemis (Layer d'ennemis) pour la détection de zone à l'impact
@export_flags_2d_physics var enemy_collision_mask: int = 3


@export_group("Shadow")
@export var min_shadow_scale: float = 0.5
@export var max_shadow_scale: float = 1.0
@export var shadow_texture: Texture2D = preload("res://assets/Shadow.png")

@onready var explosion_area: Area2D = $ExplosionArea
@onready var shadow_sprite: Sprite2D = get_node_or_null("Shadow")
@onready var trail_particles: GPUParticles2D = $TrailParticles

var start_position: Vector2 = Vector2.ZERO
var target_node: Node2D = null
var target_last_position: Vector2 = Vector2.ZERO
var explosion_radius: float = 20.0
var time_elapsed: float = 0.0
var previous_position: Vector2 = Vector2.ZERO
var is_launched: bool = false

# Pixel trail
var total_flight_time: float = 1.0
var initial_velocity: Vector2 = Vector2.ZERO
var gravity_accel: float = 0.0


func _ready() -> void:
	monitorable = false
	monitoring = false
	_update_explosion_radius_from_shape()
	
	if not shadow_sprite and shadow_texture:
		shadow_sprite = Sprite2D.new()
		shadow_sprite.name = "Shadow"
		shadow_sprite.texture = shadow_texture
		shadow_sprite.modulate = Color(1, 1, 1, 0.6)
		add_child(shadow_sprite)
		
	if shadow_sprite:
		shadow_sprite.top_level = true


func _update_explosion_radius_from_shape() -> void:
	if explosion_area and is_instance_valid(explosion_area):
		var collision_shape: CollisionShape2D = explosion_area.get_node_or_null("CollisionShape2D")
		if collision_shape and collision_shape.shape is CircleShape2D:
			explosion_radius = (collision_shape.shape as CircleShape2D).radius


func launch(from_pos: Vector2, target_or_pos: Variant, dmg_amount: float = 25.0, override_radius: float = -1.0) -> void:
	global_position = from_pos
	start_position = from_pos
	damage = dmg_amount
	time_elapsed = 0.0
	previous_position = from_pos
	monitoring = false
	monitorable = false
	
	_update_explosion_radius_from_shape()
	if override_radius > 0.0:
		explosion_radius = override_radius
		
	$Sprite2D.visible = true
	var col = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.set_deferred("disabled", true)
		
	if shadow_sprite and is_instance_valid(shadow_sprite):
		shadow_sprite.visible = true
		shadow_sprite.global_position = from_pos
		shadow_sprite.scale = Vector2(min_shadow_scale, min_shadow_scale * 0.5)
	
	if trail_particles:
		if not Data.deactivate_particles:
			trail_particles.emitting = true
			trail_particles.restart()
		else:
			trail_particles.emitting = false
		
	_reset_visual_effects()
	
	if target_or_pos is Node2D and is_instance_valid(target_or_pos):
		target_last_position = target_or_pos.global_position
	elif target_or_pos is Vector2:
		target_last_position = target_or_pos
	else:
		target_last_position = from_pos
	
	is_launched = true


func _physics_process(delta: float) -> void:
	if not is_launched:
		return
		
	time_elapsed += delta
	var t: float = clampf(time_elapsed / flight_duration, 0.0, 1.0)
	
	# Trajectoire sur le plan (sol)
	var current_ground_pos: Vector2 = start_position.lerp(target_last_position, t)
	
	# Hauteur parabolique
	var arc_offset: float = 4.0 * arc_height * t * (1.0 - t)
	var new_pos: Vector2 = current_ground_pos + Vector2(0, -arc_offset)
	
	# Gestion de l'ombre au sol : elle s'agrandit et s'assombrit au fur et à mesure que la boule approche du sol
	if shadow_sprite and is_instance_valid(shadow_sprite):
		shadow_sprite.global_position = current_ground_pos
		var normalized_height: float = clampf(arc_offset / arc_height, 0.0, 1.0)
		var current_scale: float = lerpf(max_shadow_scale, min_shadow_scale, normalized_height)
		shadow_sprite.scale = Vector2(current_scale, current_scale * 0.5)
		shadow_sprite.modulate.a = lerpf(0.8, 0.25, normalized_height)
	
	# Orientation du boulet selon la direction du déplacement
	var move_vec: Vector2 = new_pos - previous_position
	if move_vec.length_squared() > 0.001:
		rotation = move_vec.angle()
		
	previous_position = new_pos
	global_position = new_pos
	
	if t >= 1.0:
		explode()


func try_hit(_target: Node2D) -> bool:
	# Le boulet de canon survole le champ de bataille et n'explose qu'à destination
	return false


func reactivate() -> void:
	super.reactivate()
	monitoring = false
	monitorable = false
	is_launched = false
	time_elapsed = 0.0
	$Sprite2D.visible = true
	var col = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.set_deferred("disabled", true)
	if shadow_sprite and is_instance_valid(shadow_sprite):
		shadow_sprite.visible = false
	if trail_particles:
		trail_particles.emitting = false
	_reset_visual_effects()


func deactivate() -> void:
	super.deactivate()
	is_launched = false
	if shadow_sprite and is_instance_valid(shadow_sprite):
		shadow_sprite.visible = false
	if trail_particles:
		trail_particles.emitting = false
	_reset_visual_effects()


func explode() -> void:
	is_launched = false
	global_position = target_last_position
	
	# 1. Masquer le boulet et l'ombre immédiatement
	$Sprite2D.visible = false
	if shadow_sprite and is_instance_valid(shadow_sprite):
		shadow_sprite.visible = false
	if trail_particles:
		trail_particles.emitting = false
	_reset_visual_effects()
	
	# 2. Spawns des explosions et application des dégâts (uniquement si les particules sont activées)
	var scene_root = get_tree().current_scene
	if not Data.deactivate_particles and scene_root:
		if explosion_effect:
			var effect_instance = explosion_effect.instantiate()
			if "global_position" in effect_instance:
				effect_instance.global_position = target_last_position
			scene_root.add_child(effect_instance)
			if effect_instance is GPUParticles2D:
				effect_instance.restart()
				effect_instance.emitting = true
		
		if explosion_effect2:
			var effect_instance = explosion_effect2.instantiate()
			if "global_position" in effect_instance:
				effect_instance.global_position = target_last_position
			scene_root.add_child(effect_instance)
			if effect_instance is GPUParticles2D:
				effect_instance.restart()
				effect_instance.emitting = true
		
	SoundManager.play_explosion(target_last_position)
	_apply_aoe_damage()
	release()




func _apply_aoe_damage() -> void:
	var damaged_targets: Dictionary = {}
	
	# Requête spatiale directe et ultra-rapide via le moteur physique (DirectSpaceState2D)
	var space_state = get_world_2d().direct_space_state
	if space_state:
		var shape_query := PhysicsShapeQueryParameters2D.new()
		var circle := CircleShape2D.new()
		circle.radius = explosion_radius
		shape_query.shape = circle
		shape_query.transform = Transform2D(0.0, target_last_position)
		shape_query.collision_mask = enemy_collision_mask
		shape_query.collide_with_areas = true
		shape_query.collide_with_bodies = false
		
		var results = space_state.intersect_shape(shape_query, 128)
		for result in results:
			var collider = result.get("collider")
			if is_instance_valid(collider) and not damaged_targets.has(collider):
				damaged_targets[collider] = true
				if collider.has_method("take_damage"):
					collider.take_damage(damage, "physical")
				elif collider.get_parent() and collider.get_parent().has_method("take_damage"):
					collider.get_parent().take_damage(damage, "physical")
	elif explosion_area and is_instance_valid(explosion_area):
		explosion_area.global_position = target_last_position
		for target in explosion_area.get_overlapping_areas():
			if is_instance_valid(target) and not damaged_targets.has(target):
				damaged_targets[target] = true
				if target.has_method("take_damage"):
					target.take_damage(damage, "physical")
				elif target.get_parent() and target.get_parent().has_method("take_damage"):
					target.get_parent().take_damage(damage, "physical")

