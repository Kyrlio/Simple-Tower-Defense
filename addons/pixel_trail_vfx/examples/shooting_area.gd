@tool
class_name DemoProjectileSpawner
extends Node

const SPEED_OPTIONS: Array[float] = [0.5, 0.75, 1.0, 2.0, 3.0, 5.0]

@export var max_size: float = 10.0
@export var auto_spawn: bool = true
@export var area_start_y: float = 0.0
@export var area_height: float = 0.33

var cooldown: float = 0.0
var _viewport_size: Vector2

@onready var start_rect: TextureRect = $Start
@onready var target_rect: TextureRect = $Target
@onready var trail_vfx: PixelTrailVFX = $PixelTrailVFX

func _ready() -> void:
	var viewport = get_viewport()
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

func _process(delta: float) -> void:
	if cooldown > 0.0:
		cooldown -= delta
	if trail_vfx and cooldown <= 0.0 and auto_spawn:
		spawn_gpu_projectile()

func _update_target(target: Vector2) -> void:
	target_rect.global_position = target - target_rect.size * target_rect.scale * 0.5

func spawn_gpu_projectile(speed_option: int = -1, randomize_pos: bool = true, particle_size: float = 0.0) -> float:
	var offset_start = Vector2(randf() if randomize_pos else 0.15, randf() if randomize_pos else 0.5)
	var start = Vector2(offset_start.x * _viewport_size.x * 0.15 + _viewport_size.x * 0.05, offset_start.y * area_height * _viewport_size.y * 0.8 + area_start_y * _viewport_size.y + area_height * _viewport_size.y * 0.2)
	start_rect.global_position = start - start_rect.size * start_rect.scale * 0.5
	var offset_target = Vector2(randf() if randomize_pos else 0.35, randf() if randomize_pos else 0.5)
	var target = Vector2(offset_target.x * _viewport_size.x * 0.15 + _viewport_size.x * 0.8, offset_target.y * area_height * _viewport_size.y * 0.8 + area_start_y * _viewport_size.y + area_height * _viewport_size.y * 0.2)
	target_rect.global_position = target - target_rect.size * target_rect.scale * 0.5
	var speed = SPEED_OPTIONS[randi() % SPEED_OPTIONS.size()] if speed_option == -1 else SPEED_OPTIONS[speed_option]
	var p_size = min(particle_size, max_size) if particle_size >= 1.0 else randf() * (max_size - 1.0) + 1.0
	var flight_time: float = trail_vfx.launch(start, target, p_size, speed) + 0.4
	cooldown += flight_time
	return flight_time
