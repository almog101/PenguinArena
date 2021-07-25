extends Node2D

var border = load("res://scences//Border.tscn")
var object_button = load("res://scences//Object_button.tscn")

onready var ground_tilemap = $Ground_tilemap
onready var borders = $Borders
onready var object_menu = $CanvasLayer/Object_menu

var points = null
var edge_points = null
var spawn_points = null

func _player_disconnected(id):
	if Persistent_nodes.has_node(str(id)):
		Persistent_nodes.get_node(str(id)).username_text_instance.queue_free()
		Persistent_nodes.get_node(str(id)).queue_free()

func array_to_vector2(arr):
	return Vector2(arr[0], arr[1])

func _process(delta):
	if get_alive_players() == 1 and not object_menu.visible:
		object_menu.visible = true

		if get_tree().is_network_server():
			rpc("instance_button", Vector2(rand_range(170,815), rand_range(127,470)), "box")
			
	if object_menu.visible:
		if child_group_count(object_menu, "ObjectButton") == 0:
			object_menu.visible = false
			restart_game()

func _ready():
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	VisualServer.set_default_clear_color(Color("041d4e"))
	object_menu.visible = false
	
	if get_tree().is_network_server():
			rpc("generate_island", randi())
			spawn_points = ground_tilemap.generate_spawn_points(edge_points, 4)
			setup_players_positions()

sync func instance_button(location: Vector2, type: String):
	var object_button_instance = Global.instance_node(object_button, object_menu)
	object_button_instance.set_type(type)

func child_group_count(parent: Object, group: String) -> int:
	var count = 0
	for child in parent.get_children():
		if child.is_in_group(group):
			count += 1
	return count

func get_alive_players() -> int:
	var count = 0
	for player in Persistent_nodes.get_children():
		if player.is_in_group("Player"):
			if not player.is_dead:
				count += 1
	return count
	
sync func show_object_menu():
	pass

sync func restart_game():
	for node in Persistent_nodes.get_children():
		if node.is_in_group("Bullet"):
			node.rpc("destroy")
		else:
			node.rpc("reset")
	setup_players_positions()

						
func setup_players_positions():
	var current_spawn_location = 0
	for player in Persistent_nodes.get_children():
		if player.is_in_group("Player"):
			player.rpc("update_position", ground_tilemap.map_to_world(array_to_vector2(spawn_points[current_spawn_location])))
			current_spawn_location += 1

sync func generate_island(Seed):
	points = ground_tilemap.generate_island(Seed)
	edge_points = points[1]
	points = points[0]
	
	for border_point in ground_tilemap.get_outer_edges(points, edge_points):
		Global.instance_node_at_location(border, borders, ground_tilemap.map_to_world(array_to_vector2(border_point)))
