class_name HealthBar
extends Control

@export var back_bar: TextureProgressBar
@export var front_bar: TextureProgressBar

@export var is_health: bool = true
@export var low_hp_pulse: bool = true
@export var damage_shake: bool = true

var current_pct: float = 1.0
var _is_initialized: bool = false

var front_tween: Tween
var back_tween: Tween
var pulse_tween: Tween = null
var flash_tween: Tween = null
var shake_tween: Tween = null


func update_bar(current: float, max_value: float) -> void:
	if max_value <= 0.0:
		return
		
	var pct: float = clamp(current / max_value, 0.0, 1.0)
	
	front_bar.max_value = max_value
	back_bar.max_value = max_value
	
	if not _is_initialized:
		_is_initialized = true
		current_pct = pct
		front_bar.value = current
		back_bar.value = current
		if is_health:
			_check_low_hp_pulse(pct)
		return
	
	var is_damage: bool = pct < current_pct
	var is_heal: bool = pct > current_pct
	
	if is_damage:
		if front_tween and front_tween.is_running():
			front_tween.kill()
		if back_tween and back_tween.is_running():
			back_tween.kill()
		
		front_bar.value = current
		
		back_tween = create_tween()
		back_tween.tween_property(back_bar, "value", current, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_on_damaged()
		
	elif is_heal:
		if front_tween and front_tween.is_running():
			front_tween.kill()
		if back_tween and back_tween.is_running():
			back_tween.kill()
		
		front_tween = create_tween().set_parallel()
		front_tween.tween_property(front_bar, "value", current, 0.25)
		front_tween.tween_property(back_bar, "value", current, 0.25)
		_on_heal()
	else:
		front_bar.value = current
		back_bar.value = current
	
	current_pct = pct
	
	if is_health:
		_check_low_hp_pulse(pct)


func _shake() -> void:
	if shake_tween and shake_tween.is_running():
		shake_tween.kill()
		
	shake_tween = create_tween()
	shake_tween.tween_property(self, "offset_transform_position", Vector2(2, 0), 0.04)
	shake_tween.tween_property(self, "offset_transform_position", Vector2(-2, 0), 0.04)
	shake_tween.tween_property(self, "offset_transform_position", Vector2.ZERO, 0.04)


func _flash(flash_color: Color) -> void:
	if flash_tween and flash_tween.is_running():
		flash_tween.kill()
		
	modulate = flash_color
	flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1), 0.2)


func _on_damaged() -> void:
	_flash(Color(1.3, 0.6, 0.6))
	if damage_shake:
		_shake()


func _on_heal() -> void:
	_flash(Color(0.6, 1.3, 0.6))


func _check_low_hp_pulse(pct: float) -> void:
	if is_health and low_hp_pulse and pct < 0.25 and pct > 0.0:
		if pulse_tween == null or not pulse_tween.is_running():
			if pulse_tween:
				pulse_tween.kill()
				
			pulse_tween = create_tween()
			pulse_tween.set_loops()
			pulse_tween.tween_property(self, "offset_transform_scale", Vector2(1.04, 1.04), 0.2)
			pulse_tween.tween_property(self, "offset_transform_scale", Vector2(1.00, 1.00), 0.2)
	else:
		if pulse_tween and pulse_tween.is_running():
			pulse_tween.kill()
			pulse_tween = null
		offset_transform_scale = Vector2.ONE
