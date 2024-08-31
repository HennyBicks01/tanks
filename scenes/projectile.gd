extends RigidBody3D

@export var speed = 20.0
@export var lifetime = 5.0
@export var damage = 25

var ignore_body: PhysicsBody3D = null
var launch_direction: Vector3 = Vector3.ZERO

func _ready():
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0)  # Red color
	$MeshInstance3D.material_override = material

	lock_rotation = true
	axis_lock_linear_y = true

	if ignore_body:
		add_collision_exception_with(ignore_body)

	if launch_direction != Vector3.ZERO:
		apply_central_impulse(launch_direction.normalized() * speed)

	connect("body_entered", Callable(self, "_on_body_entered"))

func launch(direction: Vector3):
	launch_direction = direction
	if is_inside_tree():
		apply_central_impulse(direction.normalized() * speed)

func _integrate_forces(state):
	var current_transform = state.transform
	current_transform.origin.y = 0.5
	state.transform = current_transform

func set_ignore_body(body: PhysicsBody3D):
	ignore_body = body

func _on_body_entered(body):
	if body != ignore_body and body.is_in_group("tanks"):
		if body.has_method("take_damage"):
			print("Projectile hit tank: ", body.name)
			rpc("apply_damage", body.get_path())
		queue_free()

@rpc("any_peer", "call_local")
func apply_damage(body_path):
	var body = get_node(body_path)
	if body and body.has_method("take_damage"):
		body.take_damage(damage)
