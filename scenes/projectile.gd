extends RigidBody3D

@export var speed = 20.0
@export var lifetime = 5.0

func _ready():
	# Set up a timer to destroy the projectile after its lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

	# Add a material to make the projectile visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0)  # Red color
	$MeshInstance3D.material_override = material

func launch(direction: Vector3):
	apply_central_impulse(direction.normalized() * speed)
