extends Area2D
class_name Arrow

@export var damage: int = 1

var direction: Vector2
var speed: float = 125.0


func setup(pos: Vector2, angle: float, projectile_enum: Data.Projectile) -> void:
	position = pos
	direction = Vector2.DOWN.rotated(angle - PI/2)
	rotation = angle


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
