class_name DifficultyCurve
extends Resource


## Formule : f(x) = base_difficulty + (log_scale * ln(log_growth * x + 1)) + (wave_amplitude * sin(wave_frequency * x))

@export_group("Base Configuration")
@export var base_difficulty: float = 1.0
## Croissance linéaire par vague (ex: 0.15 = +15% de base par vague)
@export var linear_growth: float = 0.15

@export_group("Growth Settings")
## Facteur exponentiel doux (1.0 = purement linéaire, 1.05 = accélération très légère en très haute vague)
@export var exponential_power: float = 1.05
@export var exponential_scale: float = 0.01

@export_group("Wavy Oscillations")
## Amplitude des oscillations (hauteur des pics de difficulté et profondeur des creux de récupération)
@export var wave_amplitude: float = 0.25
## Fréquence des vagues de tension (ex: 0.8 pour des cycles progressifs réguliers)
@export var wave_frequency: float = 0.8


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
