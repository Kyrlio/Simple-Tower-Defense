@tool
## VFX handler for particle trails for a specific pixel art style.
##
## This class either creates GPUParticles2D and required SubViewport and render 
## target in form of a TextureRect to apply stylization and drop shadow to the
## GPUParticles2D. Or can be provided with existing GPUParticles2D, SubViewport
## and TextureRect, that can potentially be shared with other VFX classes or
## offer more control that way.
## [br]
## A lot of parameters that are handed over to the particle and visual shaders
## that control looks and physics of the particle trails.
## [br]
## Two functions let you spawn the particles and calculate flight time and
## velocity for the particles. 
class_name PixelTrailVFX
extends Control

enum TRAIL_TYPE {
	## Single color trails
	SIMPLE_COLOR,
	## Trails use the palette colors from a texture - 1D left to right
	PALETTE_COLOR
}

const _TRAIL_TYPE_SHADER: Dictionary[int, Shader] = {
	TRAIL_TYPE.SIMPLE_COLOR: preload("uid://dy16xljxcc44e"),
	TRAIL_TYPE.PALETTE_COLOR: preload("uid://ht8le2pdgydw")
}
const _POST_PROCESSING_SHADER: Shader = preload("uid://cthdc1w3hituj")
const _PARTICLE_SHADER: Shader = preload("uid://cux61b2wbf8up")

const _POST_SHADER_UNIFORMS: Array[String] = ["shadow_offset", "shadow_color"]
const _PARTICLE_UNIFORMS: Array[String] = ["gravity", "trail_length"]
const _SHADER_UNIFORMS_BASE: Array[String] = ["trail_max_width", "trail_length", "shape_change_rate", "shape_base", "trail_fade_head", "trail_split_rate", "border_fade_falloff", "first_fade_rate", "second_fade_rate", "pixel_noise_falloff", "line_noise_falloff", "primary_noise_type", "primary_time_fade_strength", "primary_noise_strength", "enable_secondary_noise", "secondary_noise_type", "secondary_time_fade_strength", "secondary_noise_strength"]
const _SHADER_UNIFORMS: Dictionary[int, Array] = {
	TRAIL_TYPE.SIMPLE_COLOR: ["trail_color"],
	TRAIL_TYPE.PALETTE_COLOR: ["trail_color_palette", "trail_color_falloff"]
}

## Use external parts for the vfx for more control. Specific settings are necessary for these external nodes to get the intended look and functionality.
## @experimental
@export var external_parts: bool = false:
	set(value):
		external_parts = value
		notify_property_list_changed()
		_update_low_res_viewport()
		_update_post_processing()
		_update_gpu_particles()
		_update_viewport_size()
		update_configuration_warnings()
## SubViewport for rendering the GPU Particles in, which then gets processed as a texture to render the results. Using external allows for multiple VFX to share the same SubViewport. Specific settings are necessary to get the intended look and functionality. Check _update_low_res_viewport for the relevant settings.
## @experimental
@export var low_res_viewport: SubViewport = null:
	set(value):
		low_res_viewport = value
		_update_low_res_viewport()
		_update_viewport_size()
	get():
		if external_parts:
			return low_res_viewport
		else:
			return _low_res_viewport
## The TextureRect, replacing an internal TextureRect that adds a drop shadow effect to the VFX via ShaderMaterial and upscales the Viewport based on pixel_size. Specific settings are necessary to get the intended look and functionality. Check _update_post_processing for the relevant settings.
@export var post_processing: TextureRect = null:
	set(value):
		post_processing = value
		_update_post_processing()
		_update_viewport_size()
	get():
		if external_parts:
			return post_processing
		else:
			return _post_processing
## The GPUParticle2D node, used to emit particles. Specific settings are necessary to get the intended look and functionality. Check _update_gpu_particles for the relevant settings.
@export var gpu_particles: GPUParticles2D = null:
	set(value):
		gpu_particles = value
		_update_gpu_particles()
		_update_viewport_size()
	get():
		if external_parts:
			return gpu_particles
		else:
			return _gpu_particles

## The gpu particle amount: The number of particles to emit in one emission cycle. The effective emission rate is (amount * amount_ratio) / lifetime particles per second. Higher values will increase GPU requirements, even if not all particles are visible at a given time or if amount_ratio is decreased. Note: Changing this value will cause the particle system to restart.
@export var amount: int = 1000:
	set(value):
		amount = value
		if gpu_particles:
			gpu_particles.amount = amount

