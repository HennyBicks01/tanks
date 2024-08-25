extends CharacterBody3D

@export var shoot_interval = 3.0
@export var projectile_scene: PackedScene

@onready var cannon = $Cannon

var player: Node3D = null

func _ready():
	# Add a material to make the enemy tank visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)  # Red color
	$MeshInstance3D.material_override = material

	# Start the shooting timer
	var timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", Callable(self, "shoot"))
	timer.set_wait_time(shoot_interval)
	timer.set_one_shot(false)
	timer.start()

func _process(_delta):
	if player:
		# Make the enemy tank look at the player
		look_at(player.global_position, Vector3.UP)
		# Adjust the cannon to aim at the player
		cannon.look_at(player.global_position, Vector3.UP)

func shoot():
	if player and projectile_scene:
		var projectile = projectile_scene.instantiate()
		var spawn_point = cannon.global_position + -cannon.global_transform.basis.z * 1.5
		projectile.set_ignore_body(self)
		get_parent().add_child(projectile)
		projectile.global_position = spawn_point
		var shoot_direction = (player.global_position - spawn_point).normalized()
		shoot_direction.y = 0  # Ensure projectile moves only in X-Z plane
		projectile.launch(shoot_direction)

func set_player(p):
	player = p
