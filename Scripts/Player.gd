extends KinematicBody2D

const GRAVITY = 2200.0
var velocity = Vector2()
var WALK_SPEED = 400
var WEAPON_STRENGTH = 1
var CLIMB_SPEED = 200
var player_num = 0
var my_tool
var button_names
var cur_frame = 2
var dir_facing = 1

var feet_col = null
var left_col = null
var right_col = null
var bodies = null

var player_sprite = null
var anim_player = null
var prev_anim_wanted
var allow_anim_override = true

var health = 100
var lives = 3

var single_arrow = null
var single_bomb = null
var aiming = "no"
var aiming_speed = 0

var main_node = null
var gui_node = null
var portal = Vector2(0,0)
var currently_buying = false
var hit_color = 0

var extra_force = 0
var sample_player = null
var general_timer = 0

func _ready():
	player_sprite = get_node("PlayerSprite")
	anim_player = get_node("PlayerSprite/AnimationPlayer")
	feet_col = get_node("FeetCollider")
	left_col = get_node("LeftCollider")
	right_col = get_node("RightCollider")
	main_node = get_tree().get_root().get_node("Main")
	gui_node = main_node.get_node("GUI/Control")
	portal = main_node.get_node("Portal").get_pos()
	
	sample_player = get_node("SamplePlayer2D")
	
	single_arrow = preload("res://Scenes/Arrow.tscn")
	single_bomb = preload("res://Scenes/Bomb.tscn")
	
	if(!GLOBAL.night_mode):
		get_node("Light2D").queue_free()
		get_node("Light2D1").queue_free()
	
	get_node("ToolsPopup").set_frame(player_num)
	change_tool(my_tool)
	
	if(GLOBAL.multiplayer):
		if(player_num == 0):
			self.set_collision_mask_bit(19, 1)
			feet_col.set_layer_mask_bit(18, 1)
		else:
			self.set_collision_mask_bit(18, 1)
			feet_col.set_layer_mask_bit(19, 1)

	set_fixed_process(true)
	set_process_input(true)

func _fixed_process(delta):
	general_timer += delta
	if(!currently_buying):
		move_character(delta)
		if(general_timer > 0.3):
			general_timer = 0
			check_portal()
		hit_feedback()

func hit_feedback():
	# hitting feedback
	if(hit_color > 0):
		player_sprite.set_modulate(Color(1.0, 1.0-hit_color, 1.0))
		hit_color -= 0.01

# check if we're close enough to the portal - if so, suck us in!
func check_portal():
	if(GLOBAL.night_mode):
		var all_trees = get_tree().get_nodes_in_group("Trees")
		for i in range (all_trees.size()):
			if((get_pos() - all_trees[i].get_pos()).length() < 600):
				all_trees[i].turn_light(true)
			else:
				all_trees[i].turn_light(false)
	
	if((get_pos() - portal).length() < 100):
		main_node.end_game("win")

func change_health(n):
	health += n
	gui_node.change_health_display(player_num, health)
	hit_color = 0.5
	if(health <= 0):
		change_health(100)
		lives -= 1
		gui_node.change_lives_display(player_num, lives)
		if(lives <= 0):
			main_node.end_game("lose")
		else:
			main_node.relay_signal(-3)
	if(health > 100):
		change_health(-100)
		lives = min((lives+1), 3)
		gui_node.change_lives_display(player_num, lives)

# 10 means no tool
func change_tool(num):
	my_tool = num
	aiming = "no"
	allow_anim_override = true
	if(num == 10):
		get_node("Tool").hide()
		main_node.relay_signal(3)
	else:
		get_node("Tool").show()
		get_node("Tool").set_frame(num)
		main_node.relay_signal(2)
		if(num == 0):
			main_node.relay_signal(16)
		elif(num == 1):
			main_node.relay_signal(14)
		elif(num == 2):
			main_node.relay_signal(19)
		elif(num == 3):
			main_node.relay_signal(8)
		elif(num == 4):
			main_node.relay_signal(4)
		elif(num == 5):
			main_node.relay_signal(10)