## The pixelization rate. 2.0 means one vfx pixel stretches 2.0 vieport pixels.
@export var pixel_scale: float = 2.0:
	set(value):
		pixel_scale = value
		if _viewport_size:
			if low_res_viewport:
				low_res_viewport.size = _viewport_size / pixel_scale
			if post_processing:
				post_processing.size = _viewport_size
## Gravity scale. Defines how fast a particle falls down.
@export var gravity: float = 500.0:
	set(value):
		gravity = value
		_set_particle_uniform("gravity")
## The maximum width a particle trail can have. Affects the performance.
@export var trail_max_width: float = 10.0:
	set(value):
		trail_max_width = value
		if gpu_particles and gpu_particles.texture:
			(gpu_particles.texture as GradientTexture2D).width = int(trail_max_width)
		_set_shader_uniform("trail_max_width")
## The length of a trail defined by the time offset of the tail in seconds. 0.4s means the end of the trail is 0.4s behind the the front.
@export var trail_length: float = 0.4:
	set(value):
		trail_length = value
		if gpu_particles:
			gpu_particles.trail_lifetime = trail_length
		_set_shader_uniform("trail_length")
		_set_particle_uniform("trail_length")

@export_category("Drop Shadow")
## Drop Shadow offset. Defines at which distance a particle pixel will spawn a shadow pixel.
@export var shadow_offset: Vector2i = Vector2i(0, -1):
	set(value):
		shadow_offset = value
		_set_post_processing_uniform("shadow_offset")
## Drop Shadow color.
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 1.0):
	set(value):
		shadow_color = value
		_set_post_processing_uniform("shadow_color")

@export_category("Trail Shape")
@export_group("Base Shape")
## The rate of change for the shape of the trail. Usually between 0.0 (No change) - 1.0 (A lot of change).
@export var shape_change_rate: float = 0.75:
	set(value):
		shape_change_rate = value
		_set_shader_uniform("shape_change_rate")
## The shape baseline, 0.0 = means full shape - 1.0 = means faded out shape.
@export var shape_base: float = 0.25:
	set(value):
		shape_base = value
		_set_shader_uniform("shape_base")
## The portion of the trail, that gets special treatment and smoothed to make a rounder shape.
@export_range(0.0, 1.0, 0.001) var trail_fade_head: float = 0.1:
	set(value):
		trail_fade_head = value
		_set_shader_uniform("trail_fade_head")
## The trail width is split by this rate. 1.0 means every pixel width is shaped diffently, 0.0 means the trail is shaped as one thick line regardless of width.
@export var trail_split_rate: float = 1.0:
	set(value):
		trail_split_rate = value
		_set_shader_uniform("trail_split_rate")
## Defines the border fade curve of the trail. 1.0 - linear, 2.0 - quadratic, 0.5 - square root.
@export var border_fade_falloff: float = 0.25:
	set(value):
		border_fade_falloff = value
		_set_shader_uniform("border_fade_falloff")
## Modifies fadeout threshold, can't really describe it, sorry!
@export_range(0.0, 1.0, 0.001) var first_fade_rate: float = 0.6:
	set(value):
		first_fade_rate = value
		_set_shader_uniform("first_fade_rate")
## Modifies fadeout value compared to the threshold, can't really describe it, sorry!
@export_range(0.0, 1.0, 0.001) var second_fade_rate: float = 0.85:
	set(value):
		second_fade_rate = value
		_set_shader_uniform("second_fade_rate")
@export_group("Noise")
## Defines the pixel noise curve, changing how frequent the trails are. 1.0 - linear, 2.0 - quadratic, 0.5 - square root.
@export var pixel_noise_falloff: float = 0.25:
	set(value):
		pixel_noise_falloff = value
		_set_shader_uniform("pixel_noise_falloff")
## Defines the line noise curve, changing how long the trail splits are. 1.0 - linear, 2.0 - quadratic, 0.5 - square root.
@export var line_noise_falloff: float = 0.5:
	set(value):
		line_noise_falloff = value
		_set_shader_uniform("line_noise_falloff")
## How fast should the line noise vary in general, lower values mean longer lines.
@export var line_noise_variation: float = 10.0:
	set(value):
		line_noise_variation = value
		_set_shader_uniform("line_noise_variation")
@export_subgroup("Primary Noise")
## Set which noise type should be used for the primary (start) of the trail shape.
@export_enum("Line", "Pixel") var primary_noise_type: int = 0:
	set(value):
		primary_noise_type = value
		_set_shader_uniform("primary_noise_type")
