extends KinematicBody2D

var speed = 300
var hp = 100 setget set_hp
var velocity = Vector2(0,0)
var can_shoot = true
var is_reloading = false
var is_dead = false

var player_bullet = load("res://scences/Player_bullet.tscn")
var username_text = load("res://scences/Username_text.tscn")

var username setget username_set
var username_text_instance = null

puppet var puppet_hp = 100 setget puppet_hp_set
puppet var puppet_position = Vector2(0, 0) setget puppet_position_set
puppet var puppet_velocity = Vector2()
puppet var puppet_rotation = 0
puppet var puppet_username setget puppet_username_set

onready var tween = $Tween
onready var player_sprite = $Player_sprite
onready var Gun_sprite = $Gun_sprite
onready var reload_timer = $Reload_timer
onready var shoot_point = $Shoot_point
onready var hit_timer = $Hit_timer

func _ready():
	get_tree().connect("network_peer_connected", self, "_network_peer_connected")
	
	username_text_instance = Global.instance_node_at_location(username_text,  Persistent_nodes, global_position)
	username_text_instance.player_following = self
	
	update_shoot_mode(false)
	
	yield(get_tree(), "idle_frame")
	if is_network_master():
		Global.player_master = self

func _process(delta: float) -> void:
	# Set Username text
	if username_text_instance != null:
		username_text_instance.name = "username" + name
	
	# Movement
	if is_network_master():
		var x_input = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
		var y_input = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))

		velocity = Vector2(x_input, y_input).normalized()

		move_and_slide(velocity * speed)
		look_at(get_global_mouse_position())

		if Input.is_action_pressed("click") and can_shoot and not is_reloading:
			rpc("instance_bullet", get_tree().get_network_unique_id())
			is_reloading = true
			reload_timer.start()

	else:
		rotation_degrees = lerp(rotation_degrees, puppet_rotation, delta*8)
		
		if not tween.is_active():
			move_and_slide(puppet_velocity * speed)

	# Death and Spectate
	if is_dead:
		if is_network_master():
			update_spectate_mode(true)
			
			#show other players in spectate mode
			for player in Persistent_nodes.get_children():
				if player.is_in_group("Player") and player.is_dead:
					pass
					#player.visible = true
					
			# tint to ghost color
			modulate = Color(3, 3, 3, 1)
	else:
		if hp<=0:
			if get_tree().is_network_server():
				rpc("disable")

func puppet_position_set(new_value) -> void:
	puppet_position = new_value

	tween.interpolate_property(self,"global_position", global_position, puppet_position, 0.1)
	tween.start()

func set_hp(new_value) -> void:
	hp = new_value
	
	if is_network_master():
		rset("puppet_hp", hp)

func puppet_hp_set(new_value) -> void:
	puppet_hp = new_value
	
	if not is_network_master():
		hp = puppet_hp

func username_set(new_value):
	username = new_value
	
	if is_network_master() and username_text_instance != null:
		username_text_instance.text = username
		rset("puppet_username", username)

func puppet_username_set(new_value):
	puppet_username = new_value
	
	if not is_network_master() and username_text_instance != null:
		username_text_instance.text = puppet_username

func _network_peer_connected(id):
	rset_id(id, "puppet_username", username)
	

func _on_Network_tick_rate_timeout():
	if is_network_master():
		rset_unreliable("puppet_position", global_position)
		rset_unreliable("puppet_velocity", velocity)
		rset_unreliable("puppet_rotation", rotation_degrees)

sync func instance_bullet(id):
	var player_bullet_instance = Global.instance_node_at_location(player_bullet, Persistent_nodes, shoot_point.global_position)
	player_bullet_instance.name = "Bullet" + name + str(Network.networked_object_name_index)
	player_bullet_instance.set_network_master(id)
	player_bullet_instance.player_rotation = rotation
	player_bullet_instance.player_owner = id
	Network.networked_object_name_index += 1

sync func update_position(pos):
	global_position = pos
	puppet_position = pos

func update_shoot_mode(shoot_mode):
	Gun_sprite.visible = shoot_mode
	can_shoot = shoot_mode

func _on_Reload_timer_timeout():
	is_reloading = false

func _on_Hit_timer_timeout():
	modulate = Color(1, 1, 1, 1)

func _on_Hitbox_area_entered(area):
	if get_tree().is_network_server():
		if area.is_in_group("Player_damager") and area.get_parent().player_owner != int(name):
			rpc("hit_by_damager", area.get_parent().damage)
			
			if not is_dead:
				area.get_parent().rpc("destroy")
			
sync func hit_by_damager(damage):
	hp -= damage
	modulate = Color(5, 5, 5, 1)
	hit_timer.start()
	
func update_spectate_mode(spectate_mode):
	visible = true
	if spectate_mode:
		speed = 450
	else:
		speed = 300

sync func reset():
	username_text_instance.visible = true
	visible = true
	update_shoot_mode(true)
	$CollisionShape2D.disabled = false
	$Hitbox/CollisionShape2D.disabled = false
	can_shoot = true
	is_dead = false
	update_spectate_mode(false)
	modulate = Color(1, 1, 1, 1)
	set_hp(100)

sync func disable() -> void:
	username_text_instance.visible = false
	visible = false
	update_shoot_mode(false)
	$CollisionShape2D.disabled = true
	$Hitbox/CollisionShape2D.disabled = true
	can_shoot = false
	is_dead = true
	

func _exit_tree():
	if is_network_master():
		Global.player_master = null
