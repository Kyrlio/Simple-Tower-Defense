extends Node2D

const ARROW = preload("uid://cdxelq0wi6jwf")

@export var spawner_west: EnemySpawner

@onready var projectiles: Node2D = $Projectiles
@onready var wave_timer: Timer = $WaveTimer
@onready var path_2d: Path2D = $WaveManager/SpawnerWest/Path2D

func _ready() -> void:
	# SIGNALS
	GameEvents.shoot.connect(create_projectile)
	wave_timer.timeout.connect(next_wave)
	
	#enemy_spawner.start_next_wave()


func next_wave() -> void:
	spawner_west.start_next_wave()
	#enemy_spawner.start_next_wave()
	wave_timer.wait_time *= 1.15
	print(wave_timer.wait_time)



func create_projectile(pos: Vector2, angle: float, projectile_enum: Data.Projectile) -> void:
	var projectile = ARROW.instantiate() 
	projectile.setup(pos, angle, projectile_enum)
	projectiles.add_child(projectile)
