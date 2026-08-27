extends Node

signal particles_toggled(deactivated: bool)

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

