
extends Control

var split_screen_side = -1
var shop_pos = Vector2(0,0)
var shop_jumps_x = 170
var shop_jumps_y = 170
var shop_anchor = Vector2(5, 117)

var cost_dict = [
[0,0,0], [0,0,3], [0,0,6], 
[10, 10, 4], [15, 15, 8], [20, 20, 10],
[20, 20, 12], [25, 25, 16], [40, 40, 25]]
var store_desc = [
"Leave store without buying", 
"Regrow 5 trees", 
"Regrow 5 stones", 
"Gain extra speed", 
"Regain one life", 
"Buy your own automatic ghost soldier",
"Make weapons more effective", 
"Give your towerblocks extra health",
"Automatically regrow trees and stones over time"
]

var buttons = ["LeaveButton", "WoodButton", "StoneButton", "SpeedButton", "LivesButton", "DefenseButton", "WeaponsButton", "TowerHealthButton", "RegrowButton"]

func change_resource_display(r):
	get_node("Resources/WoodText").set_text(str(r[0]))
	get_node("Resources/StoneText").set_text(str(r[1]))
	get_node("Resources/DiamondText").set_text(str(r[2]))

func change_health_display(n, new_val):
	get_node(str("Player", (n+1), "Health")).get_child(0).set_scale(Vector2(new_val/100*4,0.5))

func reduce_to_single_player():
	get_node("Player2Health").queue_free()

func change_lives_display(n, new_val):
	var node = get_node(str("Player", (n+1), "Health"))
	for i in range(3):
		if(i < new_val):
			node.get_node(str("Life", (i+1))).show()
		else:
			node.get_node(str("Life", (i+1))).hide()

func change_buying_description():
	var num = (shop_pos.x+shop_pos.y*3)
	var costs = cost_dict[num]
	var desc = store_desc[num]
	var resources = ["Wood", "Stone", "Diamond"]
	var node = get_node("BuyingMenu/Description")
	node.get_node("ActualDescription").set_text(desc)
	
	# reduce opacity for all other items
	for i in range(buttons.size()):
		get_node("BuyingMenu").get_node(buttons[i]).set_opacity(0.4)
	get_node("BuyingMenu").get_node(buttons[num]).set_opacity(1.0)
	
	# set text to correct number; if zero, remove text and texture altogether
	for i in range(3):
		if(costs[i] <= 0):
			node.get_node(str(resources[i], "Text")).hide()
			node.get_node(str(resources[i], "Texture")).hide()
		else:
			node.get_node(str(resources[i], "Text")).set_text(str(costs[i]))
			node.get_node(str(resources[i], "Text")).show()
			node.get_node(str(resources[i], "Texture")).show()

func handle_split_screen(width, side):
	split_screen_side = side
	
	# initialize cursor and rest of the shop
	var viewport_size = get_viewport().get_rect().size
	self.set_comp_scale(1024, viewport_size.x, viewport_size.y)
	move_selection(Vector2(0,0))
	
	# actually display buying menu
	# get_node("BuyingMenu").set_pos(Vector2(width*0.5*side,0))
	get_node("BuyingMenu").show()

func get_costs():
	return cost_dict[(shop_pos.x+shop_pos.y*3)]

func get_item():
	return shop_pos.x+shop_pos.y*3

func move_selection(vec):
	var temp_pos = Vector2(clamp(shop_pos.x+vec.x, 0, 2), clamp(shop_pos.y+vec.y, 0, 2))
	if(temp_pos.x+temp_pos.y*3 >= cost_dict.size()):
		return
	shop_pos.x = temp_pos.x
	shop_pos.y = temp_pos.y
	get_node("BuyingMenu/SelectionCursor").set_pos(Vector2(shop_pos.x*shop_jumps_x, shop_pos.y*shop_jumps_y) + shop_anchor)
	change_buying_description()

