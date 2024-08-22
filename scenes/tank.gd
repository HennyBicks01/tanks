extends CharacterBody3D

@export var speed = 10.0

@onready var cannon = $Cannon

func _ready():
	# Add a material to make the tank visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.2, 0.8)  # Blue color
	$MeshInstance3D.material_override = material

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# Rotate towards mouse position
	var mouse_pos = get_mouse_position()
	look_at(mouse_pos, Vector3.UP)

	if Input.is_action_just_pressed("shoot"):
		shoot()

func get_mouse_position():
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 1000
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space_state = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(ray_query)
	if result:
		return result.position
	return to

func shoot():
	var projectile = preload("res://scenes/Projectile.tscn").instantiate()
	projectile.global_transform = cannon.global_transform
	get_parent().add_child(projectile)
	projectile.launch(cannon.global_transform.basis.z)
