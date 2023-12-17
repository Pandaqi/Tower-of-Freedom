
extends StaticBody2D

var health = 0
var main_node
var has_shape = false
var collider_translation = Vector2(-120,-10)
var is_flipped = 0
var my_number = 0

func _ready():
	main_node = get_tree().get_root().get_node("Main")

func change_health(change):
	if(health == -5):
		return
	health = clamp(health+change, -1, GLOBAL.max_tower_health)
	
	# show light if in night mode, and full health
	get_node("Light2D").hide()
	if(health == GLOBAL.max_tower_health):
		main_node.relay_signal(5)
		if(GLOBAL.night_mode):
			get_node("Light2D").show()
	
	# destroys tower if it's too damaged
	if(health < 0):
		main_node.remove_tower(is_flipped, my_number, get_pos())
		health = -5
		queue_free()
		return
	
	var temp_health = clamp(health, 0, GLOBAL.max_tower_health)
	# set the right frame
	get_node("TowerSprite").set_frame(round(float(GLOBAL.max_tower_health-temp_health)/GLOBAL.max_tower_health*4))

func update_health():
	change_health(1)

func flip():
	is_flipped = 1
	get_node("TowerSprite").set_flip_h(true)
	collider_translation = Vector2(-50,0)
	get_node("TowerSprite/Ladder").set_flip_h(true)
	get_node("TowerSprite/LadderArea").set_pos(get_node("TowerSprite/LadderArea").get_pos()+Vector2(-80,0))
	get_node("TowerSprite/Ladder").set_pos(get_node("TowerSprite/Ladder").get_pos()+Vector2(-80,0))
	get_node("Light2D").set_pos(get_node("Light2D").get_pos()+Vector2(-40,0))

func _on_LadderArea_body_enter( body ):
	if not body.get("player_num") == null:
		main_node.ladder_variable[body.player_num] += 1

func _on_LadderArea_body_exit( body ):
	if not body.get("player_num") == null:
		main_node.ladder_variable[body.player_num] -= 1
