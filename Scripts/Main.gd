
extends Node2D

# determining the sizes of all types of stuff
var grass_block_size
var grass_block_amount = 30
var level_size
var cell_size
var lev_width
var lev_height

var gui_node = null
var players = [null, null]

var last_monster = 15
var monsters = [null, null, null, null]
var monster_time_interval = 0
var dust_particles = null

# camera and viewport shizzle
var main_camera = null
var external_change_zoom = 0
var max_zoom = 1
var viewport_width = 0
var viewport_height = 0
var original_view_rect
var viewport_size = Vector2(0,0)

var split_screen = -1
var split_screen_side = -1

var time_tracker = 0
var highscore = 0
var general_timer = 0
var warning_sign_scene = null
var ghost_helper = null

# tower, ladders and tower tops
var tower_block = null
var tower_pos = [Vector2(0,0),Vector2(0,0)]
var tower_block_height = 149
var ladder_variable = [0,0]
var tower_top_blocks = [null, null]
var tower_info = [[1],[1]]

# wood, stone, diamonds
var pickables = []
var amount_resources = [0,0,0]
var diamond_piece = null
var stone_blocks = [null, null, null, null]
var tree

var trees_removed = []
var stone_removed = []
var automatic_regrowing = -1

# tool bodies
var all_tools = []
var should_remove_towers = false

# array that stores level information
var lev = []
var sky_container = null
var portal = null

var background_samples = ["Soft Bird Whistle", "Loud Bird Whistle"]
var main_sample_player = null

func remove_tower(flip, num, pos):
	tower_info[flip][num] = 0
	relay_signal(-2)
	should_remove_towers = true

func restructure_tower():
	# first remove stuff at the top (in both columns)
	for j in range(2):
		while(tower_info[j].size() > 0 && tower_info[j][tower_info[j].size()-1] == 0):
			tower_info[j].pop_back()
	
	# then check for double emptiness
	var lowest_side = int(tower_info[1].size() < tower_info[0].size())
	var i = 0
	var get_towers = get_tree().get_nodes_in_group("TowerBlocks")
	while(i < tower_info[lowest_side].size()-1):
		if(tower_info[0][i] == 0 && tower_info[1][i] == 0):
			var get_position = tower_pos[0].y-i*tower_block_height
			tower_info[0].remove(i)
			tower_info[1].remove(i)
			for tower in get_towers:
				if(tower.get_pos().y < get_position):
					tower.set_pos(tower.get_pos()+Vector2(0,tower_block_height))
					tower.my_number -= 1
		i += 1
	
	# and check for single emptiness
	for j in range(2):
		var i = 0
		while(i < tower_info[j].size()-1):
			if(tower_info[j][i] == 0 && i >= tower_info[(j+1)%2].size()):
				var get_position = tower_pos[j].y-i*tower_block_height
				tower_info[j].remove(i)
				for tower in get_towers:
					if(tower.get_pos().y < get_position && tower.is_flipped == j):
						tower.set_pos(tower.get_pos()+Vector2(0,tower_block_height))
						tower.my_number -= 1
			i += 1
	
	# then reset the top tower blocks to the correct height
	tower_top_blocks[0].set_pos(Vector2(tower_top_blocks[0].get_pos().x, tower_pos[0].y-(tower_info[0].size()-1)*tower_block_height))
	tower_top_blocks[1].set_pos(Vector2(tower_top_blocks[1].get_pos().x, tower_pos[1].y-(tower_info[1].size()-1)*tower_block_height))

func create_new_tower(dir, pos):
	var grid_index = floor((tower_pos[0].y - pos.y) / tower_block_height)+1
	var convert_dir = 0
	var highest_point = [0,0]
	if(dir == -1):
		convert_dir = 1
	
	var all_towers = get_tree().get_nodes_in_group("TowerBlocks")
	for i in range(all_towers.size()):
		if(tower_info[convert_dir].size() > 0 && all_towers[i].my_number == (tower_info[convert_dir].size()-1) && int(all_towers[i].is_flipped) == convert_dir):
			if(all_towers[i].health < 0.75):
				relay_signal(-8)
				return
			break
	
	if(abs(pos.x-tower_pos[0].x) > 170):
		relay_signal(-7)
		return
	
	var is_top = false
	if(grid_index >= tower_info[convert_dir].size()):
		is_top = true
		highest_point[0] = tower_pos[0].y - (tower_info[0].size()-1)*tower_block_height
		highest_point[1] = tower_pos[1].y - (tower_info[1].size()-1)*tower_block_height
