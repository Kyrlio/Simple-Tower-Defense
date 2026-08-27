extends Line2D

@export_category('Trail')
@export var length : = 10

@onready var parent : Node2D = get_parent()
var offset : = Vector2.ZERO

func _ready() -> void:
	offset = position
	top_level = true

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(parent) or not parent.visible or not parent.is_physics_processing():
		clear_points()
		return
		
	global_position = Vector2.ZERO

	var point : = parent.global_position + offset
	if get_point_count() > 0:
		var last_p := get_point_position(0)
		# Si téléportation / réapparition du projectile (ex: sortie du pool), reset immédiat
		if last_p.distance_squared_to(point) > 2500.0:
			clear_points()
			
	add_point(point, 0)
	
	if get_point_count() > length:
		remove_point(get_point_count() - 1)


func reset_trail() -> void:
	clear_points()


