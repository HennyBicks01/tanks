extends CharacterBody3D
@export var speed = 10.0
@onready var cannon = $Cannon

var projectile_scene = preload("res://scenes/Projectile.tscn")
var mine_scene = preload("res://scenes/Landmine.tscn")  # Make sure this path is correct

func _ready():
	# Add a material to make the tank visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.2, 0.8)  # Blue color
	$MeshInstance3D.material_override = material

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
	
	if Input.is_action_just_pressed("place_landmine"):  # Changed from "lay_mine" to "place_landmine"
		place_landmine()  # Changed function name for consistency

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
	rpc("spawn_projectile")

@rpc("any_peer", "call_local")
func spawn_projectile():
	var projectile = projectile_scene.instantiate()
	var spawn_point = cannon.global_position + -cannon.global_transform.basis.z * 1.5
	projectile.set_ignore_body(self)  # Set the tank as the body to ignore
	get_parent().add_child(projectile)
	projectile.global_position = spawn_point
	var shoot_direction = -cannon.global_transform.basis.z
	shoot_direction.y = 0  # Ensure projectile moves only in X-Z plane
	projectile.launch(shoot_direction)

func place_landmine():  # Changed function name for consistency
	rpc("spawn_mine")

@rpc("any_peer", "call_local")
func spawn_mine():
	var mine = mine_scene.instantiate()
	var spawn_point = global_position - global_transform.basis.z * 2  # Spawn behind the tank
	spawn_point.y = 0.1  # Slightly above the ground
	get_parent().add_child(mine)
	mine.global_position = spawn_point