#		if((dir == -1 && abs(pos.y-highest_point_right) > 151) || (dir == 1 &&  abs(pos.y-highest_point_left) > 151)):
#			return
	elif(tower_info[convert_dir][grid_index] == 1):
		return
	
	# subtract resources, because new towers have to be bought!
	# towers cost 6 wood and 4 stone, or (if that's not available), 10 diamonds
	if(amount_resources[0] >= 6 && amount_resources[1] >= 4):
		amount_resources[0] -= 6
		amount_resources[1] -= 4
		gui_node.change_resource_display(amount_resources)
	#elif(amount_resources[2] >= 10):
	#	amount_resources[2] -= 10
	#	gui_node.change_resource_display(amount_resources)
	else:
		relay_signal(-1)
		return
	
	var new_block = tower_block.instance()
	
	if(is_top):
		new_block.set_pos(Vector2(tower_pos[convert_dir].x, highest_point[convert_dir]-tower_block_height))
		tower_top_blocks[convert_dir].set_pos(Vector2(tower_top_blocks[convert_dir].get_pos().x, highest_point[convert_dir]-tower_block_height))
		tower_info[convert_dir].append(1)
		new_block.my_number = tower_info[convert_dir].size()-1
	else:
		new_block.set_pos(Vector2(tower_pos[convert_dir].x, tower_pos[convert_dir].y-grid_index*tower_block_height))
		tower_info[convert_dir][grid_index] = 1
		new_block.my_number = grid_index
	if(dir == -1):
		new_block.flip()
	
	GLOBAL.highscore += 15
	add_child(new_block)

# -3 = grass side right, -2 = grass side left, -1 = grass, 0 = nothing, 1 = big stone, 2 = small stone, >3 = tree
func generate_level():
	cell_size = Vector2(grass_block_size.x, grass_block_size.y-15)
	lev_width = round(level_size.x/cell_size.x)
	lev_height = round(level_size.y*0.5/cell_size.y)
	
	# resize beforehand, to prevent complications
	lev.resize(lev_height)
	
	for i in range(lev_height):
		lev[i] = []
		lev[i].resize(lev_width)
		for j in range(lev_width):
			lev[i][j] = 0
	
	# complex stuff to decide where to place stuff
	for i in range(lev_height):
		for j in range(lev_width):
			if(i == 0):
				lev[i][j] = -1
			else:
				# if there's already a block underneath us, place a tree/stone/whatever
				if(lev[i-1][j] < 0):
					lev[i][j] = round(randf()*4.5-0.49)
				
				# this forbids blocks from being so close to each other (vertically) we don't fit
				# it DOES create a more empty, less playable map, so I wonder if I should keep it
				if(lev[i][j] == -1 && lev[i-2][j] < 0):
					lev[i][j] = 0
				
				if(lev[i][j] != -5):
					# if there's a single block to the left of us
					if(j > 1 && lev[i][j-1] < 0 && lev[i][j-2] >= 0):
						lev[i][j] = -1
					
					# if there's a single pair to the left of us
					if(j > 2 && lev[i][j-1] < 0 && lev[i][j-2] < 0 && lev[i][j-3] >= 0):
						lev[i][j] = -1
					
					# if there's a single trio to the left of us
					if(j > 3 && lev[i][j-1] < 0 && lev[i][j-2] < 0 && lev[i][j-3] < 0 && lev[i][j-4] >= 0):
						lev[i][j] = -1
					
					# if we have two empty spaces below us
					if(i > 2 && (lev[i-1][j] >= 0 || lev[i-1][j] == -5) && (lev[i-2][j] >= 0 || lev[i-2][j] == -5)):
						if(j == round(lev_width*0.5)-1 || j == round(lev_width*0.5)):
							lev[i][j] = 0
						elif(randf() > 0.2):
							lev[i][j] = -1
				else:
				# placement is forbidden
					lev[i][j] = 0
				
				# place block above tree, disallow all other tiles between it
				if(lev[i][j] == 3 || lev[i][j] == 4):
					lev[i][j] = 3 + round(randf()*2)
					var tree_top = i + round((292+96*(lev[i][j]+1))/cell_size.y)
					if(tree_top < (lev_height-1)):
						lev[tree_top][j] = -1
					for a in range(1, tree_top-1-i):
						if((i+a) < (lev_height-1)):
							lev[(i+a)][j] = -5
				# don't place anything over the tower
				if(j == round(lev_width*0.5)-1 || j == round(lev_width*0.5)):
					lev[i][j] = 0
	
	# clean up phase: remove ugly stuff, and turn edges into, well, edges
	for i in range(1,lev_height):
		for j in range(lev_width):
			if(lev[i][j] < 0):
				# left edge
				if(j == 0 || (j < lev_width-1 && lev[i][j-1] >= 0 && lev[i][j+1] < 0)):
					lev[i][j] = -2
				
				# right edge
				if(j == lev_width-1 || (j > 0 && lev[i][j+1] >= 0 && lev[i][j-1] < 0)):
					lev[i][j] = -3
				
				# no two blocks directly above each other?!
				if(i < (lev_height-1) && lev[i+1][j] < 0):
					lev[i][j] = 0
				
				# lonely platform - doesn't work, causes too much empty space and floating trees
				#if((j > 0 && lev[i][j-1] >= 0) && (j < (lev_width - 1) && lev[i][j+1] >= 0)):
				# 	lev[i][j] = 0

