
extends KinematicBody2D

var velocity = Vector2(0,0)
var GRAVITY = 2200.0
var FORWARD_SPEED = 250
var particle_node = null
var anim_player = null
var walking_dir = 1
var status = 0
var dynamite = null
var main_node = null
var hit_color = 0
var health = 2
var death_limit = 0
var dying = false
var dropped_one = false
var sample_player = null

var warning_sign = null

func initialize(main, lev_height, warn_sign):
	main_node = main #get_tree().get_root().get_node("Main")
	death_limit = lev_height.y+100
	warning_sign = warn_sign.instance()
	main.get_node("GUI/Control/WarningSigns").add_child(warning_sign)
	sample_player = get_node("SamplePlayer2D")
	warning_sign.hide()
	health = 2*ceil(GLOBAL.difficulty/10)

func _ready():
	set_fixed_process(true)
	set_process(true)
	particle_node = get_node("DustParticles")
	anim_player = get_node("Sprite/AnimationPlayer")
	if(walking_dir == 1):
		get_node("Sprite").set_flip_h(true)
	if(walking_dir == 1):
		anim_player.play_backwards("Roll")
	else:
		anim_player.play("Roll")

func _fixed_process(delta):
	velocity.y += delta * GRAVITY
	if(status == 0):
		velocity.x = FORWARD_SPEED*walking_dir
		if(!sample_player.is_voice_active(0)):
			sample_player.play("Foliage")
	else:
		sample_player.stop_voice(0)
		velocity.x = 0
	var motion = velocity * delta
	motion = move(motion)
	
	if(is_colliding()):
		var n = get_collision_normal()
		motion = n.slide(motion)
		velocity = n.slide(velocity)
		move(motion)
		particle_node.set_emitting(true)
	else:
		particle_node.set_emitting(false)

func _process(delta):
	if(get_pos().y > death_limit && health > 0):
		if(dynamite != null):
			dynamite.explode()
		set_process(false)
		set_fixed_process(false)
		change_health(-10, true)
	
	# hitting feedback
	if(hit_color > 0):
		get_node("Sprite").set_modulate(Color(1.0, 1.0-hit_color, 1.0-hit_color))
		hit_color -= 0.01

func change_health(n, off_field = false):
	if(dying):
		return
	health += n
	hit_color = 0.5
	if(health <= 0):
		GLOBAL.highscore += 20
		if(warning_sign != null):
			warning_sign.queue_free()
			warning_sign = null
		dying = true
		main_node.relay_signal(-5)
		main_node.relay_signal(18)
		if(dynamite != null && !off_field):
			dynamite.panda_died()
			dynamite = null
		move(Vector2(0,-200))
		get_node("CollisionShape2D").set_trigger(true)
		if(!off_field):
			main_node.drop_diamond(get_pos())

func revolt(x, y):
	pass

func drop():
	if(dying):
		return
	status = 0
	anim_player.stop()
	# DROP THA BOMB
	dynamite = load("res://Scenes/Dynamite.tscn").instance()
	dynamite.set_pos(get_pos()+Vector2(walking_dir*-150,-50))
	main_node.add_child(dynamite)
	
	if(walking_dir == 1):
		anim_player.play_backwards("Roll")
	else:
		anim_player.play("Roll")

func _on_Area2D_body_enter(body):
	if(body.is_in_group("Arrows")):
		change_health(-1*body.MY_STRENGTH)
		body.queue_free()
	elif(body.is_in_group("TowerBlocks")):
		if(dropped_one):
			return
		walking_dir *= -1
		if(walking_dir == 1):
			get_node("Sprite").set_flip_h(true)
		else:
			get_node("Sprite").set_flip_h(false)
		status = 1
		dropped_one = true
		anim_player.play("Drop")

