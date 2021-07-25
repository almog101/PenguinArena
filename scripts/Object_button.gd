extends Button

var box = load("res://scences//Box.tscn")
var wall = load("res://scences//Wall.tscn")


func set_type(type: String):
	text = type

sync func generate_box(location: Vector2):
	print("Box at ", location)
	Global.instance_node_at_location(box, Persistent_nodes, location)

sync func destroy():
	queue_free()

func _on_Object_button_pressed():
	randomize()
	rpc("generate_box", Persistent_nodes.get_children()[randi() % Persistent_nodes.get_children().size()].global_position)
	rpc("destroy")
