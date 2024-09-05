extends Node3D

@export var arena_size = Vector2(70, 40)
@export var border_height = 2.0
@export var border_block_scene: PackedScene

var wave_function_collapse = preload("res://scripts/wave_function_collapse.gd").new()
var current_map = null

func _ready():
	wave_function_collapse.initialize(arena_size)

func generate_new_map():
	# Remove the old map
	var old_map = get_node_or_null("GeneratedMap")
	if old_map:
		old_map.queue_free()
		# Wait for the next frame to ensure the old map is fully removed
		await get_tree().process_frame

	# Generate the new map
	current_map = wave_function_collapse.generate_map()
	if current_map == null:
		print("Failed to generate map")
		return
	
	var map_3d = create_3d_map(current_map)
	
	add_child(map_3d)
	map_3d.name = "GeneratedMap"

func create_3d_map(map):
	var scene = Node3D.new()
	var wall_mesh = BoxMesh.new()
	var wall_height = 1.5
	wall_mesh.size = Vector3(wave_function_collapse.TILE_SIZE, wall_height, wave_function_collapse.TILE_SIZE)
	
	var offset_x = (wave_function_collapse.MAP_SIZE_X * wave_function_collapse.TILE_SIZE) / 2
	var offset_z = (wave_function_collapse.MAP_SIZE_Z * wave_function_collapse.TILE_SIZE) / 2
	
	for x in range(wave_function_collapse.MAP_SIZE_X):
		for z in range(wave_function_collapse.MAP_SIZE_Z):
			if map[x][z] != "empty":
				var wall = MeshInstance3D.new()
				wall.mesh = wall_mesh
				wall.position = Vector3(
					x * wave_function_collapse.TILE_SIZE - offset_x,
					wall_height / 2,
					z * wave_function_collapse.TILE_SIZE - offset_z
				)
				
				var static_body = StaticBody3D.new()
				var collision_shape = CollisionShape3D.new()
				var box_shape = BoxShape3D.new()
				box_shape.size = Vector3(wave_function_collapse.TILE_SIZE, wall_height, wave_function_collapse.TILE_SIZE)
				collision_shape.shape = box_shape
				static_body.add_child(collision_shape)
				wall.add_child(static_body)
				
				scene.add_child(wall)
	
	return scene

func find_spawn_position():
	return wave_function_collapse.find_spawn_position(current_map)

func get_world_position(map_position: Vector2) -> Vector3:
	var offset_x = (wave_function_collapse.MAP_SIZE_X * wave_function_collapse.TILE_SIZE) / 2
	var offset_z = (wave_function_collapse.MAP_SIZE_Z * wave_function_collapse.TILE_SIZE) / 2
	return Vector3(
		map_position.x * wave_function_collapse.TILE_SIZE - offset_x,
		0.5,
		map_position.y * wave_function_collapse.TILE_SIZE - offset_z
	)
