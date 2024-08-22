extends Node3D

@onready var arena = $Arena

func _ready():
	setup_game()

func setup_game():
	spawn_tank()

func spawn_tank():
	var tank_scene = preload("res://scenes/Tank.tscn")
	var tank = tank_scene.instantiate()
	tank.position = Vector3.ZERO  # Spawn at the center (0, 0, 0)
	add_child(tank)

	# Make the camera follow the tank
	$Camera3D.position = tank.position + Vector3(0, 15, 10)
	$Camera3D.look_at(tank.position, Vector3.UP)

func _physics_process(delta):
	# Clean up projectiles that have gone too far
	for child in get_children():
		if child is RigidBody3D and child.global_position.length() > 100:
			child.queue_free()
