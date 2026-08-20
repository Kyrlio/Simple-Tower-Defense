class_name DifficultyCurve
extends Resource


## Formule : f(x) = base_difficulty + (log_scale * ln(log_growth * x + 1)) + (wave_amplitude * sin(wave_frequency * x))

@export_group("Base Configuration")
@export var base_difficulty: float = 1.0

@export_group("Logarithmic Growth")
## Facteur multiplicateur de la croissance logarithmique (hauteur globale de la courbe)
@export var log_scale: float = 1.5
## Vitesse de la croissance logarithmique initiale (plus la valeur est élevée, plus la courbe grimpe vite au départ)
@export var log_growth: float = 0.3

@export_group("Wavy Oscillations")
## Amplitude des oscillations (hauteur des pics de difficulté et profondeur des creux de récupération)
@export var wave_amplitude: float = 0.35
## Fréquence des vagues de tension (ex: 1.0 signifie qu'une oscillation complète prend environ 6.28 vagues)
@export var wave_frequency: float = 1.05


## Calcule le coefficient multiplicateur de difficulté pour une vague donnée
func get_difficulty_factor(wave_num: int) -> float:
	# On décale wave_num pour commencer à x = 0 pour la vague 1
	var x: float = float(wave_num - 1)
	
	# 1. Composante Logarithmique (croissance globale stable qui s'adoucit en fin de partie)
	# log() dans GDScript est le logarithme népérien (ln)
	var log_part: float = log_scale * log(log_growth * x + 1.0)
	
	# 2. Composante Ondulatoire (génère les phases d'assaut intenses puis de calme)
	var wave_part: float = wave_amplitude * sin(wave_frequency * x)
	
	# 3. Somme finale
	var final_factor: float = base_difficulty + log_part + wave_part
	
	# Protection pour éviter un multiplicateur négatif ou nul sur les vagues de très bas niveau
	return maxf(final_factor, 0.1)
