extends Node2D

@onready var star = $Star
@onready var star2 = $Star2
@onready var star3 = $Star3
@onready var sound = $CharacterBody2D/AudioStreamPlayer2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		body.position = Vector2(897, -248)


func _on_area_2d_body_entered_2(body: Node2D) -> void:
	if body.has_method("player"):
		sound.play()
		Global.collect_star(1)
		star.hide()
		star.queue_free()


func _on_area_2d_body_entered_3(body: Node2D) -> void:
	if body.has_method("player"):
		sound.play()
		Global.finish_level(1)
		get_tree().change_scene_to_file(ResourceManager.title)


func _on_area_2d_body_entered_star2(body: Node2D) -> void:
	if body.has_method("player"):
		sound.play()
		Global.collect_star(2)
		star2.hide()
		star2.queue_free()


func _on_area_2d_body_entered_star3(body: Node2D) -> void:
	if body.has_method("player"):
		sound.play()
		Global.collect_star(3)
		star3.hide()
		star3.queue_free()
