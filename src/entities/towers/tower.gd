extends Node2D
class_name Tower

@export var shoot_reload_time: float = 1.0

@onready var reload_timer: Timer = $ReloadTimer

var enemies: Array


func _ready() -> void:
	reload_timer.wait_time = shoot_reload_time
	scale = Vector2.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.8)


func _physics_process(_delta: float) -> void:
	print(enemies)


func _on_enemy_detection_area_area_entered(area: Area2D) -> void:
	if area not in enemies:
		enemies.append(area)


func _on_enemy_detection_area_area_exited(area: Area2D) -> void:
	if area in enemies:
		enemies.erase(area)
