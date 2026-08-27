extends Node

## Pools d'instances inactives indexés par le chemin de la ressource de scène (String -> Array[Projectile])
var _pools: Dictionary = {}

## Conteneur par défaut dans l'arbre pour les projectiles si non spécifié
var _default_parent: Node = null


func _ready() -> void:
	# Réinitialisation propre lors des changements de scène
	get_tree().scene_changed.connect(_on_scene_changed)


func _on_scene_changed() -> void:
	clear_all()


## Récupère un projectile inactif dans le pool ou en instancie un nouveau
func spawn_projectile(scene: PackedScene, parent: Node = null) -> Projectile:
	if not scene:
		return null
		
	var scene_key: String = scene.resource_path
	var pool_list: Array = _pools.get(scene_key, [])
	var instance: Projectile = null
	
	# Recherche d'une instance disponible et valide dans le pool
	while not pool_list.is_empty():
		var candidate = pool_list.pop_back()
		if is_instance_valid(candidate) and not candidate.is_queued_for_deletion():
			instance = candidate
			break
			
	var target_parent = parent
	if not is_instance_valid(target_parent):
		target_parent = _get_default_parent()
		
	if instance == null:
		# Pas d'instance inactive disponible : création d'une nouvelle
		instance = scene.instantiate() as Projectile
		if not instance:
			return null
		instance._pool_scene_path = scene_key
		if target_parent and is_instance_valid(target_parent):
			target_parent.add_child(instance)
		else:
			get_tree().current_scene.add_child(instance)
	else:
		# Reparenting si nécessaire si le conteneur a changé
		if instance.get_parent() != target_parent and target_parent and is_instance_valid(target_parent):
			instance.reparent(target_parent)
			
	# Réactivation complète du projectile
	instance.reactivate()
	return instance


## Remet un projectile inactif dans le pool correspondant
func return_projectile(proj: Projectile) -> void:
	if not is_instance_valid(proj) or proj.is_queued_for_deletion():
		return
		
	var scene_key: String = proj._pool_scene_path
	if scene_key.is_empty():
		proj.queue_free()
		return
		
	proj.deactivate()
	
	if not _pools.has(scene_key):
		_pools[scene_key] = []
		
	_pools[scene_key].append(proj)


## Vide et détruit tous les pools
func clear_all() -> void:
	for scene_key in _pools:
		var list: Array = _pools[scene_key]
		for item in list:
			if is_instance_valid(item) and not item.is_queued_for_deletion():
				item.queue_free()
	_pools.clear()


func _get_default_parent() -> Node:
	if is_instance_valid(_default_parent):
		return _default_parent
		
	var cur_scene = get_tree().current_scene
	if cur_scene:
		var proj_node = cur_scene.get_node_or_null("Projectiles")
		if proj_node:
			_default_parent = proj_node
			return proj_node
		return cur_scene
	return self
