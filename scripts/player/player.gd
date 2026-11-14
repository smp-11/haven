extends CharacterBody2D

const SPEED = 500
const ACCELERATION = 5000
const DECELARATION = 1000

const JUMP_VELOCITY = 500

const DASH_SPEED = 1200.0
const DASH_TIME = 0.15
const DASH_COOLDOWN = 0.5

var can_dash = true
var is_dashing = false
var dash_timer = 0.0
var cooldown_timer = 0.0
var dash_direction = 1.0
var facing = 1.0

@onready var arrow = $Arrow_pivot

func _physics_process(delta: float) -> void:
	var direction = Input.get_axis("left", "right")
	#cooldown_timer = max(cooldown_timer - delta, 0.0)
	
	#if is_dashing:
		#velocity.x = move_toward(velocity.x, direction * DASH_SPEED, delta * DASH_TIME)
	
	#Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta	
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = -JUMP_VELOCITY
		#else:
			#is_dashing = true
			
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * SPEED, delta * ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECELARATION * delta)
	
	move_and_slide()

func _process(delta: float) -> void:
	arrow.look_at(get_global_mouse_position())
	arrow.rotation += deg_to_rad(90) 

func player() -> void:
	pass
