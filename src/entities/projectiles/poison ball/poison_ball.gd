extends Projectile
class_name PoisonBall

var poison_damage: float = 1.0
var poison_duration: float = 3.0
var poison_tick_interval: float = 0.5

@onready var sprite: Sprite2D = $Sprite2D
@onready var trail_particles: GPUParticles2D = $TrailParticles


func _init() -> void:
	damage_type = "poison"


func reactivate() -> void:
	super.reactivate()
	if trail_particles:
		if not Data.deactivate_particles:
			trail_particles.emitting = true
			trail_particles.restart()
		else:
			trail_particles.emitting = false



func on_hit_target(target: Node2D) -> void:
	if is_instance_valid(target) and target.has_method("apply_poison"):
		target.apply_poison(poison_damage, poison_duration, poison_tick_interval, source_tower)
