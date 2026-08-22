class_name Castle
extends Area2D

@onready var health_component: HealthComponent = $HealthComponent


func _ready() -> void:
	add_to_group("castle")
	
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_castle_destroyed)
	GameEvents.castle_health_changed.emit(health_component.current_health, health_component.max_health)
	
	#_on_health_changed(health_component.max_health, health_component.max_health)


func take_damage(amount: int) -> void:
	health_component.damage(amount)
	


func _on_health_changed(current_health: int, max_health: int) -> void:
	GameEvents.castle_health_changed.emit(current_health, max_health)
	print(current_health)


func _on_castle_destroyed() -> void:
	GameEvents.game_over.emit()
