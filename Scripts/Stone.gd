
extends StaticBody2D

var health = 0
var start_health = 0
var stone_piece
var my_pos = Vector2(0,0)

func set_health(a, pos):
	my_pos = pos
	health = a
	start_health = a
	stone_piece = preload("res://Scenes/StonePiece.tscn")

func change_health(change):
	if(health > 0):
		health += change
	
	if(health <= 0):
		GLOBAL.highscore += 6
		var main_node = get_tree().get_root().get_node("Main")
		main_node.update_level(my_pos, "stone")
		main_node.relay_signal(11)
		for i in range(start_health):
			var new_piece = stone_piece.instance()
			new_piece.set_pos(get_pos()+Vector2(randf()*400-200,-100))
			new_piece.apply_impulse(Vector2(0,0), Vector2(randf()*300-150, -randf()*1500))
			main_node.pickables.append(new_piece)
			main_node.add_child(new_piece)
			self.queue_free()



