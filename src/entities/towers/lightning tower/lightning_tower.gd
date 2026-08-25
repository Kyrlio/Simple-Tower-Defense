class_name LightningTower
extends Tower

@export_group("Lightning Mechanics")
## Type d'élément/dégât infligé par la tour
@export_enum("physical", "fire", "ice", "poison", "lightning") var damage_type: String = "lightning"
## Nombre maximum de cibles que l'éclair peut toucher en une seule décharge
@export var max_bounces: int = 4
## Distance maximale (en pixels) pour que l'éclair bondisse vers un nouvel ennemi
@export var bounce_range: float = 45.0
## Dégâts infligés au premier ennemi touché
@export var base_damage: float = 8.0
## Réduction des dégâts à chaque rebond (0.85 = -15% de dégâts à chaque saut)
@export var bounce_damage_decay: float = 0.85
## Couleur principale de l'arc électrique
@export var lightning_color: Color = Color(0.3, 0.85, 1.0, 1.0)
## Épaisseur de la ligne d'éclair
@export var lightning_width: float = 3.0
## Durée d'affichage de l'arc électrique en secondes avant dissipation
@export var lightning_duration: float = 0.12
@export var base_shoot_reload_time: float = 1.4

@onready var weapon: Sprite2D = $Visuals/Weapon
@onready var muzzle: Marker2D = $Visuals/Weapon/Muzzle
@onready var animation_player: AnimationPlayer = $AnimationPlayer


## Nettoie la liste des ennemis des références invalides ou supprimées
func _clean_enemies() -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())


## Déclenché à chaque rechargement de la tour
func _on_reload_timer_timeout() -> void:
	_clean_enemies()
	
	if enemies.is_empty():
		return
	
	if animation_player and animation_player.has_animation("shoot"):
		var calculated_anim_speed: float = base_shoot_reload_time / maxf(0.05, shoot_reload_time)
		animation_player.speed_scale = clampf(calculated_anim_speed, 0.1, 10.0)
		animation_player.play("shoot")


## Initialise la chaîne d'éclairs instantanée (Hitscan)
func _fire_chain_lightning() -> void:
	_clean_enemies()
	if enemies.is_empty():
		return
		
	var first_target: Enemy = enemies[0]
	if not is_instance_valid(first_target) or first_target.is_queued_for_deletion():
		return
		
	var hit_targets: Array[Enemy] = []
	var start_pos: Vector2 = muzzle.global_position
	
	# Lancement de la propagation récursive
	SoundManager.play_shoot("lightning", start_pos)
	_propagate_chain(start_pos, first_target, hit_targets, base_damage, max_bounces)


## Algorithme récursif de propagation de l'arc électrique (Chain Lightning)
func _propagate_chain(source_pos: Vector2, current_target: Node2D, hit_targets: Array[Enemy], current_damage: float, remaining_bounces: int) -> void:
	if remaining_bounces <= 0 or not is_instance_valid(current_target) or current_target.is_queued_for_deletion():
		return
		
	# 1. Enregistrement de la cible pour éviter de la frapper à nouveau
	hit_targets.append(current_target)
	
	# 2. Application instantanée des dégâts (avec le type configuré)
	if current_target.has_method("take_damage"):
		current_target.take_damage(current_damage, damage_type)
	elif current_target.has_method("on_hit"):
		current_target.on_hit(current_damage)
		
	# 3. Rendu visuel de l'arc électrique entre la source et la cible
	var target_pos: Vector2 = current_target.global_position
	_create_lightning_effect(source_pos, target_pos)
	
	# 4. Recherche récursive de la cible la plus proche pour le rebond suivant
	if remaining_bounces > 1:
		var next_target: Node2D = _find_next_bounce_target(current_target, hit_targets)
		if is_instance_valid(next_target):
			var next_damage: float = current_damage * bounce_damage_decay
			_propagate_chain(target_pos, next_target, hit_targets, next_damage, remaining_bounces - 1)


