extends Resource
class_name EnemyStats

@export var name: String = "Enemy"
@export var max_hp: float = 10.0
@export var hp: float = 2.0
@export var speed: float = 25.0
@export var attack_speed: float = 3.5
@export var attack_damage: float = 2.0
@export var gold_reward: int = 5

@export_group("Resistances")
@export var physical_resist: float = 0.0
@export var fire_resist: float = 0.0
@export var ice_resist: float = 0.0
@export var poison_resist: float = 0.0
@export var lightning_resist: float = 0.0
