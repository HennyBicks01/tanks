extends CharacterBody3D

@export var shoot_interval = 3.0
@export var projectile_scene: PackedScene
@export var max_health = 100

@onready var cannon = $Cannon
@onready var mesh_instance = $MeshInstance3D

var player: Node3D = null
var health = max_health

func _ready():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)  # Red color
	$MeshInstance3D.material_override = material

	var timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", Callable(self, "shoot"))
	timer.set_wait_time(shoot_interval)
	timer.set_one_shot(false)
	timer.start()

	add_to_group("tanks")

func _process(_delta):
	if player:
		look_at(player.global_position, Vector3.UP)
		cannon.look_at(player.global_position, Vector3.UP)

@rpc("any_peer", "call_local")
func shoot():
	if player and projectile_scene:
		var projectile = projectile_scene.instantiate()
		var spawn_point = cannon.global_position + -cannon.global_transform.basis.z * 1.5
		projectile.set_ignore_body(self)
		get_parent().add_child(projectile, true)
		projectile.global_position = spawn_point
		var shoot_direction = (player.global_position - spawn_point).normalized()
		shoot_direction.y = 0
		projectile.launch(shoot_direction)

func set_player(p):
	player = p

@rpc("any_peer", "call_local")
func take_damage(damage):
	health -= damage
	print("Enemy tank took damage. Health: ", health)
	if health <= 0:
		explode()

func explode():
	var explosion = preload("res://scenes/Explosion.tscn").instantiate()
	get_parent().add_child(explosion, true)
	explosion.global_position = global_position
	visible = false
	await get_tree().create_timer(2.0).timeout
	queue_free()
