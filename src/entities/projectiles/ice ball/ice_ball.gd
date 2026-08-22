extends Projectile
class_name IceBall

@export_group("Freeze / Slow")
## Facteur de vitesse pendant le ralentissement (0.5 = 50% de la vitesse normale de l'ennemi)
@export_range(0.0, 1.0, 0.05) var slow_factor: float = 0.5
## Durée en secondes pendant laquelle l'ennemi reste ralenti
@export var slow_duration: float = 2.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var trail_particles: GPUParticles2D = $TrailParticles


func _init() -> void:
	damage_type = "ice"


func on_hit_target(target: Node2D) -> void:
	if is_instance_valid(target) and target.has_method("apply_slow"):
		target.apply_slow(slow_factor, slow_duration)

func _on_max_targets_reached() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	# Masquer le boulet et l'ombre immédiatement
	sprite.visible = false
	if $CollisionShape2D:
		$CollisionShape2D.set_deferred("disabled", true)
	
	
	# Stopper l'émission (les particules existantes continuent leur vie)
	if trail_particles and is_instance_valid(trail_particles):
		trail_particles.emitting = false
	
	# Attendre que les dernières particules disparaissent avant de libérer le nœud
	var wait_time: float = trail_particles.lifetime if trail_particles else 0.0
	get_tree().create_timer(wait_time + 0.1).timeout.connect(queue_free)
