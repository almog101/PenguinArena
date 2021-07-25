extends StaticBody2D

export var MAX_HP = 100
var hp = MAX_HP setget set_hp

var is_dead = false

onready var hit_timer = $Hit_timer

func _process(delta):
	if hp<=0 and not is_dead:
		if get_tree().is_network_server():
			rpc("disable")
			is_dead = true

func set_hp(new_value) -> void:
	hp = new_value

func _on_Hitbox_area_entered(area):
	if get_tree().is_network_server():
		if area.is_in_group("Player_damager") and area.get_parent().player_owner != int(name):
			rpc("hit_by_damager", area.get_parent().damage)
			
			area.get_parent().rpc("destroy")
			
sync func hit_by_damager(damage):
	hp -= damage
	modulate = Color(5, 5, 5, 1)
	hit_timer.start()

sync func reset():
	visible = true
	$CollisionShape2D.disabled = false
	$Hitbox/CollisionShape2D.disabled = false
	set_hp(MAX_HP)
	is_dead = false

sync func disable() -> void:
	visible = false
	$CollisionShape2D.disabled = true
	$Hitbox/CollisionShape2D.disabled = true

func _on_Hit_timer_timeout():
		modulate = Color(1, 1, 1, 1)
