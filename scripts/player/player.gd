extends CharacterBody2D

const SPEED = 500
const ACCELERATION = 5000
const DECELARATION = 1000

const JUMP_VELOCITY = 500

const DASH_BOUNCE_TIME = 0.12
const MAX_DASH_BOUNCES = 2

const DASH_SPEED = 2000.0
const DASH_TIME = 0.17
const DASH_COOLDOWN = 0.5

const AIM_TIME = 1.0

var facing = 1
var should_jump = false
var should_dash = false

var is_dashing = false
var dash_ticks = 0.0
var dash_cooldown = 0.0
var dash_direction = Vector2.RIGHT
var bounce_count = 0

var is_aiming = false
var aim_ticks = 0.0
var aim_used = false
var prev_velocity_y = 0.0
var predicted_path = PackedVector2Array()
var predicted_bounces = PackedVector2Array()

@onready var arrow = $Arrow_pivot

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _physics_process(delta: float) -> void:
<<<<<<< HEAD
	if is_aiming:
		return
		
	_process_timers(delta)
	
	if is_dashing:
		_process_dash(delta)
=======
	var direction = Input.get_axis("left", "right")

	
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
	
	if not is_on_floor():
		velocity += get_gravity() * delta	
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = -JUMP_VELOCITY
		else:
			dash_timer = DASH_TIME
			dash_direction = get_dash_direction()
			is_dashing = true
			
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * SPEED, delta * ACCELERATION)
>>>>>>> 0170ae052f10f86e80a62be395bcb08e9a716d60
	else:
		_process_gravity(delta)
		_process_input(delta)
		_process_movement(delta)
		
	move_and_slide()
	
	if is_dashing:
		_check_dash_bounce()
	else:
		_check_apex()

	prev_velocity_y = velocity.y

func _process(delta: float) -> void:
	arrow.look_at(get_global_mouse_position())
	arrow.rotation += deg_to_rad(90)
	
	if is_aiming:
		_process_aiming(delta)
	
func get_dash_direction() -> Vector2:
	var input_dir = global_position.direction_to(get_global_mouse_position())
	
	if input_dir != Vector2.ZERO:
		return input_dir
	return Vector2.RIGHT
	
func dashTo(direction: Vector2) -> void:
	if dash_cooldown:
		return;
		
	dash_ticks = DASH_TIME
	dash_direction = direction
	is_dashing = true
	
func jump(jump_velocity: float) -> void:
	velocity.y = -jump_velocity

func _process_dash(delta: float) -> void:
	dash_ticks -= delta
	if dash_ticks > 0:
		velocity = dash_direction * DASH_SPEED
	else:
		dash_ticks = 0;
		velocity = dash_direction * SPEED
		dash_cooldown = DASH_COOLDOWN
		bounce_count = 0
		is_dashing = false

func _process_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func _process_input(delta: float) -> void:
	facing = Input.get_axis("left", "right")
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			should_jump = true
		else:
			should_dash = true

func _process_movement(delta: float) -> void:
	if should_jump:
		jump(JUMP_VELOCITY)
		should_jump = false
	elif should_dash:
		dashTo(get_dash_direction())
		should_dash = false
	
	if facing != 0.0:
		velocity.x = move_toward(velocity.x, facing * SPEED, delta * ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECELARATION * delta)

func _process_timers(delta: float) -> void:
	dash_cooldown = max(dash_cooldown - delta, 0.0)
	if is_on_floor():
		aim_used = false

func _check_dash_bounce() -> void:
	if bounce_count >= MAX_DASH_BOUNCES:
		return

	for i in get_slide_collision_count():
		var normal = get_slide_collision(i).get_normal()

		# Only bounce if we're actually moving into the surface
		if dash_direction.dot(normal) < -0.1:
			dash_direction = dash_direction.bounce(normal)
			dash_ticks += DASH_BOUNCE_TIME
			bounce_count += 1
			return

func _check_apex() -> void:
	if is_on_floor() or aim_used or dash_cooldown > 0.0:
		return
	if prev_velocity_y < 0.0 and velocity.y >= 0.0:
		start_aiming()

func start_aiming() -> void:
	is_aiming = true
	aim_used = true
	aim_ticks = AIM_TIME
	get_tree().paused = true

func stop_aiming() -> void:
	is_aiming = false
	get_tree().paused = false
	predicted_path.clear()
	predicted_bounces.clear()
	queue_redraw()

func _process_aiming(delta: float) -> void:
	aim_ticks -= delta

	if Input.is_action_just_pressed("jump"):
		var dir = get_dash_direction()
		stop_aiming()
		dashTo(dir)
		return

	if aim_ticks <= 0.0:
		stop_aiming()
		return

	_predict_dash_path(get_dash_direction())
	queue_redraw()

func _predict_dash_path(dir: Vector2) -> void:
	predicted_path.clear()
	predicted_bounces.clear()

	var step = 1.0 / Engine.physics_ticks_per_second
	var xform = global_transform
	var time_left = DASH_TIME
	var bounces = 0
	var col = KinematicCollision2D.new()

	predicted_path.append(xform.origin)

	while true:
		time_left -= step
		if time_left <= 0.0:
			break

		var motion = dir * DASH_SPEED * step
		if test_move(xform, motion, col):
			var normal = col.get_normal()
			xform.origin += col.get_travel()
			xform.origin += col.get_remainder().slide(normal)   # slide along the surface

			if bounces < MAX_DASH_BOUNCES and dir.dot(normal) < -0.1:
				dir = dir.bounce(normal)
				time_left += DASH_BOUNCE_TIME
				bounces += 1
				predicted_bounces.append(xform.origin)
		else:
			xform.origin += motion

		predicted_path.append(xform.origin)

	xform.origin += dir * SPEED * step
	predicted_path.append(xform.origin)

func _draw() -> void:
	if not is_aiming:
		return

	if predicted_path.size() > 1:
		var points = PackedVector2Array()
		for p in predicted_path:
			points.append(to_local(p))
		draw_polyline(points, Color(1, 1, 1, 0.8), 2.0)

	for p in predicted_bounces:
		draw_circle(to_local(p), 6.0, Color.ORANGE)

	var m = to_local(get_global_mouse_position())
	draw_arc(m, 14.0, 0.0, TAU, 24, Color.WHITE, 2.0)
	draw_line(m + Vector2(-24, 0), m + Vector2(-8, 0), Color.WHITE, 2.0)
	draw_line(m + Vector2(8, 0), m + Vector2(24, 0), Color.WHITE, 2.0)
	draw_line(m + Vector2(0, -24), m + Vector2(0, -8), Color.WHITE, 2.0)
	draw_line(m + Vector2(0, 8), m + Vector2(0, 24), Color.WHITE, 2.0)

	var ratio = clampf(aim_ticks / AIM_TIME, 0.0, 1.0)
	draw_arc(Vector2.ZERO, 40.0, -PI / 2, -PI / 2 + TAU * ratio, 32, Color(1, 1, 1, 0.5), 3.0)
	
func player() -> void:
	pass
