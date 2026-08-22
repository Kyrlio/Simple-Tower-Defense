extends Node2D
class_name RangeIndicator

@export var fill_color: Color = Color(0.2, 0.65, 1.0, 0.14)
@export var border_color: Color = Color(0.35, 0.85, 1.0, 0.85)
@export var base_ring_color: Color = Color(0.35, 0.85, 1.0, 0.5)
@export var border_width: float = 1.2

var radius: float = 56.0
var center_offset: Vector2 = Vector2(0, -9)
var is_active: bool = false
var anim_tween: Tween


func _ready() -> void:
	visible = false
	modulate.a = 0.0
	z_index = -1
	_update_dimensions()


func _update_dimensions() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
		
	var detection_area = parent_node.get_node_or_null("EnemyDetectionArea")
	if detection_area:
		var col = detection_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if col:
			center_offset = detection_area.position + col.position
			if col.shape is CircleShape2D:
				radius = (col.shape as CircleShape2D).radius
	queue_redraw()


func _draw() -> void:
	if radius <= 0.0:
		return
	
	# Disque de portée semi-transparent
	draw_circle(center_offset, radius, fill_color)
	
	# Contour externe net
	draw_arc(center_offset, radius, 0.0, TAU, 64, border_color, border_width, true)
	
	# Anneau de sélection à la base de la tour
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 32, base_ring_color, 1.0, true)


func set_active(active: bool) -> void:
	if is_active == active and visible == active:
		return
		
	is_active = active
	_update_dimensions()
	
	if anim_tween:
		anim_tween.kill()
		
	anim_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anim_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	if active:
		visible = true
		anim_tween.tween_property(self, "modulate:a", 1.0, 0.18).from(0.0)
	else:
		anim_tween.tween_property(self, "modulate:a", 0.0, 0.15)
		anim_tween.tween_callback(func():
			if not is_active:
				visible = false
		)
