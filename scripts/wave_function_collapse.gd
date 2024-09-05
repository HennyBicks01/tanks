extends Node

const TILE_SIZE = 3
const MIN_WALL_LENGTH = 3
const MAX_WALL_LENGTH = 5

var MAP_SIZE_X: int
var MAP_SIZE_Z: int

var tiles = {
	"empty": 0,
	"wall_h": 1,
	"wall_v": 2,
}

func initialize(arena_size: Vector2):
	MAP_SIZE_X = int(arena_size.x / TILE_SIZE)
	MAP_SIZE_Z = int(arena_size.y / TILE_SIZE)
	print("Initialized map size: ", MAP_SIZE_X, " x ", MAP_SIZE_Z)
	print("TILE_SIZE: ", TILE_SIZE)
	print("Total map size: ", MAP_SIZE_X * TILE_SIZE, " x ", MAP_SIZE_Z * TILE_SIZE)

func generate_map():
	if MAP_SIZE_X == 0 or MAP_SIZE_Z == 0:
		print("Error: Map size not initialized. Call initialize() first.")
		return null

	var map = []
	for x in range(MAP_SIZE_X):
		map.append([])
		for z in range(MAP_SIZE_Z):
			map[x].append("empty")
	
	# Ensure the borders are walls
	for x in range(MAP_SIZE_X):
		map[x][0] = "wall_h"
		map[x][MAP_SIZE_Z-1] = "wall_h"
	for z in range(MAP_SIZE_Z):
		map[0][z] = "wall_v"
		map[MAP_SIZE_X-1][z] = "wall_v"
	
	create_uniform_walls(map)
	ensure_connectivity(map)
	return map

func create_uniform_walls(map):
	for x in range(1, MAP_SIZE_X - 1):
		for z in range(1, MAP_SIZE_Z - 1):
			if map[x][z] == "empty" and randf() < 0.1:
				var wall_type = "wall_h" if randf() < 0.5 else "wall_v"
				var wall_length = randi() % (MAX_WALL_LENGTH - MIN_WALL_LENGTH + 1) + MIN_WALL_LENGTH
				
				if can_place_wall(map, x, z, wall_type, wall_length):
					place_wall(map, x, z, wall_type, wall_length)

func can_place_wall(map, x, z, wall_type, length):
	var dx = 1 if wall_type == "wall_h" else 0
	var dz = 1 if wall_type == "wall_v" else 0
	
	for i in range(length):
		var nx = x + i * dx
		var nz = z + i * dz
		if nx >= MAP_SIZE_X - 1 or nz >= MAP_SIZE_Z - 1 or map[nx][nz] != "empty":
			return false
		
		# Check for adjacent walls
		if has_invalid_adjacent_walls(map, nx, nz, wall_type):
			return false
	
	return true

func has_invalid_adjacent_walls(map, x, z, wall_type):
	var opposing_type = "wall_v" if wall_type == "wall_h" else "wall_h"
	var adjacent_opposing = 0
	var adjacent_same = 0
	
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			if dx == 0 and dz == 0:
				continue
			var nx = x + dx
			var nz = z + dz
			if nx >= 0 and nx < MAP_SIZE_X and nz >= 0 and nz < MAP_SIZE_Z:
				if map[nx][nz] == opposing_type:
					adjacent_opposing += 1
				elif map[nx][nz] == wall_type:
					adjacent_same += 1
	
	# Allow only one opposing wall and no same-type walls
	return adjacent_opposing > 1 or adjacent_same > 0

func place_wall(map, x, z, wall_type, length):
	var dx = 1 if wall_type == "wall_h" else 0
	var dz = 1 if wall_type == "wall_v" else 0
	
	for i in range(length):
		map[x + i * dx][z + i * dz] = wall_type

func count_opposing_walls(map, x, z, wall_type):
	var opposing_type = "wall_v" if wall_type == "wall_h" else "wall_h"
	var count = 0
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			var nx = x + dx
			var nz = z + dz
			if nx >= 0 and nx < MAP_SIZE_X and nz >= 0 and nz < MAP_SIZE_Z:
				if map[nx][nz] == opposing_type:
					count += 1
	return count

func ensure_connectivity(map):
	var start = find_empty_spot(map)
	var end = find_empty_spot(map, start)
	
	if not has_path(map, start, end):
		remove_walls_for_path(map, start, end)

func find_empty_spot(map, exclude = null):
	var empty_spots = []
	for x in range(1, MAP_SIZE_X - 1):
		for z in range(1, MAP_SIZE_Z - 1):
			if map[x][z] == "empty" and Vector2(x, z) != exclude:
				empty_spots.append(Vector2(x, z))
	return empty_spots[randi() % empty_spots.size()]

func has_path(map, start, end):
	var queue = [start]
	var visited = {start: true}
	var directions = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
	
	while queue:
		var current = queue.pop_front()
		if current == end:
			return true
		
		for dir in directions:
			var next = current + dir
			if next.x >= 0 and next.x < MAP_SIZE_X and next.y >= 0 and next.y < MAP_SIZE_Z:
				if map[next.x][next.y] == "empty" and not visited.has(next):
					queue.append(next)
					visited[next] = true
	
	return false

func remove_walls_for_path(map, start, end):
	var path = find_path(map, start, end)
	if path:
		for i in range(1, path.size() - 1):
			var current = path[i]
			map[current.x][current.y] = "empty"

func find_path(map, start, end):
	var queue = [[start]]
	var visited = {start: true}
	var directions = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
	
	while queue:
		var path = queue.pop_front()
		var current = path[-1]
		
		if current == end:
			return path
		
		for dir in directions:
			var next = current + dir
			if next.x >= 0 and next.x < MAP_SIZE_X and next.y >= 0 and next.y < MAP_SIZE_Z:
				if not visited.has(next):
					queue.append(path + [next])
					visited[next] = true
	
	return null

func find_spawn_position(map):
	var empty_spots = []
	for x in range(1, MAP_SIZE_X - 1):
		for z in range(1, MAP_SIZE_Z - 1):
			if is_valid_spawn_area(map, x, z):
				empty_spots.append(Vector2(x, z))
	
	if empty_spots.size() > 0:
		return empty_spots[randi() % empty_spots.size()]
	return null

func is_valid_spawn_area(map, x, z):
	for dx in range(2):
		for dz in range(2):
			if x + dx >= MAP_SIZE_X or z + dz >= MAP_SIZE_Z or map[x + dx][z + dz] != "empty":
				return false
	return true
