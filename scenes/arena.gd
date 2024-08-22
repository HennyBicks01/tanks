extends Node3D

@export var arena_size = Vector2(70, 40)
@export var border_height = 2.0
@export var border_block_scene: PackedScene

func _ready():
	create_border()

func create_border():
	if not border_block_scene:
		print("Border block scene not set!")
		return

	var half_width = arena_size.x / 2
	var half_depth = arena_size.y / 2

	# Create border along X axis
	for x in range(-half_width, half_width + 1):
		place_border_block(Vector3(x, border_height / 2, -half_depth))
		place_border_block(Vector3(x, border_height / 2, half_depth))

	# Create border along Z axis (excluding corners)
	for z in range(-half_depth + 1, half_depth):
		place_border_block(Vector3(-half_width, border_height / 2, z))
		place_border_block(Vector3(half_width, border_height / 2, z))

func place_border_block(position: Vector3):
	var block = border_block_scene.instantiate()
	add_child(block)
	block.transform.origin = position
	block.scale.y = border_height
