extends CharacterBody2D

const SPEED = 500
const ACCELERATION = 5000
const DECELARATION = 1000

const JUMP_VELOCITY = 500

const DASH_SPEED = 2000.0
const DASH_TIME = 0.17
const DASH_COOLDOWN = 0.5

var can_dash = true
var is_dashing = false
var dash_timer = 0.0
var cooldown_timer = 0.0
var dash_direction = Vector2.RIGHT

@onready var arrow = $Arrow_pivot

func _physics_process(delta: float) -> void:
	var direction = Input.get_axis("left", "right")
	#if
	#cooldown_timer = max(cooldown_timer - delta, 0.0)
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer > 0:
			velocity = dash_direction * DASH_SPEED
		else:
			dash_timer = 0;
			is_dashing = false
			velocity = dash_direction * SPEED 
		move_and_slide()
		return
	
	#Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta	
	
	if Input.is_action_just_pressed("jump"):
		print(is_on_floor())
		if is_on_floor():
			velocity.y = -JUMP_VELOCITY
		else:
			dash_timer = DASH_TIME
			dash_direction = get_dash_direction()
			is_dashing = true
			
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * SPEED, delta * ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECELARATION * delta)
	
	move_and_slide()

func _process(delta: float) -> void:
	arrow.look_at(get_global_mouse_position())
	arrow.rotation += deg_to_rad(90)
	
func get_dash_direction() -> Vector2:
	var input_dir = global_position.direction_to(get_global_mouse_position())
	
	if input_dir != Vector2.ZERO:
		return input_dir
	return Vector2.RIGHT
		 

func player() -> void:
	pass
