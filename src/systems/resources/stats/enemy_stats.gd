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
## 0.0 = 0% de résistance, 1.0 = 100% de résistance, -0.5 = +50% dégâts reçus (vulnérabilité)
@export_range(-1.0, 1.0, 0.05) var physical_resist: float = 0.0
@export_range(-1.0, 1.0, 0.05) var fire_resist: float = 0.0
@export_range(-1.0, 1.0, 0.05) var ice_resist: float = 0.0
@export_range(-1.0, 1.0, 0.05) var poison_resist: float = 0.0
@export_range(-1.0, 1.0, 0.05) var lightning_resist: float = 0.0
