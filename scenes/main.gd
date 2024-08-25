extends Node3D

@onready var arena = $Arena

var player_tank = null
var enemy_tank = null

func _ready():
	setup_game()

func setup_game():
	spawn_player_tank()
	spawn_enemy_tank()

func spawn_player_tank():
	var tank_scene = preload("res://scenes/Tank.tscn")
	player_tank = tank_scene.instantiate()
	player_tank.position = Vector3(-10, 0, 0)  # Spawn on the left side
	add_child(player_tank)

func spawn_enemy_tank():
	var enemy_tank_scene = preload("res://scenes/Enemy.tscn")
	enemy_tank = enemy_tank_scene.instantiate()
	enemy_tank.position = Vector3(10, 0, 0)  # Spawn on the right side
	add_child(enemy_tank)
	
	# Set the player reference for the enemy tank
	enemy_tank.set_player(player_tank)

func _physics_process(_delta):
	# Clean up projectiles that have gone too far
	for child in get_children():
		if child is RigidBody3D and child.global_position.length() > 100:
			child.queue_free()
