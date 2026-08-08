extends Node2D

const ARROW = preload("uid://cdxelq0wi6jwf")

@export var enemy_scene: PackedScene

@onready var path_2d: Path2D = $Path2D
@onready var projectiles: Node2D = $Projectiles

func _ready() -> void:
	# SIGNALS
	GameEvents.shoot.connect(create_projectile)
	
	var path_follow: PathFollow2D = PathFollow2D.new()
	path_follow.rotates = false
	var enemy = enemy_scene.instantiate()
	enemy.setup(path_follow)
	path_follow.add_child(enemy)
	path_2d.add_child(path_follow)



func create_projectile(pos: Vector2, angle: float, projectile_enum: Data.Projectile) -> void:
	var projectile = ARROW.instantiate() 
	projectile.setup(pos, angle, projectile_enum)
	projectiles.add_child(projectile)
