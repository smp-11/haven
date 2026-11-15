extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = 500
var player = null

@onready var bar = $ProgressBar
@onready var anim = $AnimationPlayer

func _ready() -> void:
	bar.max_value = health

func _process(delta: float) -> void:
	bar.value = health
	if self.health <= 0:
		self.hide()
		self.queue_free()


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
