extends CharacterBody2D

const speed = 500
const JUMP_VELOCITY = 400

			
func _physics_process(delta: float) -> void:
	if not is_on_floor():
			velocity += get_gravity() * delta 
		
	if Input.is_action_pressed("left"):
		velocity.x = -1 * speed
		
	elif Input.is_action_pressed("right"):
		velocity.x = 1 * speed
	elif Input.is_action_pressed("jump"):
		if is_on_floor():
			print("o")
			velocity.y = JUMP_VELOCITY * -1
	else:
		velocity.x = 0
	move_and_slide()
