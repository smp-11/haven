extends Node2D

@onready var star = $Star

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		body.position = Vector2(7141, -626)


func _on_area_2d_body_entered_2(body: Node2D) -> void:
	star.hide()
	star.queue_free()


func _on_area_2d_body_entered_3(body: Node2D) -> void:
	if body.has_method("player"):
		get_tree().change_scene_to_file(ResourceManager.title)