func create_level():
	# load trees, grass and stones
	stone_blocks[0] = preload("res://Scenes/StoneBlock1.tscn")
	stone_blocks[1] = preload("res://Scenes/StoneBlock2.tscn")
	stone_blocks[2] = preload("res://Scenes/StoneBlock3.tscn")
	stone_blocks[3] = preload("res://Scenes/StoneBlock4.tscn")
	
	var grass_block = preload("res://Scenes/GrassBlock.tscn")
	tree = preload("res://Scenes/Tree.tscn")
	var grass_side_block = preload("res://Scenes/GrassSideBlock.tscn")
	
	# place trees, according to previously generated level
	for i in range(lev_height):
		for j in range(lev_width):
			var cur_type = lev[i][j]
			var new_block = null
			var bonus_move = Vector2(0,0)
			
			if(cur_type == -3):
				new_block = grass_side_block.instance()
			elif(cur_type == -2):
				new_block = grass_side_block.instance()
				new_block.get_node("GrassSprite").set_flip_h(true)
			elif(cur_type == -1):
				new_block = grass_block.instance()
			elif(cur_type == 1):
				new_block = stone_blocks[round(randf())].instance()
				new_block.set_health(randf()*5+5, Vector2(i,j))
				var rand_scale = randf()*0.6+0.55
				new_block.set_scale(Vector2(rand_scale, rand_scale))
			elif(cur_type == 2):
				new_block = stone_blocks[round(randf())+2].instance()
				new_block.set_health(randf()*3+3, Vector2(i,j))
			elif(cur_type >= 3):
				new_block = tree.instance()
				new_block.set_health(cur_type-3, Vector2(i,j))
				bonus_move = Vector2(cell_size.x*(randf()*0.5+0.25), 0)
			
			if(cur_type != 0):
				new_block.set_pos(Vector2(j*cell_size.x, level_size.y-i*cell_size.y)+bonus_move)
				if(i == 0):
					new_block.add_to_group("Indestructibles")
				self.add_child(new_block)

