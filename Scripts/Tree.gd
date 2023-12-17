
extends StaticBody2D

var health = 0
var start_health = 0
var wood_piece = null
var random_val
var trunk_height
var multiplier = 0.01
var falling_dir = 0
var my_pos = Vector2(0,0)
var main_node = null
var has_exploded = false
var timer = 0
var dying = false
var torch = null

func set_health(n, pos):
	my_pos = pos
	
	var trunk = get_node("Trunk")
	var top = get_node("Top")
	trunk_height = trunk.get_item_rect().size.y-3
	random_val = n
	var current_pos = Vector2(trunk.get_pos().x, trunk.get_pos().y)
	var old_current_pos = current_pos
	
	var flip_switch = 0
	for i in range(random_val):
		var new_trunk = trunk.duplicate()
		current_pos.y -= trunk_height
		new_trunk.set_flip_h(flip_switch)
		new_trunk.set_pos(Vector2(current_pos.x+flip_switch*4, current_pos.y))
		flip_switch = (flip_switch+1)%2
		self.add_child(new_trunk)
	top.set_pos(Vector2(top.get_pos().x, current_pos.y-trunk_height))
	
	if(GLOBAL.night_mode):
		var new_torch = preload("res://Scenes/Torch.tscn")
		torch = new_torch.instance()
		torch.set_pos(old_current_pos)
		torch.get_node("Particles2D").set_emitting(false)
		torch.get_node("Particles2D/Particles2D").set_emitting(false)
		torch.hide()
		add_child(torch)
	
	health = random_val+randf()*10
	start_health = health
	wood_piece = preload("res://Scenes/WoodPiece.tscn")

func get_top_pos():
	return self.get_pos()+get_node("Top").get_pos()-Vector2(-10,87)

func get_sprite_z():
	return get_node("Top").get_z()

func turn_light(on):
	if(on):
		torch.get_node("Particles2D").set_emitting(true)
		torch.get_node("Particles2D/Particles2D").set_emitting(true)
		torch.show()
	else:
		torch.get_node("Particles2D").set_emitting(false)
		torch.get_node("Particles2D/Particles2D").set_emitting(false)
		torch.hide()

func explode_leafs():
	get_node("Top/LeafParticles").set_emitting(true)
	multiplier = 0.0125
	timer = 0
	has_exploded = true
	if(!GLOBAL.night_mode):
		set_process(true)

func stop_exploding_leafs():
	get_node("Top/LeafParticles").set_emitting(false)
	has_exploded = false

func _process(delta):
	# for monkey business
	if(timer >= 0):
		timer += delta
		set_rot(get_rot()+multiplier)
		multiplier *= -1
		if(timer > 0.15):
			timer = -1
			set_rot(0)
			set_process(false)
		return
	
	# for dying
	set_rot(get_rot()+multiplier)
	multiplier += 0.01*falling_dir*delta
	if(abs(get_rot()) > PI*0.5):
		var tree_length = trunk_height*random_val + 700
		#tree should shatter into wood pieces
		main_node.update_level(my_pos, "tree")
		for i in range(start_health):
			var new_piece = wood_piece.instance()
			new_piece.set_pos(get_pos()-Vector2(tree_length*randf()*falling_dir,200))
			new_piece.apply_impulse(Vector2(0,0), Vector2(randf()*200-100, -randf()*500))
			main_node.pickables.append(new_piece)
			main_node.add_child(new_piece)
		set_process(false)
		self.queue_free()

func change_health(change, dir):
	if(health > 0):
		health += change
		set_rot(get_rot()+multiplier)
		multiplier *= -1
	
	if(health <= 0 && falling_dir == 0):
		GLOBAL.highscore += 3
		dying = true
		if(dir == 1):
			multiplier = 0.001
		else:
			multiplier = -0.001
		falling_dir = dir
		timer = -1
		main_node = get_tree().get_root().get_node("Main")
		main_node.relay_signal(9)
		set_process(true)


