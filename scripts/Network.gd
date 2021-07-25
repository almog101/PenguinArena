extends Node

const PORT = 28960
const MAX_CLIENTS = 6

var server = null
var client = null

var ip_address = ""

var networked_object_name_index = 0 setget networked_object_name_index_set
puppet var puppet_networked_object_name_index = 0 setget puppet_networked_object_name_index_set

func _ready():	
	if OS.get_name() == "Windows":
		ip_address = IP.get_local_addresses()[3]
	elif OS.get_name() == "Android":
		ip_address = IP.get_local_addresses()[0]
	else:
		ip_address = IP.get_local_addresses()[3]
	
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") and not ip.ends_with(".1"):
			ip_address = ip
	
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
func create_server() -> void:
	server = NetworkedMultiplayerENet.new()
	server.create_server(PORT, MAX_CLIENTS)
	get_tree().set_network_peer(server)


func join_server() -> void:
	client = NetworkedMultiplayerENet.new()
	client.create_client(ip_address, PORT)
	get_tree().set_network_peer(client)	

func _connected_to_server() -> void:
	print("Connected to server")

func _server_disconnected() -> void:
	print("Disconnected from server")

func puppet_networked_object_name_index_set(new_value) -> void:
	puppet_networked_object_name_index = new_value

func networked_object_name_index_set(new_value) -> void:
	networked_object_name_index = new_value
	
	if get_tree().is_network_server():
		rset("puppet_networked_object_name_index", networked_object_name_index)