## Influence of trails lifetime on the fading of the primary (start)  part of the trail.
@export_range(0.0, 1.0, 0.01) var primary_time_fade_strength: float = 0.8:
	set(value):
		primary_time_fade_strength = value
		_set_shader_uniform("primary_time_fade_strength")
## Influence of the noise value on the trails shape of the primary (start) part of the trail.
@export_range(0.0, 1.0, 0.01) var primary_noise_strength: float = 0.8:
	set(value):
		primary_noise_strength = value
		_set_shader_uniform("primary_noise_strength")
@export_subgroup("Secondary Noise")
@export var enable_secondary_noise: bool = true:
	set(value):
		enable_secondary_noise = value
		_set_shader_uniform("enable_secondary_noise")
		notify_property_list_changed()
## Set which noise type should be used for the secondary (end) part of the trail shape.
@export_enum("Line", "Pixel") var secondary_noise_type: int = 0:
	set(value):
		secondary_noise_type = value
		_set_shader_uniform("secondary_noise_type")
## Influence of trails lifetime on the fading of the secondary (end) part of the trail.
@export_range(0.0, 1.0, 0.01) var secondary_time_fade_strength: float = 0.5:
	set(value):
		secondary_time_fade_strength = value
		_set_shader_uniform("secondary_time_fade_strength")
## Influence of the noise value on the trails shape of the secondary (end) part of the trail.
@export_range(0.0, 1.0, 0.01) var secondary_noise_strength: float = 1.0:
	set(value):
		secondary_noise_strength = value
		_set_shader_uniform("secondary_noise_strength")
		
@export_category("Color")
## Color type of the trails.
@export var trail_type: TRAIL_TYPE = TRAIL_TYPE.PALETTE_COLOR:
	set(value):
		trail_type = value
		if gpu_particles:
			gpu_particles.material.shader = _TRAIL_TYPE_SHADER[trail_type]
			for uniform in _SHADER_UNIFORMS[trail_type]:
				_set_shader_uniform(uniform)
		notify_property_list_changed()
## Color of the trail.
@export var trail_color: Color = Color.WHITE:
	set(value):
		trail_color = value
		_set_shader_uniform("trail_color")
## Color palette of the trail. Should be 1D horizontal color palette. Color transitions from left to right.
@export var trail_color_palette: Texture2D:
	set(value):
		trail_color_palette = value
		_set_shader_uniform("trail_color_palette")
## Defines the color curve of the trail. 1.0 - linear, 2.0 - quadratic, 0.5 - square root.
@export var trail_color_falloff: float = 0.5:
	set(value):
		trail_color_falloff = value
		_set_shader_uniform("trail_color_falloff")


var _viewport_size: Vector2:
	set(value):
		if _viewport_size != value:
			_viewport_size = value
			if low_res_viewport:
				low_res_viewport.size = _viewport_size / pixel_scale
			if post_processing:
				post_processing.size = _viewport_size
		else:
			_viewport_size = value
		
@onready var _post_processing: TextureRect
@onready var _low_res_viewport: SubViewport
@onready var _gpu_particles: GPUParticles2D

func _ready() -> void:
	_update_low_res_viewport()
	_update_post_processing()
	_update_gpu_particles()
		
	var viewport = get_viewport()
	viewport.size_changed.connect(_update_viewport_size)
	_update_viewport_size()


func _process(_delta: float) -> void:
	# Synchronise le viewport de particules avec la caméra active du jeu
	var vp = get_viewport()
	if vp and low_res_viewport:
		var ct: Transform2D = vp.get_canvas_transform()
		low_res_viewport.canvas_transform = Transform2D(
			ct.x / pixel_scale,
			ct.y / pixel_scale,
			ct.origin / pixel_scale
		)


func _update_low_res_viewport() -> void:
	if low_res_viewport:
		if _low_res_viewport and low_res_viewport != _low_res_viewport and external_parts:
			_low_res_viewport.queue_free()
	else:
		var new_viewport = SubViewport.new()
		new_viewport.name = "LowResViewport"
		new_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		new_viewport.unique_name_in_owner = true
		new_viewport.disable_3d = true
		new_viewport.transparent_bg = true
		new_viewport.handle_input_locally = false
		new_viewport.snap_2d_transforms_to_pixel = true
		new_viewport.snap_2d_vertices_to_pixel = true
		new_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		_low_res_viewport = new_viewport
		add_child(new_viewport)
	if low_res_viewport:
		if post_processing:
			post_processing.texture = low_res_viewport.get_texture()
			post_processing.material.set_shader_parameter("vp_texture", low_res_viewport.get_texture())
		if gpu_particles:
			gpu_particles.reparent(low_res_viewport)
		
