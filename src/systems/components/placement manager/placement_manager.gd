extends Node2D

@export var particle_effect: PackedScene
@export var tower_exclusion_layer: TileMapLayer
@export var towers_container: Node2D

var preview_tower: Node2D
var is_placing: bool = false
var active_tower_data: TowerStats


func _ready() -> void:
	if not tower_exclusion_layer:
		tower_exclusion_layer = get_node_or_null("../Tilemaps/TowerExclusion")
	
	GameEvents.tower_selected.connect(select_tower_to_build)
	
	if not towers_container:
		towers_container = get_node_or_null("../Towers")
		if not towers_container:
			towers_container = Node2D.new()
			towers_container.name = "Towers"
			get_parent().add_child.call_deferred(towers_container)
			
	if towers_container:
		towers_container.y_sort_enabled = true


func _physics_process(_delta: float) -> void:
	if is_placing:
		update_preview()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_P:
		if not is_placing:
			start_placement()
		else:
			cancel_placement()
	
	if is_placing:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var mouse_pos = get_global_mouse_position()
				var local_mouse = tower_exclusion_layer.to_local(mouse_pos)
				var map_pos = tower_exclusion_layer.local_to_map(local_mouse)
				
				if is_placement_valid(map_pos):
					attempt_placement(map_pos)
				else:
					print("Placement impossible ici")
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				cancel_placement()


func select_tower_to_build(tower_data: TowerStats) -> void:
	if is_placing:
		cancel_placement()
	active_tower_data = tower_data
	start_placement()


func start_placement() -> void:
	if not active_tower_data:
		return
	
	if GoldManager.gold >= active_tower_data.cost:
		is_placing = true
		preview_tower = active_tower_data.tower_scene.instantiate()
		
		if "is_preview" in preview_tower:
			preview_tower.is_preview = true
		
		preview_tower.z_index = 10
		add_child(preview_tower)
		
		preview_tower.set_process(false)
		preview_tower.set_physics_process(false)
		
		var timer = preview_tower.get_node_or_null("ReloadTimer")
		if timer:
			timer.stop()
			
		var detection_area = preview_tower.get_node_or_null("EnemyDetectionArea")
		if detection_area:
			detection_area.monitoring = false
			detection_area.monitorable = false
		
		update_preview()


func update_preview() -> void:
	if not preview_tower or not tower_exclusion_layer:
		return
		
	var mouse_pos = get_global_mouse_position()
	var local_mouse = tower_exclusion_layer.to_local(mouse_pos)
	var map_pos = tower_exclusion_layer.local_to_map(local_mouse)
	
	var snapped_local = tower_exclusion_layer.map_to_local(map_pos)
	preview_tower.global_position = tower_exclusion_layer.to_global(snapped_local)
	
	if is_placement_valid(map_pos):
		preview_tower.modulate = Color(0.2, 1.0, 0.2, 0.6)
	else:
		preview_tower.modulate = Color(1.0, 0.2, 0.2, 0.6)


func is_placement_valid(map_coords: Vector2i) -> bool:
	if GoldManager.gold < active_tower_data.cost:
		return false
		
	if tower_exclusion_layer:
		if tower_exclusion_layer.get_cell_source_id(map_coords) != -1:
			return false
			
	var target_global_pos = tower_exclusion_layer.to_global(tower_exclusion_layer.map_to_local(map_coords))
	for active_tower in get_tree().get_nodes_in_group("towers"):
		if active_tower.global_position.distance_to(target_global_pos) < 5.0:
			return false
			
	return true


func attempt_placement(map_coords: Vector2i) -> void:
	if GoldManager.spend_gold(active_tower_data.cost):
		var real_tower = active_tower_data.tower_scene.instantiate()
		var snapped_local = tower_exclusion_layer.map_to_local(map_coords)
		real_tower.global_position = tower_exclusion_layer.to_global(snapped_local)
		real_tower.add_to_group("towers")
		
		if towers_container:
			towers_container.add_child(real_tower)
		else:
			get_parent().add_child(real_tower)
	
		if particle_effect:
			var fx = particle_effect.instantiate()
			fx.global_position = real_tower.global_position
			get_parent().add_child(fx)
			
		cancel_placement()
	else:
		print("Pas assez d'or !")


func cancel_placement() -> void:
	is_placing = false
	if preview_tower:
		preview_tower.queue_free()
		preview_tower = null