func _ready():
	randomize()
	
	viewport_width = get_viewport().get_rect().size.width
	viewport_height = get_viewport().get_rect().size.height
	
	grass_block_size = Vector2(154, 92)
	grass_block_amount = 26 + GLOBAL.size*2
	var temp_level_height = 2500 + GLOBAL.size*25
	level_size = Vector2(grass_block_size.x*grass_block_amount, temp_level_height)
	
	# set parameters in SkyContainer
	sky_container = get_node("SkyContainer")
	sky_container.init_sky(level_size)
	
	ghost_helper = preload("res://Scenes/GhostHelper.tscn")
	portal = get_node("Portal")
	
	# intialize GUI stuff
	gui_node = get_node("GUI/Control")
	gui_node.change_health_display(0, 100)
	gui_node.change_health_display(1, 100)
	# initialize starting resources (based on chosen difficulty)
	# amount_resources = [1000, 1000, 1000]
	amount_resources = [max(58 - GLOBAL.difficulty*8, 0), max(24 - GLOBAL.difficulty*4, 0), max(5-GLOBAL.difficulty, 0)]
	gui_node.change_resource_display(amount_resources)
	
	warning_sign_scene = preload("res://Scenes/Sign.tscn")
	get_node("StreamPlayer").set_paused(!GLOBAL.music_enabled)
	
	# load monsters
	monsters[0] = preload("res://Scenes/Rhino.tscn")
	monsters[1] = preload("res://Scenes/Panda.tscn")
	monsters[2] = preload("res://Scenes/Monkey.tscn")
	monsters[3] = preload("res://Scenes/Elephant.tscn")
	monster_time_interval = 25
	
	# load dust particles
	dust_particles = preload("res://Scenes/DustParticles.tscn")
	diamond_piece = preload("res://Scenes/DiamondPiece.tscn")
	
	main_sample_player = get_node("MainSamplePlayer")
	
	# set camera limits
	main_camera = get_node("MainCamera")
	main_camera.set_limit(MARGIN_TOP, -100000)
	main_camera.set_limit(MARGIN_LEFT, 0)    
	main_camera.set_limit(MARGIN_RIGHT, level_size.x)
	main_camera.set_limit(MARGIN_BOTTOM, level_size.y)
	
	max_zoom = level_size.x/viewport_width
	
	tower_pos[0] = Vector2(level_size.x*0.5,level_size.y-92-135)
	tower_pos[1] = Vector2(level_size.x*0.5+155,level_size.y-92-135)
	
	# place tower top blocks
	var tower_top_block = preload("res://Scenes/TowerTopBlock.tscn")
	var new_block = tower_top_block.instance()
	new_block.set_pos(tower_pos[0])
	# add collision shape
	var shape = RectangleShape2D.new()
	shape.set_extents(Vector2(40,2))
	var m = Matrix32()
	m = m.translated(Vector2(-107, -3.6))
	new_block.get_child(0).add_shape(shape, m)
	# actually add the block
	self.add_child(new_block)
	tower_top_blocks[0] = new_block
	
	new_block = tower_top_block.instance()
	new_block.set_pos(tower_pos[1]+Vector2(10,0))
	# add collision shape + flip it!
	# remove_shape(0) removes it
	new_block.get_node("KinematicBody2D").flip()
	var shape = RectangleShape2D.new()
	shape.set_extents(Vector2(40,2))
	var m = Matrix32()
	m = m.translated(Vector2(-42, -3.6))
	new_block.get_child(0).add_shape(shape, m)
	self.add_child(new_block)
	tower_top_blocks[1] = new_block
	
	# place left starting towerblock
	tower_block = preload("res://Scenes/TowerBlock.tscn")
	var new_block = tower_block.instance()
	new_block.set_pos(tower_pos[0])
	new_block.my_number = 0
	new_block.add_to_group("Indestructibles")
	self.add_child(new_block)
	
	# place right starting towerblock
	var new_block = tower_block.instance()
	new_block.flip()
	new_block.my_number = 0
	new_block.set_pos(tower_pos[1])
	new_block.add_to_group("Indestructibles")
	self.add_child(new_block)
	
	portal.set_pos(Vector2(tower_pos[0].x, 0))
	
	generate_level()
	create_level()
	
	if(GLOBAL.night_mode):
		get_node("BG/BackgroundSolid").set_modulate(Color(0.05, 0.0125, 0.0125))
	else:
		get_node("MakeStuffDarker").queue_free()
	
	# randomly decide on starting tools
	var start_tools = [0,0]
	start_tools[0] = round(randf()*5.49)
	if(GLOBAL.multiplayer):
		var next_val = round(randf()*5.49)
		while (next_val == start_tools[0]):
			next_val = round(randf()*5.49)
		start_tools[1] = next_val
	else:
		start_tools[1] = start_tools[0]
	
	# place player 1 and 2
	var player_scene = preload("res://Scenes/Player.tscn")
	players[0] = player_scene.instance()
	players[0].player_num = 0
	if(GLOBAL.tutorial_mode):
		players[0].my_tool = 10
	else:
		players[0].my_tool = start_tools[0]
	players[0].button_names = ["ui_left", "ui_right", "ui_up", "ui_down", "ui_special", "ui_super_special"]
	players[0].set_pos(Vector2(new_block.get_pos().x, new_block.get_pos().y-300))
	self.add_child(players[0])
	
	if(GLOBAL.multiplayer):
		players[1] = player_scene.instance()
		players[1].player_num = 1
		players[1].my_tool = start_tools[1]
		players[1].button_names = ["ui_left_2", "ui_right_2", "ui_up_2", "ui_down_2", "ui_special_2", "ui_super_special_2"]
		players[1].set_pos(Vector2(new_block.get_pos().x-300, new_block.get_pos().y-300))
		self.add_child(players[1])
	else:
		gui_node.reduce_to_single_player()
		players[1] = players[0]
	
	var temp_player_center = Vector2((players[0].get_pos().x+players[1].get_pos().x)*0.5, (players[0].get_pos().y+players[1].get_pos().y)*0.5)
	main_camera.set_pos(temp_player_center)
	camera_movement()
	
	# create tools
	var load_tool = preload("res://Scenes/Tool.tscn")
	for i in range(6):
		var new_tool = load_tool.instance()
		new_tool.get_node("ToolSprite").set_frame(i)
		new_tool.set_pos(players[0].get_pos()+Vector2(-randf()*600,200))
		
		# if this is the starting tool for a player, make it disappear already
		if((i == start_tools[0] || i == start_tools[1]) && !GLOBAL.tutorial_mode):
			new_tool.hide()
		add_child(new_tool)
		all_tools.append(new_tool)
	
	# set (parallax) backgrounds to the correct position
	get_node("BackgroundForest").set_pos(Vector2(-500, level_size.y-grass_block_size.y*0.75))
	get_node("BackgroundForest").set_region_rect(Rect2(0, 3, level_size.x+1000, 925))
	
	get_node("BackgroundForestTwo").set_pos(Vector2(-500, level_size.y-grass_block_size.y*0.75))
	get_node("BackgroundForestTwo").set_region_rect(Rect2(0, 3, level_size.x+1000, 1636))
	
	# check viewport adjustments
	# original_view_rect = get_viewport().get_rect().size
	get_viewport().connect("size_changed", self, "resize")
	resize()
	
	set_fixed_process(true)
	set_process(true)

