extends Node3D

@onready var arena = $Arena
@onready var main_menu = $CanvasLayer/MainMenu
@onready var multiplayer_menu = $CanvasLayer/MultiplayerMenu
@onready var options_menu = $CanvasLayer/OptionsMenu
@onready var lobby = $CanvasLayer/Lobby
@onready var round_display = $CanvasLayer/RoundDisplay
@onready var round_number = $CanvasLayer/RoundDisplay/RoundNumber

var player_tanks = {}
var enemy_tank = null
var network = ENetMultiplayerPeer.new()
var port = 8910
var max_players = 4
var current_round = 0
var is_multiplayer = false

var time = 0
var wave_speed = 2
var wave_height = 10

func _ready():
	main_menu.connect("start_single_player", _on_start_single_player)
	main_menu.connect("show_multiplayer_menu", _on_show_multiplayer_menu)
	main_menu.connect("show_options", _on_show_options)
	multiplayer_menu.connect("host_game", _on_host_game)
	multiplayer_menu.connect("join_game", _on_join_game)
	multiplayer_menu.connect("back_to_main_menu", _on_back_to_main_menu)
	options_menu.connect("back_to_main_menu", _on_back_to_main_menu)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_show_options():
	main_menu.hide()
	options_menu.show()

func _on_back_to_main_menu():
	multiplayer_menu.hide()
	options_menu.hide()
	main_menu.show()

func _on_start_single_player():
	main_menu.hide()
	start_game(false)

func _on_show_multiplayer_menu():
	main_menu.hide()
	multiplayer_menu.show()

func _on_host_game():
	var host_code = generate_random_code()
	network.create_server(port, max_players)
	multiplayer.multiplayer_peer = network
	multiplayer_menu.hide()
	lobby.show()
	lobby.set_host_code(host_code)
	lobby.show_start_button(true)

func _on_join_game(code):
	network.create_client("localhost", port)
	multiplayer.multiplayer_peer = network
	multiplayer_menu.hide()
	lobby.show()
	lobby.show_start_button(false)

func start_new_round():
	current_round += 1
	round_number.text = str(current_round)
	round_display.visible = true
	setup_game()

func start_game(multiplayer_mode: bool):
	is_multiplayer = multiplayer_mode
	if is_multiplayer:
		lobby.hide()
	else:
		main_menu.hide()
	start_new_round()

func setup_game():
	for tank in player_tanks.values():
		tank.queue_free()
	player_tanks.clear()
	if enemy_tank:
		enemy_tank.queue_free()
	spawn_players()
	spawn_enemy_tank()

func _process(delta):
	if round_display.visible:
		time += delta
		var offset = sin(time * wave_speed) * wave_height
		round_number.position.y = offset

func check_round_end():
	var players_alive = false
	var enemies_alive = false

	for tank in player_tanks.values():
		if tank.health > 0:
			players_alive = true
			break

	if enemy_tank and enemy_tank.health > 0:
		enemies_alive = true

	if not players_alive or not enemies_alive:
		get_tree().create_timer(2.0).timeout.connect(start_new_round)

func _on_peer_connected(id):
	print("Peer connected: ", id)

func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)
	if player_tanks.has(id):
		player_tanks[id].queue_free()
		player_tanks.erase(id)

func spawn_players():
	var tank_scene = preload("res://scenes/Tank.tscn")
	var num_players = 1 if not is_multiplayer else multiplayer.get_peers().size() + 1
	var spacing = 5  # Vertical spacing between tanks
	
	for i in range(num_players):
		var peer_id = 1 if not is_multiplayer else (multiplayer.get_unique_id() if i == 0 else multiplayer.get_peers()[i-1])
		var tank = tank_scene.instantiate()
		tank.name = str(peer_id)
		
		# Calculate position based on index
		var x_pos = -10  # All tanks start at the same X position
		var y_pos = 0.5  # Slight elevation to ensure they're above the ground
		var z_pos = -((num_players - 1) * spacing / 2.0) + (i * spacing)  # Distribute along Z-axis
		
		tank.position = Vector3(x_pos, y_pos, z_pos)
		if is_multiplayer:
			tank.set_multiplayer_authority(peer_id)
		add_child(tank)
		player_tanks[peer_id] = tank
	
	if is_multiplayer:
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
	
	if is_multiplayer:
		enemy_tank.set_multiplayer_authority(1)
		if multiplayer.get_unique_id() == 1:
			var first_player_id = player_tanks.keys()[0]
			enemy_tank.set_player(player_tanks[first_player_id])
	else:
		var player_id = player_tanks.keys()[0]
		enemy_tank.set_player(player_tanks[player_id])

func get_player_tank(player_id):
	return player_tanks.get(player_id)

func _physics_process(_delta):
	for child in get_children():
		if child is RigidBody3D and child.global_position.length() > 100:
			child.queue_free()

func generate_random_code():
	var characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	for i in range(1):  # Changed to generate a 7-character code
		code += characters[randi() % characters.length()]
	return code
