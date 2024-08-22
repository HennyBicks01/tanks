extends RigidBody3D

@export var speed = 20.0
@export var lifetime = 5.0

var ignore_body: PhysicsBody3D = null
var launch_direction: Vector3 = Vector3.ZERO

func _ready():
	# Set up a timer to destroy the projectile after its lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

	# Add a material to make the projectile visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0)  # Red color
	$MeshInstance3D.material_override = material

	# Lock rotation and movement on Y-axis
	lock_rotation = true
	axis_lock_linear_y = true

	# Set up collision exception with the tank that fired it
	if ignore_body:
		add_collision_exception_with(ignore_body)

	# Apply the launch impulse if it was set
	if launch_direction != Vector3.ZERO:
		apply_central_impulse(launch_direction.normalized() * speed)

func launch(direction: Vector3):
	launch_direction = direction
	if is_inside_tree():
		apply_central_impulse(direction.normalized() * speed)

func _integrate_forces(state):
	# Ensure the projectile stays at its initial Y position
	var current_transform = state.transform
	current_transform.origin.y = 0.5  # Adjust this value based on your desired projectile height
	state.transform = current_transform

func set_ignore_body(body: PhysicsBody3D):
	ignore_body = body
