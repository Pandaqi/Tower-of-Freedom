
extends Node

var objects = []
var cloud_scene = null
var sparkle_scene = null
var level_size
var night_mode  = false
var num = 20

func init_sky(lev_s):
	level_size = lev_s
	if(GLOBAL.night_mode):
		night_mode = true
		sparkle_scene = preload("res://Scenes/Sparkle.tscn")
		
		for i in range(num):
			var new_sparkle = sparkle_scene.instance()
			init_sparkle(new_sparkle)
			add_child(new_sparkle)
			objects.push_back(new_sparkle)
	else:
		cloud_scene = preload("res://Scenes/Cloud.tscn")
		
		for i in range(num):
			var new_cloud = cloud_scene.instance()
			init_cloud(new_cloud)
			new_cloud.set_pos(Vector2(randf()*level_size.x, level_size.y*0.5*randf()))
			add_child(new_cloud)
			objects.push_back(new_cloud)

func init_cloud(cur_obj):
	randomize()
	cur_obj.set_pos(Vector2(-randf()*150 - 50, level_size.y*0.5*randf()))
	var rand_scale = randf()*1.75+0.4
	cur_obj.set_z(-1 * (randf()*150+20))
	var opac = (-1) * (cur_obj.get_z()*0.0058) # 1/170 ~~ 0.0058
	cur_obj.set_opacity(opac)
	cur_obj.set_scale(Vector2(opac*3, opac*3))
	cur_obj.set_frame(round(randf()*2.98-0.49))

func init_sparkle(cur_obj):
	randomize()
	var rand_scale = randf()*0.85+0.1
	cur_obj.set_scale(Vector2(rand_scale, rand_scale))
	cur_obj.set_rot(randf()*6)
	cur_obj.get_node("Light2D").set_color(Color(randf(), randf(), randf()))
	cur_obj.set_pos(Vector2(level_size.x*randf(), level_size.y*0.5*randf()))

func animate_objects():
	if(night_mode):
		# SPARKLES
		for i in range(num):
			var cur_obj = objects[i]
			
			# check state, fade in or fade out
			if(cur_obj.get_z() == -100):
				cur_obj.set_opacity(cur_obj.get_opacity()+randf()*0.0667)
			elif(cur_obj.get_z() == -99):
				cur_obj.set_opacity(cur_obj.get_opacity()-randf()*0.0667)
			
			# switch in extreme states
			if(cur_obj.get_opacity() >= 1):
				cur_obj.set_z(-99)
			elif(cur_obj.get_opacity() <= 0):
				cur_obj.set_z(-100)
				init_sparkle(cur_obj)
	else:
		# CLOUDS
		for i in range(num):
			var cur_obj = objects[i]
			cur_obj.set_pos(cur_obj.get_pos()+Vector2(-cur_obj.get_z()*0.02,0))
			
			if(cur_obj.get_pos().x > level_size.x+200):
				init_cloud(cur_obj)


