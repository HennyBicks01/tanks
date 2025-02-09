extends CharacterBody3D

signal enemy_destroyed

@export var shoot_interval = 3.0
@export var projectile_scene: PackedScene
@export var max_health = 1

@onready var cannon = $Cannon
@onready var mesh_instance = $MeshInstance3D

var player: Node3D = null
var health = max_health
var target_player_id: int = 0
var is_exploding = false

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
	if is_multiplayer_authority():
		if player:
			look_at(player.global_position, Vector3.UP)
			cannon.look_at(player.global_position, Vector3.UP)
		rpc("sync_rotation", rotation, cannon.rotation)

@rpc("any_peer", "call_local")
func sync_rotation(enemy_rotation, cannon_rotation):
	if not is_multiplayer_authority():
		rotation = enemy_rotation
		cannon.rotation = cannon_rotation

@rpc("any_peer", "call_local")
func shoot():
	if not is_inside_tree() or not visible:
		return
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
	print("Enemy: set_player called. Player: ", player)
	if is_multiplayer_authority():
		if player:
			var player_id = player.name.to_int() if player.name.is_valid_int() else 1
			print("Enemy: Syncing target player. Player ID: ", player_id)
			rpc("sync_target_player", player_id)
		else:
			print("Enemy: Player is null in set_player")

@rpc("any_peer", "call_local")
func sync_target_player(player_id):
	target_player_id = player_id
	print("Enemy: sync_target_player called. Target Player ID: ", target_player_id)
	var main_node = get_tree().get_root().get_node("Main")
	if main_node and main_node.has_method("get_player_tank"):
		player = main_node.get_player_tank(target_player_id)
		if player:
			print("Enemy: Player found and set. Player position: ", player.global_position)
		else:
			print("Enemy: Player not found in sync_target_player")
	else:
		print("Enemy: Main node or get_player_tank method not found")

@rpc("any_peer", "call_local")
func take_damage(damage):
	health -= damage
	print("Enemy tank took damage. Health: ", health)
	if health <= 0 and not is_exploding:
		explode()

func explode():
	if is_exploding:
		return
	is_exploding = true
	
	var explosion = preload("res://scenes/Explosion.tscn").instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	
	# Disable collision and shooting immediately
	$CollisionShape3D.disabled = true
	set_process(false)
	set_physics_process(false)
	
	# Make the tank invisible
	visible = false
	
	# Emit the signal instead of directly calling check_round_end
	emit_signal("enemy_destroyed")
	
	# Remove the tank after a delay
	await get_tree().create_timer(2.0).timeout
	queue_free()
