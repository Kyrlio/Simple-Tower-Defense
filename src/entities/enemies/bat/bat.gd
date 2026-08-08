extends Area2D
class_name Enemy

var path_follow: PathFollow2D

func setup(new_path_follow: PathFollow2D) -> void:
	path_follow = new_path_follow


func _process(delta: float) -> void:
	path_follow.progress += 20 * delta
	if path_follow.progress_ratio >= 0.99:
		print("damage")
		queue_free()


func _on_area_entered(projectile: Area2D) -> void:
	projectile.queue_free()
