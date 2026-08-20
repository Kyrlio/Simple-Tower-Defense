extends Area2D
class_name Projectile

@export var damage: float = 1
@export var max_targets: int = 1

var direction: Vector2
var speed: float = 125.0

var has_hit: bool = false
var targets_hit_count: int = 0
var hit_targets: Array[Node2D] = []


func setup(pos: Vector2, angle: float, _projectile_enum: Data.Projectile) -> void:
	position = pos
	direction = Vector2.DOWN.rotated(angle - PI/2)
	rotation = angle


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func try_hit(target: Node2D) -> bool:
	if has_hit or targets_hit_count >= max_targets:
		return false
	
	if target in hit_targets:
		return false
	
	hit_targets.append(target)
	targets_hit_count += 1
	
	if targets_hit_count >= max_targets:
		has_hit = true
		_on_max_targets_reached()
	
	return true


func _on_max_targets_reached() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()
