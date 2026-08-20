extends Node2D

const ARROW = preload("uid://cdxelq0wi6jwf")
const CANNON = preload("uid://dcjv0y55wy5ec")


@onready var projectiles: Node2D = $Projectiles

func _ready() -> void:
	GameEvents.shoot.connect(create_projectile)
	GoldManager.add_gold(500)


func create_projectile(pos: Vector2, angle: float, projectile_enum: Data.Projectile) -> void:
	var projectile = null
	match projectile_enum:
		Data.Projectile.ARROW:
			projectile = ARROW.instantiate() as Arrow
		Data.Projectile.CANNON:
			projectile = CANNON.instantiate() as Cannon
		
	projectile.setup(pos, angle, projectile_enum)
	projectiles.add_child(projectile)
