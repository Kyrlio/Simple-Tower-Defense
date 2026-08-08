class_name HitboxComponent
extends Area2D

signal hit_hurtbox(hurtbox_component: HurtboxComponent)

@export var damage: int = 1:
	get(): return damage
	set(value): damage = value

var is_hit_handled: bool


func register_hurtbox_hit(hurtbox_component: HurtboxComponent) -> void:
	hit_hurtbox.emit(hurtbox_component)
