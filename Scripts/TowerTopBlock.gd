
extends KinematicBody2D

var main_node

func _ready():
	main_node = get_tree().get_root().get_node("Main")

func flip():
	get_node("..").set_flip_h(true)
	get_node("LadderArea").set_pos(Vector2(-124, 0))

func _on_LadderArea_body_enter( body ):
	if not body.get("player_num") == null:
		main_node.ladder_variable[body.player_num] += 1

func _on_LadderArea_body_exit( body ):
	if not body.get("player_num") == null:
		main_node.ladder_variable[body.player_num] -= 1


