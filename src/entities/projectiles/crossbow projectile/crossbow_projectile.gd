extends Projectile
class_name CrossbowProjectile


func _ready() -> void:
	add_to_group("projectile")
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_timeout)


func shoot(pos: Vector2, angle: float) -> void:
	position = pos
	direction = Vector2.DOWN.rotated(angle - PI/2)
	rotation = angle


func _on_lifetime_timeout() -> void:
	queue_free.call_deferred()
