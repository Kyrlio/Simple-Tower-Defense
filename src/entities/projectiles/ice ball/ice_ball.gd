extends Projectile
class_name IceBall

var slow_factor: float = 0.5
var slow_duration: float = 2.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var trail_particles: GPUParticles2D = $TrailParticles


func _init() -> void:
	damage_type = "ice"


func reactivate() -> void:
	super.reactivate()
	if trail_particles:
		if not Data.deactivate_particles:
			trail_particles.emitting = true
			trail_particles.restart()
		else:
			trail_particles.emitting = false



func on_hit_target(target: Node2D) -> void:
	if is_instance_valid(target) and target.has_method("apply_slow"):
		target.apply_slow(slow_factor, slow_duration, source_tower)
