extends Tower
class_name ArcherTower

@onready var weapon: Sprite2D = $Visuals/Weapon
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _process(delta: float) -> void:
	if enemies.size() > 0:
		weapon.look_at(enemies[0].global_position)


func _on_reload_timer_timeout() -> void:
	if enemies:
		animation_player.play("shoot")
		GameEvents.shoot.emit(weapon.global_position, weapon.rotation, Data.Projectile.ARROW)