func resize():
	viewport_size = get_viewport().get_rect().size
	get_node("BG/BackgroundSolid").set_region_rect(Rect2(0,0,viewport_size.x, viewport_size.y))
	max_zoom = level_size.x/viewport_size.x
	gui_node.set_comp_scale(1024, viewport_size.x, viewport_size.y)

func drop_diamond(pos):
	var new_diam = diamond_piece.instance()
	new_diam.set_pos(pos)
	add_child(new_diam)
	pickables.append(new_diam)

func _process(delta):
	if(!GLOBAL.tutorial_mode):
		if(last_monster > monster_time_interval):
			add_monster()
		else:
			last_monster += delta
		
		gui_node.toggle_message(2)
	
	var center = main_camera.get_camera_screen_center()
	var variance = Vector2(viewport_size.x*0.5*main_camera.get_zoom().x, viewport_size.y*0.5*main_camera.get_zoom().y)
	
	if((players[0].get_pos().y - variance.y) < level_size.y*0.5 || (players[1].get_pos().y - variance.y) < level_size.y*0.5):
		sky_container.animate_objects()
		portal.animate_portal()
	
	if(automatic_regrowing >= 0):
		automatic_regrowing += delta
		if(automatic_regrowing > 5):
			replant_trees(1)
			replant_stones(1)
	
	general_timer += delta
	time_tracker += delta
	if(general_timer > 0.5):
		general_timer = 0
		gui_node.display_warning_signs(center, variance, get_viewport().get_rect().size, main_camera.get_zoom().x)

