extends CharacterBody3D

@export var speed = 10.0
@export var landmine_scene: PackedScene
@export var max_health = 100

@onready var cannon = $Cannon
@onready var mesh_instance = $MeshInstance3D

var health = max_health

func _ready():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.2, 0.8)  # Blue color
	$MeshInstance3D.material_override = material

	if landmine_scene:
		print("Landmine scene is assigned")
	else:
		print("Landmine scene is NOT assigned")

	add_to_group("tanks")

func _physics_process(delta):
	if is_multiplayer_authority():
		handle_input()
	
	# Lock Y position to prevent vertical movement
	global_position.y = 0.5

func handle_input():
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	var mouse_pos = get_mouse_position()
	var look_dir = (mouse_pos - global_position).normalized()
	look_dir.y = 0
	if look_dir.length() > 0.001:
		look_at(global_position + look_dir, Vector3.UP)

	if Input.is_action_just_pressed("shoot"):
		rpc("shoot")

	if Input.is_action_just_pressed("place_landmine"):
		rpc("place_landmine")

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

@rpc("any_peer", "call_local")
func shoot():
	var projectile = preload("res://scenes/Projectile.tscn").instantiate()
	var spawn_point = cannon.global_position + -cannon.global_transform.basis.z * 1.5
	projectile.set_ignore_body(self)
	get_parent().add_child(projectile, true)
	projectile.global_position = spawn_point
	var shoot_direction = -cannon.global_transform.basis.z
	shoot_direction.y = 0
	projectile.launch(shoot_direction)

@rpc("any_peer", "call_local")
func place_landmine():
	if landmine_scene:
		var landmine = landmine_scene.instantiate()
		get_parent().add_child(landmine, true)
		landmine.global_position = global_position + Vector3(0, 0.1, 0)
		print("Landmine placed at: ", landmine.global_position)
	else:
		print("Landmine scene not assigned!")

@rpc("any_peer", "call_local")
func take_damage(damage):
	health -= damage
	print("Player tank took damage. Health: ", health)
	if health <= 0:
		explode()

func explode():
	var explosion = preload("res://scenes/Explosion.tscn").instantiate()
	get_parent().add_child(explosion, true)
	explosion.global_position = global_position
	visible = false
	await get_tree().create_timer(2.0).timeout
	queue_free()
