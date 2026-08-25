class_name DifficultyCurve
extends Resource


## Formule : f(x) = base_difficulty + (log_scale * ln(log_growth * x + 1)) + (wave_amplitude * sin(wave_frequency * x))

@export_group("Base Configuration")
@export var base_difficulty: float = 1.0
## Croissance par vague (ex: 0.25 = +25% de base par vague)
@export var linear_growth: float = 0.25

@export_group("Growth Settings")
## Facteur exponentiel pour faire exploser la difficulté en mid/late game
@export var exponential_power: float = 1.2
@export var exponential_scale: float = 0.08

@export_group("Wavy Oscillations")
## Amplitude des oscillations (hauteur des pics de difficulté et profondeur des creux de récupération)
@export var wave_amplitude: float = 0.35
## Fréquence des vagues de tension (ex: 1.0 signifie qu'une oscillation complète prend environ 6.28 vagues)
@export var wave_frequency: float = 1.05


## Calcule le coefficient multiplicateur de difficulté pour une vague donnée
func get_difficulty_factor(wave_num: int) -> float:
	var x: float = float(wave_num - 1)
	
	# Croissance linéaire de base + accélération exponentielle
	var linear_part: float = linear_growth * x
	var expo_part: float = exponential_scale * pow(x, exponential_power)
	
	# Oscillations de tension / répit
	var wave_part: float = wave_amplitude * sin(wave_frequency * x)
	
	var final_factor: float = base_difficulty + linear_part + expo_part + wave_part
	return maxf(final_factor, 0.1)
