
extends KinematicBody2D

var main_node = null
var warning_sign = null
var my_sprite = null
var velocity = Vector2(0,0)
var state
var GRAVITY = 400
var WALKING_SPEED = 200
var timer = 0
var lev_width
var walking_dir
var health = 2
var dying = false
var num_players = 1
var sample_player = null
var hit_color = 0

func _ready():
	my_sprite = get_node("Sprite")
	state = 0
	my_sprite.set_frame(2)
	velocity.x = WALKING_SPEED*walking_dir
	velocity.y = -GRAVITY
	if(walking_dir == -1):
		get_node("Sprite").set_flip_h(true)
		get_node("AirParticles").set_pos(Vector2(-126, -15))
		get_node("AirParticles").set_param(0, -90)
	set_fixed_process(true)
	set_process(true)

func initialize(main, lev_height, warn_sign):
	main_node = main
	lev_width = lev_height.x
	warning_sign = warn_sign.instance()
	main.get_node("GUI/Control/WarningSigns").add_child(warning_sign)
	warning_sign.hide()
	sample_player = get_node("SamplePlayer2D")
	health = 1*ceil(GLOBAL.difficulty/4)
	if(GLOBAL.multiplayer):
		num_players = 2

func _fixed_process(delta):
	if(dying):
		velocity.y = -350
		var motion = velocity * delta
		set_opacity(get_opacity()-delta)
		move(motion)
		if(get_opacity() <= 0):
			set_fixed_process(false)
			set_process(false)
			self.queue_free()
		return
	
	# gravity stuff
	velocity.y += delta * GRAVITY
	var motion = velocity * delta
	move(motion)

func _process(delta):
	# every one second, change state (between jumping up and floating down)
	timer += delta
	if(timer > 1):
		timer = 0
		# jump UP!
		if(state == 1):
			velocity.y = -GRAVITY
			my_sprite.set_frame(1)
			state = 0
		# float DOWN
		elif(state == 0):
			state = 1
			my_sprite.set_frame(2)
	
	# check if there's a player in front of us - if so, blow him off the tower!
	for i in range(num_players):
		var cur_p = main_node.players[i]
		if((cur_p.get_pos()-self.get_pos()).length() > 300):
			continue
		if((walking_dir == 1 && cur_p.get_pos().x > self.get_pos().x) || (walking_dir == -1 && cur_p.get_pos().x < self.get_pos().x)):
			get_node("AirParticles").set_emitting(true)
			if(!sample_player.is_voice_active(0)):
				sample_player.play("Air Blowing")
			cur_p.extra_force = 800*walking_dir
			cur_p.change_health(randf()*(-15))
			my_sprite.set_frame(3)
	
	# hitting feedback
	if(hit_color > 0):
		get_node("Sprite").set_modulate(Color(1.0, 1.0-hit_color, 1.0-hit_color))
		hit_color -= 0.01
	
	# automatically die when off stage
	if(get_pos().x < -400 || get_pos().x > lev_width+400):
		change_health(-2)

func change_health(n):
	if(dying):
		return
	health += n
	hit_color = 0.3
	if(health <= 0):
		velocity.x *= -3.5
		my_sprite.set_frame(0)
		dying = true
		main_node.drop_diamond(get_pos())
		warning_sign.queue_free()
		warning_sign = null
		GLOBAL.highscore += 40

func _on_Area2D_body_enter( body ):
	if(dying):
		return
	# we hit a player, blow him away!
	if(body.is_in_group("TowerBlocks")):
		body.change_health(-7)
		sample_player.play("Explosion")
		main_node.create_dust(body.get_pos()+Vector2(-150+body.is_flipped*150,50), -walking_dir)
		self.change_health(-3)
	elif(body.is_in_group("Arrows")):
		body.queue_free()
		self.change_health(-1*body.MY_STRENGTH)

