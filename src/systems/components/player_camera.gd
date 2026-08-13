extends Camera2D

## Camera parameters
@export_group("Zoom Settings")
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
@export var zoom_step_factor: float = 1.15
@export var zoom_smoothness: float = 18.0

@export_group("Movement & Drag")
@export var keyboard_speed: float = 350.0
@export var keyboard_acceleration: float = 20.0
@export var keyboard_friction: float = 18.0
@export var drag_acceleration: float = 1.0
@export var drag_friction: float = 14.0

@export_group("Juice & Game Feel")
@export var limit_bump_intensity: float = 0.08
@export var step_punch_intensity: float = 0.04
@export var enable_pixel_snap: bool = false

# Internal state
var target_zoom_level: float = 1.0
var current_zoom_level: float = 1.0

var target_position: Vector2 = Vector2.ZERO
var keyboard_velocity: Vector2 = Vector2.ZERO
var drag_velocity: Vector2 = Vector2.ZERO

var is_dragging: bool = false
var last_drag_world_pos: Vector2 = Vector2.ZERO

# Recoil & punch dynamics
var limit_bump_offset: float = 0.0
var bump_velocity: float = 0.0
var zoom_punch_offset: float = 0.0


func _ready() -> void:
	target_zoom_level = zoom.x
	current_zoom_level = zoom.x
	target_position = global_position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging = event.pressed
			if is_dragging:
				drag_velocity = Vector2.ZERO

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_by_factor(zoom_step_factor)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_by_factor(1.0 / zoom_step_factor)

	elif event is InputEventMouseMotion and is_dragging:
		# Anchor drag 1:1 with ground under mouse pointer
		var delta_drag = (event.relative / current_zoom_level) * drag_acceleration
		target_position -= delta_drag
		# Store instant velocity for momentum after drag release
		drag_velocity = -delta_drag / max(get_process_delta_time(), 0.001)


func _zoom_by_factor(factor: float) -> void:
	var old_target_zoom = target_zoom_level
	var raw_new_zoom = target_zoom_level * factor
	var new_target_zoom = clamp(raw_new_zoom, min_zoom, max_zoom)

	# Check if zoom hit limits for bump feedback
	if raw_new_zoom > max_zoom and old_target_zoom >= max_zoom - 0.001:
		bump_velocity += limit_bump_intensity * 12.0
	elif raw_new_zoom < min_zoom and old_target_zoom <= min_zoom + 0.001:
		bump_velocity -= limit_bump_intensity * 12.0

	if not is_equal_approx(new_target_zoom, old_target_zoom):
		# Punch impulse on zoom step
		var punch_dir = 1.0 if factor > 1.0 else -1.0
		zoom_punch_offset += step_punch_intensity * punch_dir

		# Zoom to cursor anchoring math
		var mouse_world = get_global_mouse_position()
		target_position += (mouse_world - target_position) * (1.0 - old_target_zoom / new_target_zoom)

		target_zoom_level = new_target_zoom


func _process(delta: float) -> void:
	_update_zoom(delta)
	_update_movement(delta)


func _update_zoom(delta: float) -> void:
	# Smooth lerp to target zoom
	var zoom_weight = 1.0 - exp(-zoom_smoothness * delta)
	current_zoom_level = lerp(current_zoom_level, target_zoom_level, zoom_weight)

	# Spring oscillator for limit bump recoil
	var spring_k = 280.0
	var spring_damp = 18.0
	var accel = -spring_k * limit_bump_offset - spring_damp * bump_velocity
	bump_velocity += accel * delta
	limit_bump_offset += bump_velocity * delta

	# Decay zoom step punch
	zoom_punch_offset = lerp(zoom_punch_offset, 0.0, 1.0 - exp(-14.0 * delta))

	# Compute final effective camera zoom
	var final_zoom_val = current_zoom_level + limit_bump_offset + zoom_punch_offset
	final_zoom_val = max(0.1, final_zoom_val)
	zoom = Vector2(final_zoom_val, final_zoom_val)


func _update_movement(delta: float) -> void:
	# WASD Keyboard movement scaled by zoom level (constant screen speed)
	var move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed_multiplier = 1.0 / current_zoom_level
	var target_kbd_vel = move_input * (keyboard_speed * speed_multiplier)

	if move_input != Vector2.ZERO:
		keyboard_velocity = keyboard_velocity.lerp(target_kbd_vel, 1.0 - exp(-keyboard_acceleration * delta))
	else:
		keyboard_velocity = keyboard_velocity.lerp(Vector2.ZERO, 1.0 - exp(-keyboard_friction * delta))

	target_position += keyboard_velocity * delta

	# Mouse drag momentum after release
	if not is_dragging:
		drag_velocity = drag_velocity.lerp(Vector2.ZERO, 1.0 - exp(-drag_friction * delta))
		target_position += drag_velocity * delta

	# Smooth camera position update
	var pos_weight = 1.0 - exp(-25.0 * delta)
	var next_pos = global_position.lerp(target_position, pos_weight)

	if enable_pixel_snap:
		global_position = next_pos.round()
	else:
		global_position = next_pos