func move_character(delta):
	var on_a_ladder = (main_node.ladder_variable[player_num] >= 1)
	var anim_wanted = ""
	
	var on_the_ground = (feet_col.get_overlapping_bodies().size() > 0)
	
	if(on_a_ladder):
		velocity.y = 0
	
	if(Input.is_action_pressed(button_names[5])):
		# power up a weapon
		aiming_speed += 0.1
	
	if (Input.is_action_pressed(button_names[0])):
		velocity.x = -WALK_SPEED
		if(on_the_ground):
			anim_wanted = "Running"
		dir_facing = 1
	elif (Input.is_action_pressed(button_names[1])):
		velocity.x = WALK_SPEED
		if(on_the_ground):
			anim_wanted = "Running"
		dir_facing = -1
	else:
		velocity.x = 0
	
	if (Input.is_action_pressed(button_names[2])):
		if(on_a_ladder):
			velocity.y = -CLIMB_SPEED
			anim_wanted = "Climbing"
		elif(on_the_ground):
			velocity.y = -GRAVITY*0.5
			anim_wanted = "Jump"
	elif (Input.is_action_pressed(button_names[3])):
		if(on_a_ladder):
			velocity.y = CLIMB_SPEED
			anim_wanted = "Climbing"
		elif(on_the_ground && anim_wanted != "Running"):
			anim_wanted = "Duck"
			reset_aiming()
	
	if(my_tool != 10):
		if(Input.is_action_pressed(button_names[3]) && Input.is_action_pressed(button_names[2])):
			main_node.all_tools[my_tool].set_pos(self.get_pos())
			main_node.all_tools[my_tool].show()
			main_node.all_tools[my_tool].apply_impulse(Vector2(0,0), Vector2(0,-600))
			change_tool(10)
			velocity.y = 0
	
	player_sprite.set_scale(Vector2(dir_facing, 1))
	
	if(!on_a_ladder):
		velocity.y += delta * GRAVITY
	
	if(abs(extra_force) > 120):
		velocity.x += extra_force
		extra_force *= 0.985
	var motion = velocity * delta
	
	# don't let player fall off the edges
	if(!(get_pos().x+motion.x < 0 || get_pos().x+motion.x > main_node.level_size.x)):
		motion = move(motion)
		
		if (is_colliding()):
			var n = get_collision_normal()
			motion = n.slide(motion)
			velocity = n.slide(velocity)
			move(motion)
	
	if(anim_wanted == ""):
		if(aiming == "shoot"):
			player_sprite.set_frame(23)
			anim_player.stop()
		elif(aiming == "throw"):
			player_sprite.set_frame(31)
			anim_player.stop()
	
	if(!on_the_ground && velocity.y > 0):
		anim_wanted = "Falling"
	
	if(anim_wanted != "Duck" && velocity.x == 0 && velocity.y == 0):
		anim_wanted = "Idle"
	
	if(prev_anim_wanted == "Falling" && on_the_ground):
		anim_wanted = "Landing"
	
	var speed = 4.5
	
	if(Input.is_action_pressed(button_names[4])):
		if(my_tool == 0):
			anim_wanted = "Shooting"
			speed = 3
		elif(my_tool == 1):
			anim_wanted = "Fighting"
			speed = 1.5
		elif(my_tool == 2):
			anim_wanted = "Throwing"
			speed = 3.5
		elif(my_tool == 3):
			anim_wanted = "Chopping"
		elif(my_tool == 4):
			anim_wanted = "Building"
		elif(my_tool == 5):
			anim_wanted = "Slashing"
	
	if(anim_wanted == "Running" || anim_wanted == "Landing"):
		get_node("DustParticles").set_emitting(true)
	else:
		get_node("DustParticles").set_emitting(false)
	
	# PLAY SOUNDS
	if(anim_wanted == "Running"):
		play_sample("Footsteps on Dirt", 0)
	else:
		sample_player.stop_voice(0)
	
	if(anim_wanted == "Landing"):
		play_sample("Landing", 2)
	
	# ACTUALLY CHANGE/SET  ANIMATION
	if(anim_player.get_current_animation() != anim_wanted && allow_anim_override && anim_wanted != ""):
		# third argument is speed
		# don't have a clue about the second argument
		anim_player.play(anim_wanted, -1, speed)
		
		if(anim_wanted == "Landing"):
			allow_anim_override = false
	
	prev_anim_wanted = anim_wanted

