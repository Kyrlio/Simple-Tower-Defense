#gdlint: disable=max-line-length
@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("PixelTrailVFX", "Control", preload("res://addons/pixel_trail_vfx/classes/pixel_trail_vfx.gd"), null)


func _exit_tree() -> void:
	remove_custom_type("PixelTrailVFX")