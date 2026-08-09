extends Node2D

const ARROW = preload("uid://cdxelq0wi6jwf")

@export var enemy_scene: PackedScene

@onready var path_2d: Path2D = $Path2D
@onready var projectiles: Node2D = $Projectiles
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var wave_timer: Timer = $WaveTimer

func _ready() -> void:
	# SIGNALS
	GameEvents.shoot.connect(create_projectile)
	wave_timer.timeout.connect(next_wave)
	
	#enemy_spawner.start_next_wave()


func next_wave() -> void:
	enemy_spawner.start_next_wave()
	wave_timer.wait_time *= 1.25
	print(wave_timer.wait_time)



func create_projectile(pos: Vector2, angle: float, projectile_enum: Data.Projectile) -> void:
	var projectile = ARROW.instantiate() 
	projectile.setup(pos, angle, projectile_enum)
	projectiles.add_child(projectile)