## Recherche l'ennemi le plus proche de la cible actuelle dans le rayon de rebond
func _find_next_bounce_target(origin_enemy: Node2D, hit_targets: Array[Enemy]) -> Node2D:
	var closest_enemy: Node2D = null
	var closest_distance: float = bounce_range
	var origin_pos: Vector2 = origin_enemy.global_position
	
	var candidate_enemies: Array[Node2D] = []
	var seen: Dictionary = {}
	
	# 1. Ennemis dans le groupe "enemy"
	for node in get_tree().get_nodes_in_group("enemy"):
		if node is Node2D and is_instance_valid(node) and not node.is_queued_for_deletion():
			if not seen.has(node):
				seen[node] = true
				candidate_enemies.append(node)
				
	# 2. Requête spatiale 2D directe (détecte les Area2D enemies même sans groupe explicite)
	var space_state := get_world_2d().direct_space_state
	if space_state:
		var query := PhysicsShapeQueryParameters2D.new()
		var shape := CircleShape2D.new()
		shape.radius = bounce_range
		query.shape = shape
		query.transform = Transform2D(0.0, origin_pos)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		query.collision_mask = 1
		var results := space_state.intersect_shape(query, 32)
		for res in results:
			var collider = res.get("collider")
			if is_instance_valid(collider) and collider is Node2D and not collider.is_queued_for_deletion():
				if not seen.has(collider):
					seen[collider] = true
					candidate_enemies.append(collider)
					
	# 3. Ennemis actuellement dans la zone de détection de la tour
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not seen.has(enemy):
			seen[enemy] = true
			candidate_enemies.append(enemy)
			
	# Sélection du candidat le plus proche non encore touché
	for enemy in candidate_enemies:
		if enemy in hit_targets or enemy == origin_enemy:
			continue
		if not (enemy.has_method("take_damage") or enemy.has_method("on_hit") or enemy is Enemy):
			continue
			
		var dist: float = origin_pos.distance_to(enemy.global_position)
		if dist <= closest_distance:
			closest_distance = dist
			closest_enemy = enemy
			
	return closest_enemy


## Rendu visuel de l'arc électrique en zig-zag avec perturbations chaotiques perpendiculaires
func _create_lightning_effect(from: Vector2, to: Vector2) -> void:
	var distance: float = from.distance_to(to)
	if distance < 1.0:
		return
		
	var line := Line2D.new()
	line.width = lightning_width
	line.default_color = lightning_color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.top_level = true
	
	# Dégradé lumineux pour un look néon électrique (cœur blanc vers couleur néon)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
	gradient.colors = PackedColorArray([
		lightning_color,
		lightning_color,
		lightning_color,
		Color(lightning_color.r, lightning_color.g, lightning_color.b, 0.8)
	])
	line.gradient = gradient
	
	# Ajout dans la scène (dans le nœud Projectiles s'il existe, sinon dans current_scene)
	var parent_node: Node = get_tree().current_scene.get_node_or_null("Projectiles")
	if parent_node:
		parent_node.add_child(line)
	else:
		get_tree().current_scene.add_child(line)
		
	# Algorithme de génération des segments en zig-zag
	var segments: int = clampi(int(distance / 7.0), 5, 18)
	var path_vector: Vector2 = to - from
	var direction: Vector2 = path_vector.normalized()
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	
	var points: Array[Vector2] = []
	points.append(from)
	
	var last_offset: float = 0.0
	for i in range(1, segments):
		var t: float = float(i) / float(segments)
		var base_point: Vector2 = from.lerp(to, t)
		
		# Enveloppe sinusoïdale (décharge maximale au milieu, nulle aux extrémités)
		var envelope: float = sin(t * PI)
		var max_offset: float = envelope * minf(distance * 0.25, 14.0) + 2.0
		
		# Perturbations aléatoires perpendiculaires lissées
		var raw_offset: float = randf_range(-max_offset, max_offset)
		var smoothed_offset: float = lerpf(last_offset, raw_offset, 0.75)
		last_offset = smoothed_offset
		
		var longitudinal_jitter: float = randf_range(-1.0, 1.0)
		var offset_point: Vector2 = base_point + normal * smoothed_offset + direction * longitudinal_jitter
		points.append(offset_point)
		
	points.append(to)
	line.points = PackedVector2Array(points)
	
	# Bifurcation aléatoire secondaire (fourche d'arc)
	if distance > 30.0 and randf() < 0.4:
		_create_fork_branch(points, normal, direction)
		
	# Animation de flash et dissipation rapide
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, lightning_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(line.queue_free)


