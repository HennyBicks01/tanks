extends CharacterBody3D

@export var shoot_interval = 3.0
@export var projectile_scene: PackedScene
@export var max_health = 100

@onready var cannon = $Cannon
@onready var mesh_instance = $MeshInstance3D

var player: Node3D = null
var health = max_health

func _ready():
	# Add a material to make the enemy tank visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)  # Red color
	$MeshInstance3D.material_override = material

	# Start the shooting timer
	var timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", Callable(self, "shoot"))
	timer.set_wait_time(shoot_interval)
	timer.set_one_shot(false)
	timer.start()

	# Add to tanks group
	add_to_group("tanks")

func _process(_delta):
	if player:
		# Make the enemy tank look at the player
		look_at(player.global_position, Vector3.UP)
		# Adjust the cannon to aim at the player
		cannon.look_at(player.global_position, Vector3.UP)

func shoot():
	if player and projectile_scene:
		var projectile = projectile_scene.instantiate()
		var spawn_point = cannon.global_position + -cannon.global_transform.basis.z * 1.5
		projectile.set_ignore_body(self)
		get_parent().add_child(projectile)
		projectile.global_position = spawn_point
		var shoot_direction = (player.global_position - spawn_point).normalized()
		shoot_direction.y = 0  # Ensure projectile moves only in X-Z plane
		projectile.launch(shoot_direction)

func set_player(p):
	player = p

func take_damage(damage):
	health -= damage
	print("Enemy tank took damage. Health: ", health)  # Debug print
	if health <= 0:
		explode()

func explode():
	# Play explosion animation
	var explosion = preload("res://scenes/Explosion.tscn").instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position

	# Hide the tank mesh
	mesh_instance.visible = false

	# Wait for the explosion animation to finish
	await get_tree().create_timer(2.0).timeout

	# Remove the tank
	queue_free()