func play_sample(name, voice):
	if(!sample_player.is_voice_active(voice)):
			sample_player.play(name, voice)

func build():
	bodies = get_dir_bodies()

	var found_body = false
	for i in range(bodies.size()):
		if(bodies[i].is_in_group("TowerBlocks")):
			play_sample("Hammer", 1)
			if(bodies[i].health < GLOBAL.max_tower_health):
				bodies[i].change_health(0.4)
				found_body = true
				break
	
	if(!found_body):
		main_node.create_new_tower(dir_facing, get_pos())

func chop():
	bodies = get_dir_bodies()
	
	for i in range(bodies.size()):
		if(bodies[i].is_in_group("Trees") && !bodies[i].dying):
			play_sample("Chopping", 1)
			bodies[i].change_health(-1, dir_facing)

func slash():
	bodies = get_dir_bodies()
	
	for i in range(bodies.size()):
		if(bodies[i].is_in_group("Stones")):
			play_sample("Stone Breaking", 1)
			bodies[i].change_health(-1)

func fight():
	bodies = get_dir_bodies()
	
	for i in range(bodies.size()):
		if(bodies[i].is_in_group("Monsters")):
			play_sample("Sword", 1)
			bodies[i].revolt(-dir_facing*300, 0)
			bodies[i].change_health(-2*WEAPON_STRENGTH)

func shoot():
	aiming = "shoot"

func throw():
	aiming = "throw"

func launch_projectile(what, pos):
	var new_proj = what.instance()
	if(dir_facing == 1):
		new_proj.get_node("Sprite").set_flip_h(true)
		new_proj.set_pos(get_pos()+pos)
	else:
		new_proj.set_pos(get_pos()+Vector2(pos.x*-1, pos.y))
	
	if(aiming == "shoot"):
		new_proj.set_rot(-0.125*PI*dir_facing)
		new_proj.set_angular_velocity(-dir_facing*2/aiming_speed)
		new_proj.level_bottom = main_node.level_size.y
		new_proj.MY_STRENGTH = WEAPON_STRENGTH
		play_sample("Arrow", 1)
	elif(aiming == "throw"):
		new_proj.set_angular_velocity(randf())
		new_proj.MY_STRENGTH = WEAPON_STRENGTH*0.5
		main_node.relay_signal(20)
		play_sample("Arrow", 1)
	main_node.add_child(new_proj)
	new_proj.apply_impulse(Vector2(0,0), Vector2(dir_facing*-300*aiming_speed, -150*aiming_speed))

func _input(ev):
	if(currently_buying):
		# move selection "cursor"
		var change = Vector2(0,0)
		if(ev.is_action_released(button_names[0])):
			change = Vector2(-1,0)
		elif(ev.is_action_released(button_names[1])):
			change = Vector2(1,0)
		
		if(ev.is_action_released(button_names[2])):
			change += Vector2(0,-1)
		elif(ev.is_action_released(button_names[3])):
			change += Vector2(0, 1)
		gui_node.move_selection(change)
		
		# close the GUI buying menu
		if(ev.is_action_released(button_names[5])):
			main_node.toggle_split_screen(0, 0, player_num)
	elif(aiming != "no" || my_tool == 4):
		if(ev.is_action_released(button_names[5])):
			if(aiming == "shoot"):
				launch_projectile(single_arrow, Vector2(-100,0))
				reset_aiming()
			elif(aiming == "throw"):
				launch_projectile(single_bomb, Vector2(-100,-30))
				reset_aiming()
			elif(my_tool == 4):
				# open the GUI buying menu
				if(main_node.split_screen == -1):
					main_node.toggle_split_screen(1, (player_num+1)%2, player_num)
					currently_buying = true

func reset_aiming():
	aiming = "no"
	allow_anim_override = true
	anim_player.play()
	aiming_speed = 0.01

func get_dir_bodies():
	if(dir_facing == 1):
		return left_col.get_overlapping_bodies()
	elif(dir_facing == -1):
		return right_col.get_overlapping_bodies()

func landing_finished():
	allow_anim_override = true

# velocity = velocity.normalized()
