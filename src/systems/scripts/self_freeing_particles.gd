extends GPUParticles2D

func _ready():
	if Data.deactivate_particles:
		emitting = false
		queue_free()
		return
		
	var max_lifetime: float = lifetime / speed_scale
	
	emitting = true

	
	for child in get_children():
		# Skip non particles nodes
		if not child is GPUParticles2D: continue
		
		if get_node_or_null(sub_emitter) == child:
			return
		
		# Tell the particles to emit
		#child.emitting = true
		
		# Select the highest lifetime
		var curr_lifetime: float = child.lifetime / child.speed_scale
		if curr_lifetime > max_lifetime: max_lifetime = curr_lifetime

	# Libération rapide dès la fin d'émission pour ne pas surcharger l'arbre
	await get_tree().create_timer(max_lifetime + 0.1).timeout
	if is_instance_valid(self) and not is_queued_for_deletion():
		queue_free()
