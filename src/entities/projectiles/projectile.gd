extends Area2D
class_name Projectile

@export var damage: float = 1.0
@export_enum("physical", "fire", "ice", "poison", "lightning") var damage_type: String = "physical"
@export var max_targets: int = 1
@export var speed: float = 125.0
@export var lifetime: float = 4.0

var direction: Vector2
var has_hit: bool = false
var targets_hit_count: int = 0
var hit_targets: Array[Node2D] = []
var source_tower: Node = null


func _ready() -> void:
	add_to_group("projectile")
	if lifetime > 0.0:
		get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_timeout)


func shoot(pos: Vector2, angle: float) -> void:
	global_position = pos
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
	
	on_hit_target(target)
	
	if targets_hit_count >= max_targets:
		has_hit = true
		_on_max_targets_reached()
	
	return true


func on_hit_target(_target: Node2D) -> void:
	pass


func _on_max_targets_reached() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()


func _on_lifetime_timeout() -> void:
	if is_instance_valid(self) and not is_queued_for_deletion():
		queue_free()
