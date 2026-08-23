extends Button
class_name AnimatedButton

var tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	offset_transform_enabled = true
	pivot_offset = size / 2.0 if size != Vector2.ZERO else custom_minimum_size / 2.0
	resized.connect(_on_resized)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_resized() -> void:
	pivot_offset = size / 2.0


func _pressed() -> void:
	SoundManager.play_ui_click()
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "offset_transform_scale", Vector2(1.2, 1.2), 0.65).from(Vector2(0.8, 0.8))


func _on_mouse_entered() -> void:
	if not disabled:
		SoundManager.play_ui_hover()
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "offset_transform_scale", Vector2(1.2, 1.2), 0.2)


func _on_mouse_exited() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "offset_transform_scale", Vector2(1.0, 1.0), 0.4)
