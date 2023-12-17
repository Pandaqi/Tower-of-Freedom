
extends Sprite

var timer = 0
var monster_timer = 0
var cur_dir = 0
var MY_SPEED = 0
var main_node
var arrow_scene

func _ready():
	set_process(true)
	if(randf() > 0.5):
		cur_dir = 1
	else:
		cur_dir = -1
		set_flip_h(true)
	MY_SPEED = randf()*2+0.1
	main_node = get_tree().get_root().get_node("Main")
	arrow_scene = preload("res://Scenes/Arrow.tscn")
	if(!GLOBAL.night_mode):
		get_node("Light2D").queue_free()

func _process(delta):
	timer += delta
	monster_timer += delta
	set_pos(get_pos()+Vector2(cur_dir*MY_SPEED,0))
	
	# once in a while, change direction
	if(timer > 4+randf()*4):
		timer = 0
		if(cur_dir == 1):
			cur_dir = -1
			set_flip_h(true)
		else:
			cur_dir = 1
			set_flip_h(false)
	
	# once in a while, check for targets
	if(monster_timer > 1.5):
		monster_timer = 0
		var monsters = get_tree().get_nodes_in_group("Monsters")
		for i in range (monsters.size()):
			if((get_pos()-monsters[i].get_pos()).length() < 650):
				var dS = monsters[i].get_pos() - self.get_pos()
				# a bit of randomness
				if(randf() > 0.2):
					dS.x += randf()*70-35
					dS.y += randf()*70-35
				
				var grav = 750
				var D = sqrt(dS.y*dS.y + 2*grav*abs(dS.x)*tan(0.125*PI))
				# not possible
				if(dS.y < -D):
					continue
				var timi = (1.0/grav) * (dS.y + D)
				var velocity = Vector2(dS.x/timi, -abs(dS.x/timi)*tan(0.125*PI))
				print(dS)
				print(timi)
				print(velocity)
				
				var new_proj = arrow_scene.instance()
				if(velocity.x < 0):
					new_proj.set_rotd(180-22.5)
					new_proj.set_angular_velocity(600.0/velocity.x)
				else:
					new_proj.set_rotd(22.5)
					new_proj.set_angular_velocity(600.0/velocity.x)
				new_proj.level_bottom = main_node.level_size.y
				new_proj.MY_STRENGTH = 1
				new_proj.set_pos(get_pos())
				main_node.add_child(new_proj)
				new_proj.apply_impulse(Vector2(0,0), velocity)
	

