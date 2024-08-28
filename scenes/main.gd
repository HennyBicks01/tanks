extends Node3D

@onready var arena = $Arena
@onready var main_menu = $CanvasLayer/MainMenu
@onready var lobby = $CanvasLayer/Lobby

var player_tanks = {}
var enemy_tank = null
var network = ENetMultiplayerPeer.new()
var port = 8910
var max_players = 4

func _ready():
	main_menu.connect("host_game", _on_host_game)
	main_menu.connect("join_game", _on_join_game)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_host_game():
	var host_code = generate_random_code()
	network.create_server(port, max_players)
	multiplayer.multiplayer_peer = network
	main_menu.hide()
	lobby.show()
	lobby.set_host_code(host_code)
	lobby.show_start_button(true)

func _on_join_game(code):
	network.create_client("localhost", port)
	multiplayer.multiplayer_peer = network
	main_menu.hide()
	lobby.show()
	lobby.show_start_button(false)

func _on_peer_connected(id):
	print("Peer connected: ", id)

func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)
	if player_tanks.has(id):
		player_tanks[id].queue_free()
		player_tanks.erase(id)

@rpc("any_peer", "call_local")
func start_game():
	lobby.hide()
	setup_game()

func setup_game():
	spawn_players()
	spawn_enemy_tank()

func spawn_players():
	var tank_scene = preload("res://scenes/Tank.tscn")
	var num_players = multiplayer.get_peers().size() + 1
	var spacing = 5  # Vertical spacing between tanks
	
	for i in range(num_players):
		var peer_id = multiplayer.get_unique_id() if i == 0 else multiplayer.get_peers()[i-1]
		var tank = tank_scene.instantiate()
		tank.name = str(peer_id)
		
		# Calculate position based on index
		var x_pos = -10  # All tanks start at the same X position
		var y_pos = 0.5  # Slight elevation to ensure they're above the ground
		var z_pos = -((num_players - 1) * spacing / 2) + (i * spacing)  # Distribute along Z-axis
		
		tank.position = Vector3(x_pos, y_pos, z_pos)
		tank.set_multiplayer_authority(peer_id)
		add_child(tank)
		player_tanks[peer_id] = tank
	
	# Disable collision between player tanks
	disable_collision_between_tanks()

func disable_collision_between_tanks():
	var tanks = player_tanks.values()
	for i in range(tanks.size()):
		for j in range(i + 1, tanks.size()):
			if tanks[i].has_method("add_collision_exception_with") and tanks[j].has_method("add_collision_exception_with"):
				tanks[i].add_collision_exception_with(tanks[j])
				tanks[j].add_collision_exception_with(tanks[i])

func spawn_enemy_tank():
	var enemy_tank_scene = preload("res://scenes/Enemy.tscn")
	enemy_tank = enemy_tank_scene.instantiate()
	enemy_tank.position = Vector3(10, 0, 0)
	add_child(enemy_tank)
	enemy_tank.set_player(player_tanks[multiplayer.get_unique_id()])

func _physics_process(_delta):
	for child in get_children():
		if child is RigidBody3D and child.global_position.length() > 100:
			child.queue_free()

func generate_random_code():
	var characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	for i in range(7):  # Changed to generate a 7-character code
		code += characters[randi() % characters.length()]
	return code