func _fixed_process(delta):
	camera_movement()
	
	if(pickables.size() > 0):
		check_pickables()
	
	if(players[0].my_tool == 10):
		if(Input.is_action_pressed(players[0].button_names[4])):
			check_tools(0)
	if(GLOBAL.multiplayer):
		if(players[1].my_tool == 10):
			if(Input.is_action_pressed(players[1].button_names[4])):
				check_tools(1)
	
	if(should_remove_towers):
		restructure_tower()
		should_remove_towers = false

func add_monster(n = -1):
	if(n == -1):
		n = round(((monsters.size() - 1) -0.02)*randf()-0.49)
		# only create elephants if we can actually get that high
		if(tower_top_blocks[0].get_pos().y < level_size.y * 0.5 || tower_top_blocks[1].get_pos().y < level_size.y * 0.5):
			n = round((monsters.size() -0.02)*randf()-0.49)
	var new_mon = monsters[n].instance()
	var starting_height = level_size.y-200
	if(n == 3):
		starting_height = level_size.y*0.5-randf()*600
	elif(!GLOBAL.tutorial_mode && randf() > 0.3):
		starting_height = level_size.y-200 - randf()*level_size.y*0.5
	
	# the monkey starts in a tree
	if(n == 2):
		var trees = get_tree().get_nodes_in_group("Trees")
		var rand_t = round(randf()*(trees.size()-1))
		new_mon.cur_tree = trees[rand_t]
		new_mon.set_pos(trees[rand_t].get_top_pos())
	# other monsters start at the edges
	else:
		if(randf() > 0.5):
			new_mon.set_pos(Vector2(0, starting_height))
			new_mon.walking_dir = 1
		else:
			new_mon.set_pos(Vector2(level_size.x, starting_height))
			new_mon.walking_dir = -1
	
	new_mon.initialize(self, level_size, warning_sign_scene)
	add_child(new_mon)
	
	# decrease interval between monsters every time a new monster is added
	# but keep a minimum level based on difficulty
	monster_time_interval -= randf()*GLOBAL.difficulty/5
	monster_time_interval = max(monster_time_interval, 6-GLOBAL.difficulty*0.33)
	last_monster = 0
	
	var rand_samp = background_samples[round(randf()*(background_samples.size()-1))]
	main_sample_player.set_pos(main_camera.get_pos()+Vector2(randf()*1000-500, randf()*800-400))
	main_sample_player.play(rand_samp)

func check_tools(n):
	var closest_dist = 10000
	var closest_num = -1
	var closest_frame = -1
	for i in range(all_tools.size()):
		var vec = players[n].get_pos() + Vector2(0,50) - all_tools[i].get_pos()
		var frame = all_tools[i].get_node("ToolSprite").get_frame()
		if(vec.length() < 100 && frame != players[(n+1)%2].my_tool && vec.length() < closest_dist):
			closest_frame = frame
			closest_num = i
			closest_dist = vec.length()
	
	if(closest_num != -1):
		players[n].change_tool(closest_frame)
		all_tools[closest_num].hide()

