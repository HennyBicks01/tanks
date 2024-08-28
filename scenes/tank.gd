extends CharacterBody3D

@export var speed = 10.0
@export var landmine_scene: PackedScene
@export var max_health = 100

@onready var cannon = $Cannon
@onready var mesh_instance = $MeshInstance3D

var health = max_health

func _ready():
	# Add a material to make the tank visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.2, 0.8)  # Blue color
	$MeshInstance3D.material_override = material

	# Debug: Check if landmine_scene is assigned
	if landmine_scene:
		print("Landmine scene is assigned")
	else:
		print("Landmine scene is NOT assigned")

	# Add to tanks group
	add_to_group("tanks")

func _physics_process(_delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# Rotate towards mouse position
	var mouse_pos = get_mouse_position()
	var look_dir = (mouse_pos - global_position).normalized()
	look_dir.y = 0  # Ensure the tank only rotates on the X-Z plane
	if look_dir.length() > 0.001:
		look_at(global_position + look_dir, Vector3.UP)

	if Input.is_action_just_pressed("shoot"):
		shoot()

	if Input.is_action_just_pressed("place_landmine"):
		place_landmine()

func get_mouse_position():
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(ray_query)
	if result:
		return result.position
	return to

func shoot():
	var projectile = preload("res://scenes/Projectile.tscn").instantiate()
	var spawn_point = cannon.global_position + -cannon.global_transform.basis.z * 1.5
	projectile.set_ignore_body(self)  # Set the tank as the body to ignore
	get_parent().add_child(projectile)
	projectile.global_position = spawn_point
	var shoot_direction = -cannon.global_transform.basis.z
	shoot_direction.y = 0  # Ensure projectile moves only in X-Z plane
	projectile.launch(shoot_direction)

func place_landmine():
	if landmine_scene:
		var landmine = landmine_scene.instantiate()
		get_parent().add_child(landmine)
		landmine.global_position = global_position + Vector3(0, 0.1, 0)
		print("Landmine placed at: ", landmine.global_position)
	else:
		print("Landmine scene not assigned!")

func take_damage(damage):
	health -= damage
	print("Player tank took damage. Health: ", health)  # Debug print
	if health <= 0:
		explode()

func explode():
	# Instantiate and play the explosion
	var explosion = preload("res://scenes/Explosion.tscn").instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position

	# Hide the tank immediately
	visible = false

	# Wait for the explosion animation to finish
	await get_tree().create_timer(2.0).timeout

	# Remove the tank
	queue_free()
