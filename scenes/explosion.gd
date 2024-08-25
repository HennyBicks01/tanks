extends Node3D

@onready var particles = $GPUParticles3D
@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("explode")
	await animation_player.animation_finished
	queue_free()