func check_pickables():
	# the count_nulls is a weird check to clear the pickables array and start with a clean slate
	# again, once we've picked up everything - I don't know any better way, stupid Godot.
	for player_num in range(2):
		var vec
		var count_nulls = 0
		for i in range(pickables.size()):
			if(pickables[i] == null):
				count_nulls += 1
				continue
			vec = players[player_num].get_pos() - pickables[i].get_pos()
			if(vec.length() < 150):
				pickables[i].apply_impulse(Vector2(0,0), vec*0.08)
				if(vec.length() < 100):
					# pick it up, and give us wood!
					if(pickables[i].is_in_group("WoodPieces")):
						change_resources(0, 1)
					elif(pickables[i].is_in_group("StonePieces")):
						change_resources(1, 1)
					elif(pickables[i].is_in_group("DiamondPieces")):
						change_resources(2, 1)
					pickables[i].queue_free()
					pickables[i] = null
		
		if(pickables.size() == count_nulls):
			pickables.clear()
			break

func change_resources(type, amount):
	amount_resources[type] += amount
	gui_node.change_resource_display(amount_resources)

func create_dust(pos, dir):
	var new_dust = dust_particles.instance()
	new_dust.set_pos(pos)
	new_dust.set_param(Particles2D.PARAM_DIRECTION, dir*90)
	new_dust.set_param(Particles2D.PARAM_LINEAR_VELOCITY, 200)
	new_dust.set_explosiveness(0.01)
	new_dust.set_emission_half_extents(Vector2(0,25))
	new_dust.set_emitting(true)
	self.add_child(new_dust)
	new_dust.should_time = true

func end_game(result):
	GLOBAL.game_time = time_tracker
	if(result == "win"):
		GLOBAL.game_over = 1
		GLOBAL.highscore += 5000
		var root = get_tree().get_root()
		var cur_sc = root.get_child(root.get_child_count() - 1)
		cur_sc.queue_free()
		get_tree().change_scene("res://GameOver.tscn")
	elif(result == "lose"):
		GLOBAL.game_over = 0
		var root = get_tree().get_root()
		var cur_sc = root.get_child(root.get_child_count() - 1)
		if(GLOBAL.night_mode):
			get_node("MakeStuffDarker").free()
		cur_sc.queue_free()
		get_tree().change_scene("res://GameOver.tscn")

func toggle_split_screen(enable, num, which_player):
	if(enable == 1):
		split_screen = num
		split_screen_side = (players[(num+1)%2].get_pos().x > players[num].get_pos().x)
		gui_node.handle_split_screen(viewport_width, split_screen_side)
		gui_node.change_buying_description()
	elif(enable == 0):
		var costs = gui_node.get_costs()
		var buying_allowed = false
		if(amount_resources[0] >= costs[0] && amount_resources[1] >= costs[1] && amount_resources[2] >= costs[2]):
			buying_allowed = true
		if(buying_allowed):
			buy_something(which_player)

func buy_something(which_player):
	var costs = gui_node.get_costs()
	players[which_player].currently_buying = false
	amount_resources[0] -= costs[0]
	amount_resources[1] -= costs[1]
	amount_resources[2] -= costs[2]
	gui_node.change_resource_display(amount_resources)
	var the_item = gui_node.get_item()
	if(the_item == 1):
		# replant trees!
		replant_trees(5)
		relay_signal(-9)
	elif(the_item == 2):
		# recreate stones!
		replant_stones(5)
		relay_signal(-10)
	elif(the_item == 3):
		# make player faster
		players[which_player].WALK_SPEED = min(players[which_player].WALK_SPEED+50, 700)
		players[which_player].CLIMB_SPEED = players[which_player].WALK_SPEED*0.5
		GLOBAL.highscore += 7
		relay_signal(-11)
	elif(the_item == 4):
		# add a life to this player!
		players[which_player].change_health(100)
		GLOBAL.highscore += 7
		relay_signal(-12)
	elif(the_item == 5):
		# place automatic weaponry
		var new_ghost = ghost_helper.instance()
		new_ghost.set_pos(players[which_player].get_pos())
		add_child(new_ghost)
		GLOBAL.highscore += 10
		relay_signal(-13)
	elif(the_item == 6):
		# make player's weapons stronger
		players[which_player].WEAPON_STRENGTH = min(players[which_player].WEAPON_STRENGTH+1, 4)
		GLOBAL.highscore += 7
		relay_signal(-14)
	elif(the_item == 7):
		# make towerblocks stronger
		GLOBAL.max_tower_health = min(GLOBAL.max_tower_health+1, 8)
		get_tree().call_group(0, "TowerBlocks", "update_health")
		GLOBAL.highscore += 10
		relay_signal(-15)
	elif(the_item == 8):
		# set automatic regrowing system working
		automatic_regrowing = 0
		relay_signal(-16)
	
	split_screen = -1
	split_screen_side = -1
	gui_node.get_node("BuyingMenu").hide()