func _update_post_processing() -> void:
	if post_processing:
		if _post_processing and post_processing != _post_processing and external_parts:
			_post_processing.queue_free()
	else:
		var new_texture_rect: TextureRect = TextureRect.new()
		new_texture_rect.name = "PostProcessing"
		new_texture_rect.unique_name_in_owner = true
		new_texture_rect.material = ShaderMaterial.new()
		new_texture_rect.material.shader = _POST_PROCESSING_SHADER
		new_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		new_texture_rect.mouse_filter =Control.MOUSE_FILTER_IGNORE
		_post_processing = new_texture_rect
		add_child(new_texture_rect)
	
	if post_processing:
		if low_res_viewport:
			post_processing.texture = low_res_viewport.get_texture()
			post_processing.material.set_shader_parameter("vp_texture", low_res_viewport.get_texture())
			
		for psu in _POST_SHADER_UNIFORMS:
			post_processing.material.set_shader_parameter(psu, get(psu))

func _update_gpu_particles() -> void:
	if gpu_particles:
		if _gpu_particles and gpu_particles != _gpu_particles and external_parts:
			_gpu_particles.queue_free()
	else:
		var new_gpu_particles: GPUParticles2D = GPUParticles2D.new()
		new_gpu_particles.name = "TrailParticles"
		new_gpu_particles.unique_name_in_owner = true
		new_gpu_particles.material = ShaderMaterial.new()
		new_gpu_particles.process_material = ShaderMaterial.new()
		new_gpu_particles.process_material.shader = _PARTICLE_SHADER
		new_gpu_particles.emitting = false
		new_gpu_particles.lifetime = 10.0
		var new_gradient = GradientTexture2D.new()
		new_gradient.gradient = preload("uid://bfxgg44hyxeh1")
		new_gradient.width = trail_max_width
		new_gradient.height = 1000
		new_gradient.fill_from = Vector2(0.0, 1.0)
		new_gradient.fill_to = Vector2(0.0, 0.0)
		new_gpu_particles.texture = new_gradient
		new_gpu_particles.trail_enabled = true
		_gpu_particles = new_gpu_particles
		if low_res_viewport:
			low_res_viewport.add_child(new_gpu_particles)
		else:
			add_child(new_gpu_particles)
	
	if gpu_particles:
		gpu_particles.amount = amount
		gpu_particles.material.shader = _TRAIL_TYPE_SHADER[trail_type]
		(gpu_particles.texture as GradientTexture2D).width = int(trail_max_width)
		gpu_particles.trail_lifetime = trail_length
		for pu in _PARTICLE_UNIFORMS:
			gpu_particles.process_material.set_shader_parameter(pu, get(pu))
		for su in _SHADER_UNIFORMS_BASE:
			gpu_particles.material.set_shader_parameter(su, get(su))
		for u in _SHADER_UNIFORMS[trail_type]:
			_set_shader_uniform(u)

func _validate_property(property: Dictionary) -> void:
	if property.name not in _SHADER_UNIFORMS[trail_type] and property.name in _SHADER_UNIFORMS[(trail_type + 1) % 2]:
		property.usage = PROPERTY_USAGE_NONE
	elif (property.name as String).begins_with("secondary_") and not enable_secondary_noise:
			property.usage = PROPERTY_USAGE_NONE
	elif property.name in ["low_res_viewport", "post_processing", "gpu_particles"] and not external_parts:
		property.usage = PROPERTY_USAGE_NONE

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	if external_parts:
		if not low_res_viewport:
			warnings.push_back("No SubViewport assigned!")
		if not post_processing:
			warnings.push_back("No PostProcessing TextureRect assigned!")
		if not gpu_particles:
			warnings.push_back("No GPUParticles assigned!")
	return warnings

func _set_post_processing_uniform(property: String) -> void:
	if post_processing:
		post_processing.material.set_shader_parameter(property, get(property))
		
func _set_particle_uniform(property: String) -> void:
	if gpu_particles:
		gpu_particles.process_material.set_shader_parameter(property, get(property))
		
func _set_shader_uniform(property: String) -> void:
	if gpu_particles:
		gpu_particles.material.set_shader_parameter(property, get(property))

