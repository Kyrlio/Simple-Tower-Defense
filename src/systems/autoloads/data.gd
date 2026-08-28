extends Node

signal particles_toggled(deactivated: bool)
signal enemy_debug_labels_toggled(show_labels: bool)

enum Tower {ARCHER, CANNON, CROSSBOW, ICE_WIZARD, LIGHTNING, POISON_WIZARD}
enum Enemy {BAT, SLIME, BIG_SLIME, KING_SLIME, DEMON, GHOST, GOBLIN, SKELETON, ZOMBIE}

## Si vrai, aucune particule n'est instanciée ou émise dans le jeu pour maximiser les performances
var deactivate_particles: bool = false:
	set(value):
		if deactivate_particles != value:
			deactivate_particles = value
			particles_toggled.emit(value)

var particles_enabled: bool:
	get:
		return not deactivate_particles

## If true, displays enemy info labels (speed, hp, cur_hp)
var show_enemy_debug_labels: bool = false:
	set(value):
		if show_enemy_debug_labels != value:
			show_enemy_debug_labels = value
			enemy_debug_labels_toggled.emit(value)

## --- Paramètres personnalisables du Wave Manager / Difficulté ---
const DEFAULT_WAVE_SETTINGS: Dictionary = {
	"base_difficulty": 1.0,
	"linear_growth": 0.15,
	"base_enemy_count": 4,
	"max_enemies_per_spawner": 80,
	"wave_timer_multiplier": 1.015,
	"max_wave_wait_time": 22.0,
	"spawner_start_wave_ratio": 0.2,
	"exponential_power": 1.05,
	"gold_scale_influence": 0.2,
}

var wave_settings: Dictionary = DEFAULT_WAVE_SETTINGS.duplicate()

func get_wave_setting(key: String, default_val: Variant = null) -> Variant:
	return wave_settings.get(key, default_val)

func set_wave_setting(key: String, value: Variant) -> void:
	wave_settings[key] = value

func reset_wave_setting(key: String) -> void:
	if DEFAULT_WAVE_SETTINGS.has(key):
		wave_settings[key] = DEFAULT_WAVE_SETTINGS[key]

func reset_all_wave_settings() -> void:
	wave_settings = DEFAULT_WAVE_SETTINGS.duplicate()
