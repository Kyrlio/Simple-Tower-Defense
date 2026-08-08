extends Area2D
class_name Arrow

var direction: Vector2
var speed: float = 200.0


func setup(pos: Vector2, angle: float, projectile_enum: Data.Projectile) -> void:
	position = pos
	direction = Vector2.DOWN.rotated(angle - PI/2)
	rotation = angle


func _process(delta: float) -> void:
	position += direction * speed * delta