## Génère une bifurcation électrique aléatoire secondaire
func _create_fork_branch(main_points: Array[Vector2], normal: Vector2, direction: Vector2) -> void:
	if main_points.size() < 4:
		return
		
	var branch := Line2D.new()
	branch.width = lightning_width * 0.6
	branch.default_color = Color(lightning_color.r, lightning_color.g, lightning_color.b, 0.75)
	branch.joint_mode = Line2D.LINE_JOINT_ROUND
	branch.begin_cap_mode = Line2D.LINE_CAP_ROUND
	branch.end_cap_mode = Line2D.LINE_CAP_ROUND
	branch.top_level = true
	
	var parent_node: Node = get_tree().current_scene.get_node_or_null("Projectiles")
	if parent_node:
		parent_node.add_child(branch)
	else:
		get_tree().current_scene.add_child(branch)
		
	var start_idx: int = randi_range(1, main_points.size() - 2)
	var fork_start: Vector2 = main_points[start_idx]
	var fork_points: Array[Vector2] = [fork_start]
	
	var side: float = 1.0 if randf() > 0.5 else -1.0
	var fork_dir: Vector2 = (direction + normal * side * randf_range(0.6, 1.2)).normalized()
	var branch_length: float = randf_range(8.0, 15.0)
	var fork_segments: int = 3
	
	var current_p: Vector2 = fork_start
	for j in range(1, fork_segments + 1):
		var step_len: float = branch_length / float(fork_segments)
		var jitter_norm: Vector2 = Vector2(-fork_dir.y, fork_dir.x) * randf_range(-2.5, 2.5)
		current_p += fork_dir * step_len + jitter_norm
		fork_points.append(current_p)
		
	branch.points = PackedVector2Array(fork_points)
	
	var fork_tween := branch.create_tween()
	fork_tween.tween_property(branch, "modulate:a", 0.0, lightning_duration * 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fork_tween.tween_callback(branch.queue_free)


func get_damage_value() -> float:
	return base_damage


func get_special_description() -> String:
	return "Chain Lightning (up to %d targets, bounce: %dpx)" % [max_bounces, int(bounce_range)]


func _append_custom_upgrades(upgrades: Array[Dictionary]) -> void:
	var next_bounces = max_bounces + 1
	upgrades.append({
		"id": "max_bounces",
		"name": "Max Bounces",
		"level": get_upgrade_level("max_bounces"),
		"cost": _calc_cost(350, 1.45, "max_bounces"),
		"current_text": "%d bounces" % max_bounces,
		"next_text": "+1 (%d bounces)" % next_bounces,
	})
	
	var next_brange = bounce_range * 1.2
	upgrades.append({
		"id": "bounce_range",
		"name": "Bounce Range",
		"level": get_upgrade_level("bounce_range"),
		"cost": _calc_cost(75, 1.35, "bounce_range"),
		"current_text": "%d px" % int(bounce_range),
		"next_text": "+20%% (%d px)" % int(next_brange),
	})


func _apply_custom_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"max_bounces":
			max_bounces += 1
		"bounce_range":
			bounce_range *= 1.2
