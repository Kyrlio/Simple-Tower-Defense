extends Node2D

@onready var projectiles: Node2D = $Projectiles


func _ready() -> void:
	GoldManager.add_gold(500)
