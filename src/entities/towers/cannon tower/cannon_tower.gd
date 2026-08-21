extends Tower
class_name CannonTower

@export var cannon_scene: PackedScene = preload("res://src/entities/projectiles/cannon/cannon.tscn")
@export var damage: float = 4.0
@export var max_weapon_rotation_degrees: float = 20.0

@onready var muzzle: Marker2D = $Visuals/Weapon/Muzzle
@onready var base_tower: Sprite2D = $Visuals/BaseTower
@onready var weapon: Sprite2D = $Visuals/Weapon
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_target: Node2D = null
var physical_damage_boost: float = 1.35


#func _ready() -> void:
	#reload_timer.timeout.connect(_on_reload_timer_timeout)
	#reload_timer.wait_time = shoot_reload_time
	#scale = Vector2.ZERO
	#var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	#tween.tween_property(self, "scale", Vector2(1, 1), 0.8)


func _physics_process(delta: float) -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	
	if enemies.size() > 0:
		current_target = enemies[0]
		var dir: Vector2 = current_target.global_position - weapon.global_position
		# Calcul de l'angle par rapport au HAUT (Vector2.UP)
		var angle_to_target: float = Vector2.UP.angle_to(dir)
		var max_rad: float = deg_to_rad(max_weapon_rotation_degrees)
		var clamped_angle: float = clampf(angle_to_target, -max_rad, max_rad)
		weapon.rotation = lerp_angle(weapon.rotation, clamped_angle, 10.0 * delta)
	else:
		current_target = null
		weapon.rotation = lerp_angle(weapon.rotation, 0.0, 10.0 * delta)


func _on_reload_timer_timeout() -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	
	if enemies.size() > 0:
		var target: Node2D = enemies[0]
		animation_player.play("shoot")
		
		if cannon_scene:
			var cannon_instance = cannon_scene.instantiate() as Cannon
			if cannon_instance:
				get_tree().current_scene.add_child(cannon_instance)
				cannon_instance.launch(muzzle.global_position, target, damage)
