extends TileMap

var rng = RandomNumberGenerator.new()

const Tiles = {
	TopLeft = 7,
	TopMiddle = 12,
	TopRight = 8,

	MiddleLeft = 0,
	Middle = 3,
	MiddleRight = 5,

	BottomLeft = 11,
	BottomMiddle = 10,
	BottomRight = 13,
	
	BetweenLeftAndTop = 14,
	BetweenLeftAndBottom = 16,
	BetweenRightAndTop = 15,
	BetweenRightAndBottom = 17,
}

#func get_tile_id(name: String) -> int:
#	return tile_set.find_tile_by_name(name)

func get_random_rect(points):
	var is_connected = false
	
	var size = null
	var x = null
	var y = null 
	
	while not is_connected:
		size = rng.randi_range(3, 5)
		x = rng.randi_range(0, 20)
		y = rng.randi_range(0, 20)

		for point in get_rect_area([x, y, size]):
			if point in points or points.size() == 0:
				is_connected = true
				break
	
	return [x, y, size]

func get_rect_area(rect):
	var points = []
	
	var rect_size = rect[2]

	var start_x = rect[0] 
	var start_y = rect[1]

	for x_offset in range(rect_size + 1):
		for y_offset in range(rect_size + 1):
			points.append([start_x + x_offset, start_y + y_offset])

	return points


func get_point_type(points, point, n=1):
	var up = [point[0], point[1] - 1]
	var down = [point[0], point[1] + 1]
	var left = [point[0] - 1, point[1]]
	var right = [point[0] + 1, point[1]]

	var is_up = up in points
	var is_down = down in points
	var is_left = left in points
	var is_right = right in points

	if is_up and is_down and is_left and is_right:
		if n==0:
			return Tiles.Middle

		var type_up = get_point_type(points, up, n-1)
		var type_down = get_point_type(points, down, n-1)
		var type_left = get_point_type(points, left, n-1)
		var type_right = get_point_type(points, right, n-1)

		if type_up in [Tiles.TopLeft, Tiles.MiddleLeft] and type_left in [Tiles.TopMiddle, Tiles.TopLeft]:
			return Tiles.BetweenLeftAndTop
		elif type_up in [Tiles.TopRight, Tiles.MiddleRight] and type_right in [Tiles.TopMiddle, Tiles.TopRight]:
			return Tiles.BetweenRightAndTop
		elif type_down in [Tiles.BottomLeft, Tiles.MiddleLeft] and type_left in [Tiles.BottomLeft, Tiles.MiddleLeft, Tiles.BottomMiddle]:
			return Tiles.BetweenLeftAndBottom
		elif type_down in [Tiles.BottomRight, Tiles.MiddleRight] and type_right in [Tiles.BottomRight, Tiles.MiddleRight, Tiles.BottomMiddle]:
			return Tiles.BetweenRightAndBottom
		
		return Tiles.Middle

	else:        
		if not is_left and is_right:
			if not is_down:
				return Tiles.BottomLeft
			elif not is_up:
				return Tiles.TopLeft
			else:
				return Tiles.MiddleLeft

		elif not is_right and is_left:
			if not is_down:
				return Tiles.BottomRight
			elif not is_up:
				return Tiles.TopRight
			else:
				return Tiles.MiddleRight

		elif not is_down and is_up:
			if is_right and is_left:
				return Tiles.BottomMiddle

		elif not is_up and is_down:
			if is_right and is_left:
				return Tiles.TopMiddle

func generate_island(Seed):
	clear()
	
	var points = []
	var edge_points = []
	
	rng.seed = Seed
	print("Seed: ", Seed)
	
	for n in range (20):
		var rect = get_random_rect(points)
		var rect_points = get_rect_area(rect)
		
		for point in rect_points:
			if point in points:
				rect_points.erase(point)

		points += rect_points

	for point in points:	
		var point_type = get_point_type(points, point)
		
		set_cell(point[0], point[1], point_type)
		
		if point_type != Tiles.Middle:
			edge_points.insert(0, point)
		
	#for point in get_outer_edges(points, edge_points):
	#	set_cell(point[0], point[1], Tiles.Middle)

	return [points, edge_points]

func get_outer_edges(points, edge_points):
	var cords = []
	for point in edge_points:
		var point_type = get_point_type(points, point)
		
		if point_type == Tiles.TopLeft:
			#cords.append([point[0]-1, point[1]-1])
			cords.append([point[0]-1, point[1]])
			cords.append([point[0], point[1]-1])
			
		elif point_type == Tiles.TopMiddle:
			cords.append([point[0], point[1]-1])
			
		elif point_type == Tiles.TopRight:
			#cords.append([point[0]+1, point[1]-1])
			cords.append([point[0]+1, point[1]])
			cords.append([point[0], point[1]-1])
		
		elif point_type == Tiles.MiddleLeft:
			cords.append([point[0]-1, point[1]])
		elif point_type == Tiles.MiddleRight:
			cords.append([point[0]+1, point[1]])
			
		elif point_type == Tiles.BottomLeft:
			#cords.append([point[0]-1, point[1]+1])
			cords.append([point[0]-1, point[1]])
			cords.append([point[0], point[1]+1])
			
		elif point_type == Tiles.BottomMiddle:
			cords.append([point[0], point[1]+1])
		elif point_type == Tiles.BottomRight:
			#cords.append([point[0]+1, point[1]+1])
			cords.append([point[0]+1, point[1]])
			cords.append([point[0], point[1]+1])
	
	for point in cords:
		while cords.count(point) > 1:
			cords.erase(point)
	
	return cords


func generate_spawn_points(edge_points, space):
	var spawn_points = []
	for n in range(6):
		var point = null
		while true:
			var is_in_range = false
			point = edge_points[randi() % edge_points.size()]

			for spawn_point in spawn_points:
				is_in_range = is_in_range or point in get_rect_area([spawn_point[0] - space, spawn_point[1] - space, space * 2])
				if is_in_range:
					break

			if is_in_range == false:
				break

		spawn_points.append(point)

	return spawn_points
