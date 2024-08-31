extends Node3D

@export var explosion_radius = 5.0
@export var damage = 50
@export var fragment_scene: PackedScene
@export var num_fragments = 10
@export var explosion_force = 10.0

@onready var mesh_instance = $MeshInstance3D
@onready var particles = $GPUParticles3D
@onready var animation_player = $AnimationPlayer

func _ready():
	# Add a material to make the object visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 0, 1)  # Blue color
	if mesh_instance:
		mesh_instance.material_override = material
		mesh_instance.visible = true
	else:
		print("MeshInstance3D not found in ExplodingObject scene")

func explode():
	# Generate fragments
	for i in range(num_fragments):
		var fragment = fragment_scene.instantiate()
		get_parent().add_child(fragment)
		fragment.global_transform = global_transform
		
		# Randomize fragment position slightly
		fragment.translate(Vector3(randf(), randf(), randf()) * 0.5)
		
		# Apply explosion force
		var direction = (fragment.global_transform.origin - global_transform.origin).normalized()
		if fragment is RigidBody3D:
			fragment.apply_central_impulse(direction * explosion_force * randf())

	# Apply damage to nearby bodies
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = explosion_radius
	query.shape = shape
	query.transform = global_transform
	var results = space_state.intersect_shape(query)

	for result in results:
		var body = result["collider"]
		if body.has_method("take_damage"):
			body.take_damage(damage)

	# Play explosion animation
	if animation_player:
		animation_player.play("explosion")
		# Wait for the animation to finish before removing the object
		await animation_player.animation_finished
	else:
		print("AnimationPlayer not found in ExplodingObject scene")

	queue_free()

func _on_area_3d_area_entered(area):
	if area.is_in_group("projectiles"):
		explode()
