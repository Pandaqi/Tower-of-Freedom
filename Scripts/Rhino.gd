
extends KinematicBody2D

var velocity = Vector2(0,0)
var GRAVITY = 2200.0
var extra_jump = 0
var FORWARD_SPEED = 150
var walking_dir
var anim_player = null
var health = 2
var hit_color = 0
var particle_node = null
var dying = false
var main_node = null
var idle_period = 0
var last_distance = 0
var sample_player = null

var death_limit = 0
var warning_sign = null

func initialize(main, lev_height, warn_sign):
	main_node = main
	death_limit = lev_height.y+100
	warning_sign = warn_sign.instance()
	main.get_node("GUI/Control/WarningSigns").add_child(warning_sign)
	warning_sign.hide()
	health = 2*ceil(GLOBAL.difficulty/10)
	FORWARD_SPEED = 175 + (GLOBAL.difficulty/10)*125
	
	sample_player = get_node("SamplePlayer2D")

func _ready():
	anim_player = get_node("Sprite/AnimationPlayer")
	particle_node = get_node("DustParticles")
	FORWARD_SPEED = FORWARD_SPEED*walking_dir
	if(walking_dir == 1):
		get_node("Sprite").set_flip_h(true)
	set_fixed_process(true)
	set_process(true)

func _fixed_process(delta):
	# regular movement, animations, and gravity addition
	velocity.y += delta * GRAVITY
	var motion = velocity * delta
	motion = move(motion)
	if(!dying):
		if (is_colliding()):
			if(idle_period > 0):
				velocity.x = 0
				anim_player.stop()
				get_node("Sprite").set_frame(0)
				idle_period -= delta
			elif(anim_player.get_current_animation() != "Jump"):
				sample_player.play("Explosion")
				if(randf() > 0.95):
					idle_period = randf()*6
				else:
					if(get_pos().x - last_distance <= 10):
						extra_jump += 20
						velocity.x += 20
					if(extra_jump >= 100):
						extra_jump = 0
					last_distance = get_pos().x
					velocity.x = 0
					anim_player.play("Jump")
			var n = get_collision_normal()
			motion = n.slide(motion)
			velocity = n.slide(velocity)
			move(motion)
			particle_node.set_emitting(true)
		else:
			particle_node.set_emitting(false)

func _process(delta):
	if(dying):
		anim_player.stop()
		get_node("Sprite").set_frame(1)
		get_node("Sprite").set_rot(get_node("Sprite").get_rot()+0.04*walking_dir)
		set_opacity(get_opacity()-0.04)
		if(get_opacity() <= 0):
			main_node.drop_diamond(get_pos())
			set_process(false)
			set_fixed_process(false)
			self.queue_free()
	
	if(get_pos().y > death_limit):
		change_health(-10)
	
	# hitting feedback
	if(hit_color > 0):
		get_node("Sprite").set_modulate(Color(1.0, 1.0-hit_color, 1.0-hit_color))
		hit_color -= 0.01

func revolt(dirX, dirY):
	move(Vector2(dirX*0.25, dirY*0.25))

func change_health(n):
	if(idle_period > 0):
		return
	health += n
	hit_color = 0.3
	if(health <= 0):
		if(warning_sign != null):
			warning_sign.queue_free()
			warning_sign = null
		main_node.relay_signal(15)
		main_node.relay_signal(-4)
		dying = true
		GLOBAL.highscore += 10

func jump():
	if(!dying):
		velocity.y = -GRAVITY*0.3-extra_jump
		velocity.x = FORWARD_SPEED
		anim_player.play("MidAir")

func _on_Area2D_body_enter(body):
	if(body.is_in_group("Arrows")):
		revolt(body.get_linear_velocity().x, 0)
		change_health(-1*body.MY_STRENGTH)
		body.queue_free()
	if(body.is_in_group("TowerBlocks")):
		change_health(-4)
		idle_period = -1
		sample_player.play("Explosion")
		body.change_health(-1)
		var dustSide = 0
		if get_pos().x < body.get_pos().x:
			dustSide = -150
		main_node.create_dust(body.get_pos()+Vector2(dustSide,50), -walking_dir)
