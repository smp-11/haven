extends CharacterBody2D

const speed = 500
const JUMP_VELOCITY = 500

@onready var arrow = $Arrow_pivot

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta 
	elif Input.is_action_pressed("jump"):
			velocity.y = JUMP_VELOCITY * -1
		
	if Input.is_action_pressed("left"):
		velocity.x = -1 * speed
		
	elif Input.is_action_pressed("right"):
		velocity.x = 1 * speed
	else:
		velocity.x = 0
	
	move_and_slide()

func _process(delta: float) -> void:
	arrow.look_at(get_global_mouse_position())
	arrow.rotation += deg_to_rad(90) 
	
