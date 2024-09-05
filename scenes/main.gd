extends Node3D

@onready var arena = $Arena
@onready var main_menu = $CanvasLayer/MainMenu
@onready var multiplayer_menu = $CanvasLayer/MultiplayerMenu
@onready var options_menu = $CanvasLayer/OptionsMenu
@onready var lobby = $CanvasLayer/Lobby
@onready var round_display = $CanvasLayer/RoundDisplay
@onready var round_number = $CanvasLayer/RoundDisplay/RoundNumber

var wave_function_collapse = preload("res://scripts/wave_function_collapse.gd").new()
var player_tanks = {}
var enemy_tank = null
var network = ENetMultiplayerPeer.new()
var port = 8910
var max_players = 4
var current_round = 0
var is_multiplayer = false
var round_end_cooldown = false

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
	wave_function_collapse.initialize(arena.arena_size)


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
	arena.generate_new_map()
	setup_game()
	round_end_cooldown = false  # Reset the cooldown

func generate_new_map():
	var generated_map = wave_function_collapse.generate_map()
	if generated_map == null:
		print("Failed to generate map")
		return
	
	var map_3d = wave_function_collapse.create_3d_map(generated_map)
	
	var old_map = arena.get_node("GeneratedMap")
	if old_map:
		old_map.queue_free()
	
	arena.add_child(map_3d)
	map_3d.name = "GeneratedMap"

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
		enemy_tank = null  # Ensure the reference is cleared
	
	await get_tree().process_frame  # Wait for a frame to ensure cleanup
	
	spawn_players()
	spawn_enemy_tank()

func _process(delta):
	if round_display.visible:
		time += delta
		var offset = sin(time * wave_speed) * wave_height
		round_number.position.y = offset

func check_round_end():
	if round_end_cooldown:
		return

	var players_alive = false
	var enemies_alive = false

	for tank in player_tanks.values():
		if tank.health > 0:
			players_alive = true
			break

	if enemy_tank and enemy_tank.health > 0:
		enemies_alive = true

	if not players_alive or not enemies_alive:
		round_end_cooldown = true
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
	
	for i in range(num_players):
		var peer_id = 1 if not is_multiplayer else (multiplayer.get_unique_id() if i == 0 else multiplayer.get_peers()[i-1])
		var tank = tank_scene.instantiate()
		tank.name = str(peer_id)
		
		var spawn_position = arena.find_spawn_position()
		if spawn_position:
			tank.position = arena.get_world_position(spawn_position)
			if is_multiplayer:
				tank.set_multiplayer_authority(peer_id)
			add_child(tank)
			player_tanks[peer_id] = tank
	
	if is_multiplayer:
		disable_collision_between_tanks()

func on_enemy_destroyed():
	check_round_end()

func spawn_enemy_tank():
	var enemy_tank_scene = preload("res://scenes/Enemy.tscn")
	enemy_tank = enemy_tank_scene.instantiate()
	enemy_tank.connect("enemy_destroyed", Callable(self, "on_enemy_destroyed"))
	
	var spawn_position = arena.find_spawn_position()
	if spawn_position:
		enemy_tank.position = arena.get_world_position(spawn_position)
		add_child(enemy_tank)
		
		print("Main: Spawning enemy tank. Round: ", current_round)
		
		if is_multiplayer:
			enemy_tank.set_multiplayer_authority(1)
			if multiplayer.get_unique_id() == 1:
				var first_player_id = player_tanks.keys()[0]
				print("Main: Setting player for enemy in multiplayer. Player ID: ", first_player_id)
				enemy_tank.set_player(player_tanks[first_player_id])
		else:
			var player_id = 1  # Always use 1 for single-player
			print("Main: Setting player for enemy in single-player. Player ID: ", player_id)
			enemy_tank.set_player(player_tanks[player_id])

		print("Main: Enemy tank spawned. Position: ", enemy_tank.position)

func find_valid_spawn_positions(num_players):
	var positions = []
	var generated_map = arena.get_node("GeneratedMap")
	
	while positions.size() < num_players:
		var x = randi() % wave_function_collapse.MAP_SIZE_X
		var z = randi() % wave_function_collapse.MAP_SIZE_Z
		var y = 0.5  # Slight elevation to ensure they're above the ground
		
		var position = Vector3(
			x * wave_function_collapse.TILE_SIZE - (arena.arena_size.x / 2),
			y,
			z * wave_function_collapse.TILE_SIZE - (arena.arena_size.y / 2)
		)
		
		if is_valid_spawn_position(position, generated_map, positions):
			positions.append(position)
	
	return positions

func is_valid_spawn_position(position, generated_map, existing_positions):
	# Check if the position is within the arena bounds
	if abs(position.x) > arena.arena_size.x / 2 or abs(position.z) > arena.arena_size.y / 2:
		return false

	# Check if the position is empty (no wall)
	for child in generated_map.get_children():
		if child is MeshInstance3D:
			var wall_pos = child.global_position
			wall_pos.y = position.y  # Compare at the same height
			if wall_pos.distance_to(position) < wave_function_collapse.TILE_SIZE:
				return false
	
	# Check if the position is not too close to other spawn positions
	for other_position in existing_positions:
		if position.distance_to(other_position) < wave_function_collapse.TILE_SIZE * 3:
			return false
	
	return true

func disable_collision_between_tanks():
	var tanks = player_tanks.values()
	for i in range(tanks.size()):
		for j in range(i + 1, tanks.size()):
			if tanks[i].has_method("add_collision_exception_with") and tanks[j].has_method("add_collision_exception_with"):
				tanks[i].add_collision_exception_with(tanks[j])
				tanks[j].add_collision_exception_with(tanks[i])

func get_player_tank(player_id):
	if player_id == 1:  # Always return the first player for single-player
		return player_tanks.values()[0]
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