func replant_trees(n):
	var max_trees = min(trees_removed.size(), n)
	for a in range(max_trees):
		var new_block = tree.instance()
		var j = trees_removed[a].y
		var i = trees_removed[a].x
		var old_height = lev[i][j]
		new_block.set_health(old_height-3, trees_removed[a])
		var bonus_move = Vector2(cell_size.x*(randf()*0.5+0.25), 0)
		new_block.set_pos(Vector2(j*cell_size.x, level_size.y-i*cell_size.y)+bonus_move)
		self.add_child(new_block)
	for a in range(max_trees):
		trees_removed.pop_front()
	GLOBAL.highscore += n

func replant_stones(n):
	var max_stones = min(stone_removed.size(), n)
	for a in range(max_stones):
		var new_block = stone_blocks[round(randf())].instance()
		var j = stone_removed[a].y
		var i = stone_removed[a].x
		var old_height = lev[i][j]
		new_block.set_health(randf()*5+5, stone_removed[a])
		new_block.set_pos(Vector2(j*cell_size.x, level_size.y-i*cell_size.y))
		var rand_scale = randf()*0.6+0.55
		new_block.set_scale(Vector2(rand_scale, rand_scale))
		self.add_child(new_block)
	for a in range(max_stones):
		stone_removed.pop_front()
	GLOBAL.highscore += n

func update_level(pos, type):
	if(type == "tree"):
		trees_removed.push_back(pos)
	elif(type == "stone"):
		stone_removed.push_back(pos)

# this is used so that I don't need to keep a reference to the messages node EVERYWHERE
func relay_signal(num):
	get_node("Messages").send_signal(num)

func camera_movement():
	var player_center
	if(split_screen > -1):
		# split screen is set to number of the other player (the one that's being followed)
		player_center = players[split_screen].get_pos()+Vector2((split_screen_side-0.5)*viewport_width*0.5,0)
		main_camera.set_zoom(Vector2(1,1))
	else:
		# make sure both players are in view, at all times
		player_center = Vector2((players[0].get_pos().x+players[1].get_pos().x)*0.5, (players[0].get_pos().y+players[1].get_pos().y)*0.5)+Vector2(0,-10)
		var desired_zoom_x = (abs(players[0].get_pos().x - players[1].get_pos().x))/viewport_width
		var desired_zoom_y = (abs(players[0].get_pos().y - players[1].get_pos().y)+100)/viewport_height
		var desired_zoom = min(max(max(desired_zoom_x*1.3, desired_zoom_y*1.3), 1), max_zoom)
		main_camera.set_zoom(Vector2(desired_zoom, desired_zoom))
	
	if(external_change_zoom != 0):
		var desired_zoom = min(max(main_camera.get_zoom().x+external_change_zoom, 1), max_zoom)
		main_camera.set_zoom(Vector2(desired_zoom, desired_zoom))
	
	var old_pos = main_camera.get_pos()
	main_camera.set_pos(player_center)
	
	if(!(player_center.x < 0.5*get_viewport().get_rect().size.x || player_center.x > level_size.x-0.5*get_viewport().get_rect().size.x )):
		get_node("BackgroundForest").set_pos(get_node("BackgroundForest").get_pos()+Vector2((player_center.x - old_pos.x)*0.35/main_camera.get_zoom().x, 0))
		get_node("BackgroundForestTwo").set_pos(get_node("BackgroundForestTwo").get_pos()+Vector2((player_center.x - old_pos.x)*0.25, 0))

