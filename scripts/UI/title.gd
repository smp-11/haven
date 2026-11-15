extends Control


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file(ResourceManager.test)

@onready var l1_s1 = $AnimatedSprite2D
@onready var l1_s2 = $AnimatedSprite2D2
@onready var l1_s3 = $AnimatedSprite2D3
@onready var l2_s1 = $AnimatedSprite2D4
@onready var l2_s2 = $AnimatedSprite2D5
@onready var l2_s3 = $AnimatedSprite2D6
@onready var l1_f = $AnimatedSprite2D7
@onready var l2_f = $AnimatedSprite2D8

func _ready() -> void:
	if Global.star1:
		l1_s1.show()
	if Global.star2:
		l1_s2.show()
	if Global.star3:
		l1_s3.show()
	if Global.star4:
		l2_s1.show()
	if Global.star5:
		l2_s2.show()
	if Global.star6:
		l2_s3.show()
	if Global.level1_f:
		l1_f.show()
	if Global.level2_f:
		l2_f.show()


func _on_level_1_pressed() -> void:
	get_tree().change_scene_to_file(ResourceManager.level_1)


func _on_level_2_pressed() -> void:
	get_tree().change_scene_to_file(ResourceManager.level_2)
