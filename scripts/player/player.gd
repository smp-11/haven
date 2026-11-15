extends CharacterBody2D

@onready var timer = $Label2/Timer
@onready var timer_label = $Label2
var can_kick = false

const RUN_SPEED = 700
const RUN_ACCELERATION = 5000
const RUN_DECELERATION = 1000
const JUMP_VELOCITY = -600

const DASH_SPEED = 2000.0
const DASH_DISTANCE = DASH_SPEED * 0.3
const DASH_MAX_BOUNCES = 5
const DASH_COOLDOWN = 1.5
const DASH_COOLDOWN_REDUCTION_PER_BOUNCE = 0.25
const DASH_END_THRESHOLD = 0.001
const DASH_MIN_BOUNCE_APPROACH = -0.1

const AIM_DURATION = 2.0
const MAX_PREVIEW_STEPS = 600
const PREVIEW_WIDTH = 32.0
const COOLDOWN_RING_RADIUS = 50.0
const AIM_RING_RADIUS = 40.0
const RING_START_ANGLE = -PI / 2

const PREVIEW_AREA_COLOR = Color(1, 1, 1, 0.25)
const PREVIEW_LINE_COLOR = Color(1, 1, 1, 0.9)
const RING_BACK_COLOR = Color(1, 1, 1, 0.15)
const COOLDOWN_COLOR = Color.AQUA
const AIM_TIMER_COLOR = Color(1, 1, 1, 0.5)

var health = 100

var is_dashing := false
var dash_direction := Vector2.RIGHT
var dash_remaining := 0.0
var dash_leg_start := Vector2.ZERO
var dash_bounces := 0
var dash_cooldown_left := 0.0
var dash_cooldown_total := DASH_COOLDOWN

var is_aiming := false
var aim_can_confirm := false
var aim_time_left := 0.0
var preview_path := PackedVector2Array()
var preview_bounce_points := PackedVector2Array()

@onready var arrow_pivot = $Arrow_pivot
@onready var health_bar = $ProgressBar


func player() -> void:
	pass

func take_damage(amount):
	health -= amount

func kill():
	get_tree().change_scene_to_file(ResourceManager.title)

func get_mouse_direction() -> Vector2:
	var direction := global_position.direction_to(get_global_mouse_position())
	return direction if direction != Vector2.ZERO else Vector2.RIGHT


func start_dash(direction: Vector2) -> void:
	if dash_cooldown_left > 0.0:
		return
	dash_direction = direction
	dash_remaining = DASH_DISTANCE
	dash_leg_start = global_position
	dash_bounces = 0
	is_dashing = true


func start_aiming() -> void:
	is_aiming = true
	aim_can_confirm = false
	aim_time_left = AIM_DURATION
	get_tree().paused = true

func stop_aiming() -> void:
	is_aiming = false
	get_tree().paused = false
	preview_path.clear()
	preview_bounce_points.clear()

func _preview_move(from_point: Vector2, motion: Vector2) -> KinematicCollision2D:
	var from_transform := global_transform
	from_transform.origin = from_point
	var collision := KinematicCollision2D.new()
	return collision if test_move(from_transform, motion, collision) else null

func _update_preview() -> void:
	preview_path.clear()
	preview_bounce_points.clear()

	var point := global_position
	var direction := get_mouse_direction()
	var leg_start := point
	var remaining := DASH_DISTANCE
	var bounces := 0
	var step_time := 1.0 / Engine.physics_ticks_per_second

	preview_path.append(point)

	for _i in MAX_PREVIEW_STEPS:
		if remaining <= DASH_END_THRESHOLD:
			break

		var distance := minf(DASH_SPEED * step_time, remaining)
		var motion := direction * distance
		var collision := _preview_move(point, motion)

		if collision == null:
			point += motion
			remaining -= distance
		else:
			point += collision.get_travel()
			remaining -= collision.get_travel().length()
			var normal := collision.get_normal()

			if bounces < DASH_MAX_BOUNCES and direction.dot(normal) < DASH_MIN_BOUNCE_APPROACH:
				remaining += point.distance_to(leg_start)
				direction = direction.bounce(normal)
				leg_start = point
				bounces += 1
				preview_bounce_points.append(point)
			else:
				var slide := collision.get_remainder().slide(normal)
				remaining -= slide.length()
				var slide_collision := _preview_move(point, slide)
				point += slide_collision.get_travel() if slide_collision else slide

		preview_path.append(point)

