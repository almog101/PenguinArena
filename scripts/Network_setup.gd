extends Control

const MIN_PLAYERS = 2
const NAMES = ["Mike Hawk", "Hugh G. Rection", "Drew Peacock", "Ben Dover", "Jenny Tulls", "Jack Goff", "Joe Mama", " Yuri Tarded", "Mike Hunt", "Mike Oxbig", "Nick Gurr"]
const CHARACTERS = "123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

var player = load("res://scences//Player.tscn")

onready var multiplayer_config_ui = $multiplayer_configure
onready var server_ip_address = $multiplayer_configure/Server_ip_address
onready var username_text_edit = $multiplayer_configure/Username

onready var device_ip_address = $CanvasLayer/Device_ip_address
onready var start_game = $CanvasLayer/Start_game

func _ready() -> void:
	randomize()
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_to_server")

	device_ip_address.text = Network.ip_address

	if get_tree().network_peer != null:
		pass
	else:	
		start_game.hide()

func _process(_delta: float) -> void:
	if get_tree().network_peer != null:
		if get_tree().get_network_connected_peers().size() + 1 >= MIN_PLAYERS and get_tree().is_network_server():
			start_game.show()
		else:
			start_game.hide()

func _player_connected(id) -> void:
	print("Player %d connected" % id)
	
	instance_player(id)
	
func _player_disconnected(id) -> void:
	print("Player %d disconnected" % id)
	
	if Persistent_nodes.has_node(str(id)):
		Persistent_nodes.get_node(str(id)).username_text_instance.queue_free()
		Persistent_nodes.get_node(str(id)).queue_free()

func _on_Create_server_pressed():
	if username_text_edit.text == "":
		for i in range(3):
			username_text_edit.text += CHARACTERS[randi() % CHARACTERS.length()]

	multiplayer_config_ui.hide()
	Network.create_server()
	instance_player(get_tree().get_network_unique_id())

func _on_Join_server_pressed():
	var ip = ""
	
	if server_ip_address.text != "":
		ip = server_ip_address.text
	else:
		ip = "127.0.0.1"
	
	if username_text_edit.text == "":
		for i in range(3):
			username_text_edit.text += CHARACTERS[randi() % CHARACTERS.length()]
	
	multiplayer_config_ui.hide()
	Network.ip_address = ip
	Network.join_server()
		
func _connected_to_server() -> void:
	yield(get_tree().create_timer(0.1), "timeout")
	instance_player(get_tree().get_network_unique_id())
		
func instance_player(id) -> void:
	var player_instance = Global.instance_node_at_location(player, Persistent_nodes, Vector2(rand_range(200,500), rand_range(200,500)))
	player_instance.name = str(id)
	player_instance.set_network_master(id)
	player_instance.username = username_text_edit.text

func _on_Start_game_pressed():
	rpc("switch_to_game")
	
sync func switch_to_game() -> void:
	for child in Persistent_nodes.get_children():
		if child.is_in_group("Player"):
			child.update_shoot_mode(true)
	
	get_tree().change_scene("res://scences/Game.tscn")


func _on_Random_name_button_pressed():
	randomize()
	username_text_edit.text = NAMES[randi() % NAMES.size()]




