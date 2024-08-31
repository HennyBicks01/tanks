extends Node3D

@export var explosion_radius = 5.0
@export var damage = 50
@export var fuse_time = 3.0  # Time before the mine explodes

var is_armed = true  # The mine is now armed immediately

@onready var mesh_instance = $MeshInstance3D
@onready var particles = $GPUParticles3D
@onready var animation_player = $AnimationPlayer

func _ready():
	# Add a material to make the landmine visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0)  # Red color to indicate it's armed
	if mesh_instance:
		mesh_instance.material_override = material
		mesh_instance.visible = true  # Ensure the mine is visible when placed
	else:
		print("MeshInstance3D not found in Landmine scene")

	# Set up a timer for explosion
	var timer = get_tree().create_timer(fuse_time)
	timer.timeout.connect(explode)

func explode():
	# Get all bodies in the explosion radius
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = explosion_radius
	query.shape = shape
	query.transform = global_transform
	var results = space_state.intersect_shape(query)

	# Apply damage to bodies in range
	for result in results:
		var body = result["collider"]
		if body.has_method("take_damage"):
			body.take_damage(damage)

	# Play explosion animation
	if animation_player:
		animation_player.play("explosion")
		# Wait for the animation to finish before removing the landmine
		await animation_player.animation_finished
	else:
		print("AnimationPlayer not found in Landmine scene")

	queue_free()

func _on_area_3d_area_entered(area):
	if area.is_in_group("projectiles"):
		explode()
