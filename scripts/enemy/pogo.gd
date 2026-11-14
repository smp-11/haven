extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = 500
var player = null
var player_attack = null

@onready var bar = $ProgressBar
@onready var anim = $AnimationPlayer

func _ready() -> void:
	bar.max_value = health

func _process(delta: float) -> void:
	bar.value = health
	if self.health <= 0:
		self.hide()
		self.queue_free()
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if player:
		var dx = player.global_position.x - global_position.x
		if abs(dx) > 5.0:                      # small dead zone to stop jittering
			velocity.x = sign(dx) * SPEED
		else:
			velocity.x = 0
		
		if is_on_floor():
			velocity.y = -JUMP_VELOCITY
			
	move_and_slide()

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player = body
		
func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player = null

var health = 10

func _on_damage_zone_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		if body.is_dashing == false:
			body.take_damage(5)
		else:
			anim.play("damage")
			take_damage(5)
		
func take_damage(val):
	health -= val
