extends CharacterBody2D

var player = null
var can_attack = false
var target_position

@onready var timer = $Cooldown
@onready var anim = $AnimatedSprite2D

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player = body
		
func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player = null
	
func _process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta 
	if player:
		if can_attack:
			global_position = global_position.move_toward(target_position, 500 * delta)
			if global_position.is_equal_approx(target_position):
				timer.start(2)
				can_attack = false
		else:
			rotation += deg_to_rad(90)
			look_at(player.global_position)
			target_position = player.position

func _on_cooldown_timeout() -> void:
	if player:
		can_attack = true
	else:
		timer.start(2)

func _ready():
	timer.start(2)
	anim.play()
