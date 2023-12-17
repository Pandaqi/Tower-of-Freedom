
extends KinematicBody2D

var warning_sign
var main_node
var timer = 0
var cur_tree = null
var cur_tree_ref = null
var GRAVITY = 1000
var velocity = Vector2(0,0)
var my_sprite = null
var health = 1
var dying = false
var death_limit = 0
var walking_dir = 0
var sample_player = null

func _ready():
	my_sprite = get_node("Sprite")
	set_fixed_process(true)

func initialize(main, lev_height, warn_sign):
	main_node = main
	warning_sign = warn_sign.instance()
	main.get_node("GUI/Control/WarningSigns").add_child(warning_sign)
	warning_sign.hide()
	death_limit = lev_height.y + 100
	sample_player = get_node("SamplePlayer2D")
	health = ceil(GLOBAL.difficulty/5)

func _fixed_process(delta):
	# for movement
	if(cur_tree != null):
		if(cur_tree_ref != null && !cur_tree_ref.get_ref() || cur_tree.dying):
			change_health(-10)
			cur_tree = null
			return
		
		if(cur_tree.has_exploded):
			cur_tree.stop_exploding_leafs()
	
	if(timer == -1 || timer == -2):
		velocity.y += delta * GRAVITY
		var motion = velocity * delta
		move(motion)
		
		if(velocity.x >= 0):
			my_sprite.set_flip_h(true)
			walking_dir = 1
		else:
			my_sprite.set_flip_h(false)
			walking_dir = -1
		
		if(timer == -1):
			if((cur_tree.get_top_pos() - self.get_pos()).length() < motion.length()*3):
				cur_tree.explode_leafs()
				my_sprite.set_z(cur_tree.get_sprite_z()+1)
				timer = 0
				my_sprite.set_frame(1)
				self.set_pos(cur_tree.get_top_pos())
		
		if(dying):
			my_sprite.set_rot(my_sprite.get_rot()+0.08*walking_dir)
			set_opacity(get_opacity()-0.08)
			if(get_opacity() <= 0):
				main_node.drop_diamond(get_pos())
				set_fixed_process(false)
				self.queue_free()
		return
	
	# timer, for jumping and showing/hiding
	timer += delta
	if(timer >= 5):
		self.show()
		timer = -1
		jump_tree()
	elif(timer > 2 && timer < 5):
		self.hide()
	
	if(get_pos().y > death_limit):
		change_health(-10)

func jump_tree():
	sample_player.play("Monkey")
	var trees = get_tree().get_nodes_in_group("Trees")
	var closest_tree = null
	var dist = 10000000
	var my_tower_dist = abs(get_pos().x - main_node.tower_pos[0].x)
	for i in range(trees.size()):
		if((trees[i].get_top_pos().x - self.get_pos().x) == 0):
			continue
		var temp_tower_dist = abs(trees[i].get_top_pos().x - main_node.tower_pos[0].x)
		if(temp_tower_dist < my_tower_dist):
			var temp_dist = (self.get_pos()-trees[i].get_top_pos()).length()
			if(temp_dist < dist):
				dist = temp_dist
				closest_tree = trees[i]
	
	velocity = Vector2(0,0)
	cur_tree.explode_leafs()
	if(closest_tree == null):
		# no tree closer, attack tower!
		velocity.x = (main_node.tower_pos[0].x - self.get_pos().x)
		my_sprite.set_frame(2)
		timer = -2
	else:
		my_sprite.set_z(cur_tree.get_sprite_z()-1)
		my_sprite.set_frame(2)
		var timi = 1.0
		velocity.x = float(closest_tree.get_top_pos().x - self.get_pos().x)/timi
		velocity.y = float(closest_tree.get_top_pos().y - self.get_pos().y)/timi - 0.5 * timi * GRAVITY
		cur_tree = closest_tree
		cur_tree_ref = weakref(closest_tree)

func change_health(n):
	if(dying):
		return
	health += n
	if(health <= 0):
		main_node.relay_signal(-6)
		timer = -2
		dying = true
		warning_sign.queue_free()
		warning_sign = null
		GLOBAL.highscore += 30

func _on_Area2D_body_enter( body ):
	if(dying):
		return
	if(body.is_in_group("TowerBlocks")):
		body.change_health(-4)
		sample_player.play("Explosion")
		main_node.create_dust(body.get_pos()+Vector2(-150+body.is_flipped*150,50), -walking_dir)
		self.change_health(-1)
	elif(body.is_in_group("Players") && self.is_visible()):
		body.change_health(-50-randf()*100)
		self.change_health(-1)
	elif(body.is_in_group("Arrows")):
		body.queue_free()
		self.change_health(-1*body.MY_STRENGTH)