func _update_aiming(delta: float) -> void:
	aim_time_left -= delta

	if not Input.is_action_pressed("dash"):
		aim_can_confirm = true

	if Input.is_action_just_pressed("jump") and is_on_floor():
		stop_aiming()
		velocity.y = JUMP_VELOCITY
	elif aim_can_confirm and Input.is_action_just_pressed("dash"):
		var direction := get_mouse_direction()
		stop_aiming()
		start_dash(direction)
	elif aim_time_left <= 0.0:
		stop_aiming()
	else:
		_update_preview()


func _draw_progress_ring(radius: float, progress: float, color: Color, width: float) -> void:
	draw_arc(Vector2.ZERO, radius, RING_START_ANGLE, RING_START_ANGLE + TAU * progress, 48, color, width, true)

func _draw_cooldown_ring() -> void:
	if dash_cooldown_left <= 0.0:
		return
	var progress := 1.0 - dash_cooldown_left / dash_cooldown_total
	_draw_progress_ring(COOLDOWN_RING_RADIUS, 1.0, RING_BACK_COLOR, 4.0)
	_draw_progress_ring(COOLDOWN_RING_RADIUS, progress, COOLDOWN_COLOR, 4.0)

func _draw_preview() -> void:
	var points := PackedVector2Array()
	for point in preview_path:
		points.append(to_local(point))

	if points.size() > 1:
		draw_polyline(points, PREVIEW_AREA_COLOR, PREVIEW_WIDTH, true)
		draw_polyline(points, PREVIEW_LINE_COLOR, 2.0, true)
		draw_circle(points[points.size() - 1], PREVIEW_WIDTH * 0.5, PREVIEW_AREA_COLOR)

	for point in preview_bounce_points:
		draw_circle(to_local(point), 7.0, Color.ORANGE)

func _draw_crosshair(center: Vector2) -> void:
	draw_arc(center, 14.0, 0.0, TAU, 24, Color.WHITE, 2.0)
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_line(center + direction * 8.0, center + direction * 24.0, Color.WHITE, 2.0)

func _draw_aim_timer() -> void:
	var progress := clampf(aim_time_left / AIM_DURATION, 0.0, 1.0)
	_draw_progress_ring(AIM_RING_RADIUS, progress, AIM_TIMER_COLOR, 3.0)

func _draw() -> void:
	_draw_cooldown_ring()

	if is_aiming:
		_draw_preview()
		_draw_crosshair(to_local(get_global_mouse_position()))
		_draw_aim_timer()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	health_bar.max_value = health

func _process(delta: float) -> void:
	timer_label.text = "Time left: " + str(int(timer.time_left))
	health_bar.value = health
	Global.player_dashing_f(is_dashing)
	arrow_pivot.look_at(get_global_mouse_position())
	arrow_pivot.rotation += deg_to_rad(90)
	queue_redraw()

	if is_aiming:
		_update_aiming(delta)

func _physics_process(delta: float) -> void:
	if is_aiming:
		return

	dash_cooldown_left = maxf(dash_cooldown_left - delta, 0.0)

	if is_dashing:
		var distance := minf(DASH_SPEED * delta, dash_remaining)
		var collision := move_and_collide(dash_direction * distance)

		if collision == null:
			dash_remaining -= distance
		else:
			dash_remaining -= collision.get_travel().length()
			var normal := collision.get_normal()

			if dash_bounces < DASH_MAX_BOUNCES and dash_direction.dot(normal) < DASH_MIN_BOUNCE_APPROACH:
				dash_remaining += global_position.distance_to(dash_leg_start)
				dash_direction = dash_direction.bounce(normal)
				dash_leg_start = global_position
				dash_bounces += 1
			else:
				var slide := collision.get_remainder().slide(normal)
				dash_remaining -= slide.length()
				move_and_collide(slide)

		velocity = dash_direction * DASH_SPEED

		if dash_remaining <= DASH_END_THRESHOLD:
			velocity = dash_direction * RUN_SPEED
			dash_cooldown_total = DASH_COOLDOWN * maxf(1.0 - dash_bounces * DASH_COOLDOWN_REDUCTION_PER_BOUNCE, 0.0)
			dash_cooldown_left = dash_cooldown_total
			is_dashing = false
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0:
		start_aiming()

	var input_direction := Input.get_axis("left", "right")
	var rate := RUN_ACCELERATION if input_direction != 0.0 else RUN_DECELERATION
	velocity.x = move_toward(velocity.x, input_direction * RUN_SPEED, rate * delta)

	move_and_slide()


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file(ResourceManager.title)


func _on_timer_timeout() -> void:
	if can_kick == true:
		get_tree().change_scene_to_file(ResourceManager.title)
	
func start_timer(val):
	can_kick = true
	timer_label.show()
	timer.start(val)
