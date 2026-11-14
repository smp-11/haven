extends CharacterBody2D

const SPEED = 500
const ACCELERATION = 5000
const DECELARATION = 1000

const JUMP_VELOCITY = 500

const MAX_DASH_BOUNCES = 2

const DASH_SPEED = 2000.0
const DASH_TIME = 0.17
const DASH_COOLDOWN = 0.5

const AIM_TIME = 1.0

@export var bar_width := 32.0

class DashState:
	var position := Vector2.ZERO
	var direction := Vector2.RIGHT
	var remaining := 0.0
	var leg_start := Vector2.ZERO
	var bounces := 0

var facing = 1
var should_jump = false
var should_dash = false

var is_dashing = false
var dash_cooldown = 0.0
var dash_state: DashState

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
	if is_aiming:
		return

	_process_timers(delta)

	if is_dashing:
		_process_dash(delta)
	else:
		_process_gravity(delta)
		_process_input(delta)
		_process_movement(delta)
		move_and_slide()
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
	if dash_cooldown > 0.0:
		return

	dash_state = DashState.new()
	dash_state.position = global_position
	dash_state.leg_start = global_position
	dash_state.direction = direction
	dash_state.remaining = DASH_SPEED * DASH_TIME
	is_dashing = true

func jump(jump_velocity: float) -> void:
	velocity.y = -jump_velocity

func _move(state: DashState, motion: Vector2, simulate: bool) -> KinematicCollision2D:
	if simulate:
		var xf := global_transform
		xf.origin = state.position
		var col := KinematicCollision2D.new()
		if test_move(xf, motion, col):
			state.position += col.get_travel()
			return col
		state.position += motion
		return null

	var real_col := move_and_collide(motion)
	state.position = global_position
	return real_col

func _advance_dash(state: DashState, step: float, simulate: bool) -> void:
	var distance := minf(DASH_SPEED * step, state.remaining)
	var col := _move(state, state.direction * distance, simulate)

	if col == null:
		state.remaining -= distance
		return

	var normal := col.get_normal()
	state.remaining -= col.get_travel().length()

	if state.bounces < MAX_DASH_BOUNCES and state.direction.dot(normal) < -0.1:
		state.remaining += state.position.distance_to(state.leg_start)
		state.direction = state.direction.bounce(normal)
		state.leg_start = state.position
		state.bounces += 1
		return

	var slide := col.get_remainder().slide(normal)
	state.remaining -= slide.length()
	_move(state, slide, simulate)

func _process_dash(delta: float) -> void:
	_advance_dash(dash_state, delta, false)
	velocity = dash_state.direction * DASH_SPEED

	if dash_state.remaining <= 0.001:
		velocity = dash_state.direction * SPEED
		dash_cooldown = DASH_COOLDOWN
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

	var state := DashState.new()
	state.position = global_position
	state.leg_start = global_position
	state.direction = dir
	state.remaining = DASH_SPEED * DASH_TIME

	var step := 1.0 / Engine.physics_ticks_per_second
	var guard := 0

	predicted_path.append(state.position)

	while state.remaining > 0.001 and guard < 600:
		guard += 1
		var before := state.bounces
		_advance_dash(state, step, true)
		predicted_path.append(state.position)
		if state.bounces > before:
			predicted_bounces.append(state.position)

func _draw() -> void:
	if not is_aiming:
		return

	if predicted_path.size() > 1:
		var points = PackedVector2Array()
		for p in predicted_path:
			points.append(to_local(p))
		draw_polyline(points, Color(1, 1, 1, 0.25), bar_width, true)
		draw_polyline(points, Color(1, 1, 1, 0.9), 2.0, true)
		draw_circle(points[points.size() - 1], bar_width * 0.5, Color(1, 1, 1, 0.35))

	for p in predicted_bounces:
		draw_circle(to_local(p), 7.0, Color.ORANGE)

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