func display_warning_signs(center, variance, rect_size, zoom):
	var get_monsters = get_tree().get_nodes_in_group("Monsters")
	for monster in get_monsters:
		if(monster.warning_sign == null):
			continue
		var side = -1
		# x: left to right || y: top to bottom
		var bounds_x = [center.x-variance.x, center.x+variance.x-86]
		var bounds_y = [center.y-variance.y, center.y+variance.y]
		var within_y_bounds = (monster.get_pos().y > bounds_y[0] && monster.get_pos().y < bounds_y[1])
		if(within_y_bounds):
			if(monster.get_pos().x < bounds_x[0]):
				side = 0
			elif(monster.get_pos().x > bounds_x[1]):
				side = 1
		
		if(side == -1):
			monster.warning_sign.hide()
		else:
			monster.warning_sign.show()
			if(side == 1):
				monster.warning_sign.set_flip_h(true)
			monster.warning_sign.set_pos( Vector2(side*(rect_size.x-86), (monster.get_pos().y-bounds_y[0])/(2*variance.y) * rect_size.y) ) #

func display_message(msg):
	toggle_message(1)
	get_node("MessageText").set_bbcode(msg)

func toggle_message(n):
	if(n==0):
		get_node("MessageText").hide()
		get_node("MessageSprite").hide()
	elif(n==1):
		get_node("MessageText").set_opacity(1.0)
		get_node("MessageSprite").set_opacity(1.0)
		get_node("MessageText").show()
		get_node("MessageSprite").show()
	elif(n == 2 && get_node("MessageText").is_visible()):
		get_node("MessageText").set_opacity(get_node("MessageText").get_opacity()-0.005)
		get_node("MessageSprite").set_opacity(get_node("MessageSprite").get_opacity()-0.005)
		if(get_node("MessageText").get_opacity() <= 0):
			toggle_message(0)

func set_comp_scale(old_x, new_x, new_y):
	var res = new_x/old_x*0.672678
	
	get_node("Resources").set_scale(Vector2(res,res))
	get_node("Resources").set_pos(Vector2(new_x*0.5,0))
	
	self.set_size(Vector2(new_x, new_y))
	
	get_node("MessageText").set_anchor_and_margin(MARGIN_LEFT, Control.ANCHOR_RATIO, 0.3)
	get_node("MessageText").set_anchor_and_margin(MARGIN_RIGHT, Control.ANCHOR_RATIO, 0.7)
	
	get_node("MessageText").set_anchor_and_margin(MARGIN_TOP, Control.ANCHOR_RATIO, 0.14)
	get_node("MessageText").set_anchor_and_margin(MARGIN_BOTTOM, Control.ANCHOR_RATIO, 0.35)
	
	var message_sprite = get_node("MessageSprite")
	
	message_sprite.set_anchor_and_margin(MARGIN_LEFT, Control.ANCHOR_RATIO, 0.29)
	message_sprite.set_anchor_and_margin(MARGIN_RIGHT, Control.ANCHOR_RATIO, 0.71)
	message_sprite.set_anchor_and_margin(MARGIN_TOP, Control.ANCHOR_RATIO, 0.13)
	message_sprite.set_anchor_and_margin(MARGIN_BOTTOM, Control.ANCHOR_RATIO, 0.35)
	
	get_node("Player1Health").set_scale(Vector2(res,res))
	
	if(GLOBAL.multiplayer):
		get_node("Player2Health").set_scale(Vector2(res,res))
		get_node("Player2Health").set_pos(Vector2(new_x,0))
	
	
	var buying_menu = get_node("BuyingMenu")
	buying_menu.set_size(Vector2(new_x*0.5, new_y))
	buying_menu.set_pos(Vector2(split_screen_side*new_x*0.5, 0))
	buying_menu.get_node("Description").set_pos(Vector2(14, new_y-112))
	buying_menu.get_node("Description").set_size(Vector2(new_x*0.5-32, 100))
	
	shop_anchor = Vector2(14, 0.167 * new_y)
	shop_jumps_x = (new_x*0.5)/3
	shop_jumps_y = (new_y-res*151-134)/3
	var find_scale = min(shop_jumps_x, shop_jumps_y)
	buying_menu.get_node("SelectionCursor").set_size(Vector2(find_scale, find_scale))
	
	for i in range(buttons.size()):
		buying_menu.get_node(buttons[i]).set_pos(shop_anchor + Vector2(i%3*shop_jumps_x, floor(i/3)*shop_jumps_y))
		buying_menu.get_node(buttons[i]).set_size(Vector2(find_scale, find_scale))
	
