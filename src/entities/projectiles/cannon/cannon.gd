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
	
	_update_explosion_radius_from_shape()
	if override_radius > 0.0:
		explosion_radius = override_radius
		
	if shadow_sprite and is_instance_valid(shadow_sprite):
		shadow_sprite.visible = true
		shadow_sprite.global_position = from_pos
		shadow_sprite.scale = Vector2(min_shadow_scale, min_shadow_scale * 0.5)
	
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


func explode() -> void:
	is_launched = false
	global_position = target_last_position
	
	# 1. Masquer le boulet et l'ombre immédiatement
	$Sprite2D.visible = false
	if $CollisionShape2D:
		$CollisionShape2D.set_deferred("disabled", true)
	if shadow_sprite and is_instance_valid(shadow_sprite):
		shadow_sprite.queue_free()
	
	# 2. Stopper l'émission (les particules existantes continuent leur vie)
	if trail_particles and is_instance_valid(trail_particles):
		trail_particles.emitting = false
	
	# 3. Spawns des explosions et application des dégâts
	if explosion_effect:
		var effect_instance = explosion_effect.instantiate()
		get_tree().current_scene.add_child(effect_instance)
		if "global_position" in effect_instance:
			effect_instance.global_position = target_last_position
	
	if explosion_effect2:
		var effect_instance = explosion_effect2.instantiate()
		get_tree().current_scene.add_child(effect_instance)
		if "global_position" in effect_instance:
			effect_instance.global_position = target_last_position
		
	_apply_aoe_damage()
	
	# 4. Attendre que les dernières particules disparaissent avant de libérer le nœud
	var wait_time: float = trail_particles.lifetime if trail_particles else 0.0
	get_tree().create_timer(wait_time + 0.1).timeout.connect(queue_free)


func _apply_aoe_damage() -> void:
	var damaged_targets: Array[Node2D] = []
	
	if explosion_area and is_instance_valid(explosion_area):
		explosion_area.global_position = target_last_position
		
		var areas: Array[Area2D] = explosion_area.get_overlapping_areas()
		var bodies: Array[Node2D] = explosion_area.get_overlapping_bodies()
		
		for target in (areas + bodies):
			if is_instance_valid(target) and target not in damaged_targets:
				damaged_targets.append(target)
				if target.has_method("take_damage"):
					target.take_damage(damage, "physical")
				elif target.get_parent() and target.get_parent().has_method("take_damage"):
					target.get_parent().take_damage(damage, "physical")
					
		var collision_shape: CollisionShape2D = explosion_area.get_node_or_null("CollisionShape2D")
		if collision_shape and collision_shape.shape:
			var space_state = get_world_2d().direct_space_state
			if space_state:
				var query = PhysicsShapeQueryParameters2D.new()
				query.shape = collision_shape.shape
				query.transform = collision_shape.global_transform
				query.collision_mask = explosion_area.collision_mask if explosion_area.collision_mask != 0 else enemy_collision_mask
				query.collide_with_areas = true
				query.collide_with_bodies = true
				
				var results = space_state.intersect_shape(query)
				for result in results:
					var collider = result.get("collider") as Node2D
					if is_instance_valid(collider) and collider not in damaged_targets:
						damaged_targets.append(collider)
						if collider.has_method("take_damage"):
							collider.take_damage(damage, "physical")
						elif collider.get_parent() and collider.get_parent().has_method("take_damage"):
							collider.get_parent().take_damage(damage, "physical")

	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node not in damaged_targets:
			if node.global_position.distance_to(target_last_position) <= explosion_radius:
				damaged_targets.append(node)
				if node.has_method("take_damage"):
					node.take_damage(damage, "physical")
