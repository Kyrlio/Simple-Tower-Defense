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
var _time_alive: float = 0.0
var _pool_scene_path: String = ""


func _ready() -> void:
	add_to_group("projectile")


## Réactivation du projectile lors de sa sortie du pool
func reactivate() -> void:
	has_hit = false
	targets_hit_count = 0
	hit_targets.clear()
	_time_alive = 0.0
	source_tower = null
	visible = true
	set_physics_process(true)
	set_process(true)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	var col = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.set_deferred("disabled", false)
	_reset_visual_effects()


## Désactivation et mise en sommeil pour le pool
func deactivate() -> void:
	visible = false
	set_physics_process(false)
	set_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var col = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.set_deferred("disabled", true)
	_reset_visual_effects()


func _reset_visual_effects() -> void:
	var trail = get_node_or_null("Trail2D") as Line2D
	if trail:
		trail.clear_points()


## Remet le projectile dans le pool ou le détruit en repli
func release() -> void:
	if not _pool_scene_path.is_empty() and is_instance_valid(ProjectilePool):
		ProjectilePool.return_projectile(self)
	else:
		queue_free()


func shoot(pos: Vector2, angle: float) -> void:
	global_position = pos
	direction = Vector2.DOWN.rotated(angle - PI/2)
	rotation = angle
	_reset_visual_effects()



func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_time_alive += delta
	if lifetime > 0.0 and _time_alive >= lifetime:
		release()


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
	release()

