
extends Control

# STUFF FOR BUTTONS
func _on_TutorialButton_pressed():
	# set some global variables, then start game
	GLOBAL.multiplayer = false
	set_options()
	GLOBAL.tutorial_mode = true
	load_scene("res://Main.tscn")

func _on_SinglePlayerButton_pressed():
	# set some global variables, then start game
	GLOBAL.multiplayer = false
	set_options()
	GLOBAL.tutorial_mode = false
	load_scene("res://Main.tscn")

func _on_MultiPlayerButton_pressed():
	# set some global variables differently, then start game
	GLOBAL.multiplayer = true
	set_options()
	GLOBAL.tutorial_mode = false
	load_scene("res://Main.tscn")

func _on_ExitButton_pressed():
	get_tree().quit()

func _on_MusicCheck_toggled( pressed ):
	GLOBAL.music_enabled = pressed

func _on_FullscreenCheck_toggled( pressed ):
	OS.set_window_fullscreen(pressed)

func _on_PlayButton_pressed():
	set_new_scene()

func set_options():
	GLOBAL.night_mode = get_node("CanvasLayer/MainMenu/Options/NightModeCheck").is_pressed()
	GLOBAL.difficulty = get_node("CanvasLayer/MainMenu/Options/DifficultySlider").get_value()
	GLOBAL.size = get_node("CanvasLayer/MainMenu/Options/SizeSlider").get_value()
	GLOBAL.max_tower_health = 4
	GLOBAL.highscore = 0

# STUFF FOR LOADING SCREEN
var loader
var wait_frames
var time_max = 100 # msec
var current_scene

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)
	
	# original_view_rect = root.get_rect().size
	get_viewport().connect("size_changed", self, "resize_canvas")
	
	resize_canvas()

func resize_canvas():
	var viewport_dim = get_viewport().get_rect().size
	self.set_size(viewport_dim)
	
	get_node("DarkBackground/Sprite").set_scale(Vector2(50,30)*viewport_dim/600)
	get_node("TextureFrame").set_pos(Vector2(0, viewport_dim.y+20))
	
	get_node("CanvasLayer/MainMenu/Torch").set_pos(Vector2(0.1*viewport_dim.x,0.6*viewport_dim.y))
	get_node("CanvasLayer/MainMenu/Torch1").set_pos(Vector2(0.9*viewport_dim.x,0.6*viewport_dim.y))
	
	if(GLOBAL.game_over == -1):
		get_node("CanvasLayer/MainMenu/VBoxContainer").set_pos(viewport_dim*0.5 - Vector2(150, 140))
		get_node("CanvasLayer/MainMenu/RichTextLabel").set_pos(Vector2(viewport_dim.x*0.5-150, 0.5*viewport_dim.y - 150))
		get_node("CanvasLayer/MainMenu/Options/FullscreenCheck").set_pressed(OS.is_window_fullscreen())
		
		var find_scale = min(viewport_dim.x/1025, viewport_dim.y/600)
		get_node("CanvasLayer/LoadingScreen").set_scale(Vector2(find_scale, find_scale))
		get_node("CanvasLayer/MainMenu/Options").set_pos(viewport_dim*0.5 + Vector2(0,150))
	else:
		get_node("CanvasLayer/MainMenu/VBoxContainer").set_pos(viewport_dim*0.5 - Vector2(174, 140))
		if(GLOBAL.game_over == 0):
			get_node("CanvasLayer/MainMenu/VBoxContainer/Label").set_text("Game Over!")
		else:
			get_node("CanvasLayer/MainMenu/VBoxContainer/Label").set_text("You Win!")
			get_node("SamplePlayer2D").play("Victory")
		get_node("CanvasLayer/MainMenu/VBoxContainer/HBoxContainer/Time Spent").set_text(str(round(GLOBAL.game_time*100)/100.0))
		get_node("CanvasLayer/MainMenu/VBoxContainer/HBoxContainer 2/Highscore").set_text(str(GLOBAL.highscore))

# game requests to switch to this scene
func load_scene(path):
	loader = ResourceLoader.load_interactive(path)
	 # check for errors
	if loader == null:
		show_error()
		return
	
	# process will take care of displaying any animations
	set_process(true)
	
	get_node("CanvasLayer/LoadingScreen").show()
	get_node("CanvasLayer/MainMenu").hide()
	
	wait_frames = 1

func set_new_scene():
	var scene_resource = loader.get_resource()
	loader = null
	
	# get rid of the old scene
	get_node("MakeStuffDark").free()
	current_scene.queue_free() 
	
	# instance new one
	current_scene = scene_resource.instance()
	get_node("/root").add_child(current_scene)

func update_progress():
	pass

func show_error():
	print("ERROR!")

func _process(time):
	# no need to process anymore
	if loader == null:
		set_process(false)
		return
	# wait for frames to let the "loading" animation to show up
	if wait_frames > 0: 
		wait_frames -= 1
		return
	
	var t = OS.get_ticks_msec()
	while OS.get_ticks_msec() < t + time_max: # use "time_max" to control how much time we block this thread
		# poll your loader
		var err = loader.poll()
		if err == ERR_FILE_EOF: # load finished
			get_node("CanvasLayer/LoadingScreen/RichTextLabel").hide()
			get_node("CanvasLayer/LoadingScreen/PlayButton").show()
			set_process(false)
			break
		elif err == OK:
			update_progress()
		else: # error during loading
			show_error()
			loader = null
			break

# GAME OVER MENU BUTTONS
func _on_ReplayButton_pressed():
	GLOBAL.game_over = -1
	get_tree().change_scene("res://Main.tscn")

func _on_BackButton_pressed():
	GLOBAL.game_over = -1
	get_tree().change_scene("res://Menu.tscn")