func _update_viewport_size() -> void:
	var viewport = get_viewport()
	if viewport:
		_viewport_size = viewport.size
		if is_instance_of(viewport, Window):
			_viewport_size = (viewport as Window).content_scale_size
		else:
			if Engine.is_editor_hint():
				var game_size = Vector2i(
					ProjectSettings.get_setting("display/window/size/viewport_width"),
					ProjectSettings.get_setting("display/window/size/viewport_height")
				)
				_viewport_size = game_size
		if low_res_viewport:
			low_res_viewport.size = _viewport_size / pixel_scale
		if post_processing:
			post_processing.size = _viewport_size

## Launches one gpu projectile flying at a target position at specific speed, which affects the arc of the particle trail.
## [param start]: start position of the projectile.
## [param target]: target position for the projectile.
## [param projectile_size]: size of the projectile.
## [param speed]: speed of the projectile.
## Speed affects the projectile trail arch. Higher speed, lower arc. [br]
## Projectile sizes are maxed at [member trail_max_width] meaning higher values are not larger than this. Keep [member trail_max_width] as low as possible, as it affects the performance. [br]
## Returns the time until the projectile hits the target.
func launch(start: Vector2, target: Vector2, projectile_size: float = 1.0, speed: float = 1.0) -> float:
	var trans = Transform2D.IDENTITY
	trans = trans.translated(start / pixel_scale)
	var distance: float = abs(target.x - start.x)
	var max_height: float = distance * (0.2 + 1.0 / speed) * 0.2
	var arc_height: float = target.y - start.y - max_height
	arc_height = min(arc_height, -max_height)
	var arc_values: Array[Vector2] = calculate_arc_velocity(start / pixel_scale, target / pixel_scale, arc_height / pixel_scale)
	var velocity: Vector2 = arc_values[0]
	var time: float = (arc_values[1].x + arc_values[1].y)
	var custom_data: Color = Color.BLACK
	custom_data.g = projectile_size / trail_max_width
	custom_data.a = time
	var static_data: Color = Color.WHITE
	if gpu_particles:
		gpu_particles.emit_particle(trans, velocity, static_data, custom_data, 0x1F)
	return time


## Lance une traînée synchronisée avec la physique d'un projectile
func launch_to_target(start: Vector2, target: Vector2, duration: float, arc_h: float, projectile_size: float = 4.0) -> void:
	# 1. Calcul de la gravité nécessaire pour atteindre exactement cet arc_height en 'duration' secondes
	var g_world: float = (8.0 * arc_h) / (duration * duration)
	var g_local: float = g_world / pixel_scale
	gravity = g_local
	
	# 2. Position de départ dans le repère du viewport
	var trans = Transform2D.IDENTITY.translated(start / pixel_scale)
	
	# 3. Vitesse initiale exacte (X et Y) pour arriver à 'target' à t = duration
	var vel_x: float = (target.x - start.x) / (pixel_scale * duration)
	var vel_y: float = ((target.y - start.y) / pixel_scale - 0.5 * g_local * duration * duration) / duration
	var velocity: Vector2 = Vector2(vel_x, vel_y)
	
	var custom_data: Color = Color.BLACK
	custom_data.g = projectile_size / trail_max_width
	custom_data.a = duration
	var static_data: Color = Color.WHITE
	
	if gpu_particles:
		gpu_particles.emit_particle(trans, velocity, static_data, custom_data, 0x1F)



## Calculate the velocity and times of the movement phases of the projectile. [br]
## [param start]: start position of the projectile.
## [param target]: target position for the projectile.
## [param arc_height]: The desired arc height for the projectile's flight path.
## The desired arc height and [member gravity] is used to calculate the flight time and required start velocity to fullfill the arc height and reach the target.
## Returns an array of Vector2 containing the start velocity (first Vector2) and Up/Down flight time (second Vector2) of the projectile.
func calculate_arc_velocity(start: Vector2, target: Vector2, arc_height: float) -> Array[Vector2]:
	var velocity: Vector2 = Vector2.ZERO
	var displacement: Vector2 = target - start
	var time_up: float = 0.0
	var time_down: float = 0.0
	if displacement.y > arc_height:
		time_up = sqrt(-2.0 * arc_height / gravity)
		time_down = sqrt(2.0 * (displacement.y - arc_height) / gravity)
		velocity.y = - sqrt(-2.0 * gravity * arc_height)
		velocity.x = displacement.x / float(time_up + time_down)
	return [velocity, Vector2(time_up, time_down)]
