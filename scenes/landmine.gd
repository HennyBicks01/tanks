extends Node3D

@export var explosion_radius = 5.0
@export var damage = 50
@export var fragment_force = 10.0
@export var fuse_time = 3.0
@export var fragment_explosion_delay = 0.1

var is_armed = true

@onready var fragments = $Fragments
@onready var collision_shape = $Area3D/CollisionShape3D

func _ready():
	# Make fragments visible immediately
	fragments.visible = true
	
	# Set up timer for explosion
	var timer = get_tree().create_timer(fuse_time)
	timer.timeout.connect(trigger_explosion)

func trigger_explosion():
	if not is_armed:
		return

	is_armed = false
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

	collision_shape.disabled = true  # Disable collision after explosion

	# Set up timer for fragment explosion
	var fragment_timer = get_tree().create_timer(fragment_explosion_delay)
	fragment_timer.timeout.connect(explode_fragments)

func explode_fragments():
	for fragment in fragments.get_children():
		if fragment is MeshInstance3D:
			var rigid_body = RigidBody3D.new()
			var fragment_collision_shape = CollisionShape3D.new()
			var shape = ConvexPolygonShape3D.new()
			
			shape.set_points(fragment.mesh.get_faces())
			fragment_collision_shape.shape = shape
			
			rigid_body.add_child(fragment_collision_shape)
			fragment.get_parent().remove_child(fragment)
			rigid_body.add_child(fragment)
			add_child(rigid_body)
			
			rigid_body.global_transform = fragment.global_transform
			fragment.transform = Transform3D.IDENTITY
			
			var direction = (rigid_body.global_position - global_position).normalized()
			rigid_body.apply_central_impulse(direction * fragment_force)

	# Remove the original fragments node
	fragments.queue_free()

	# Set a timer to remove the landmine after the explosion
	var cleanup_timer = get_tree().create_timer(5.0)  # Adjust time as needed
	cleanup_timer.timeout.connect(queue_free)

func _on_area_3d_area_entered(area):
	if area.is_in_group("projectiles") and is_armed:
		trigger_explosion()
