
extends Node

var tutorial = [
["The purpose of the game is to build a tower, in order to reach the portal before you die!", 1],
["First, try moving around with the [color=#FFAAAA]ARROW KEYS[/color].", 1],
["Oh no, our player doesn't have a tool at the moment, so he can't do anything! To pick up one of the six tools, walk towards it, and press the [color=#FFAAAA]?[/color] key.", 0],
["To drop the tool (so that your hands are free to fetch another tool), press [color=#FFAAAA]UP+DOWN[/color] simultaneously. Try it now!", 0],
["Now go and fetch the hammer. When you're next to a broken towerpiece, the hammer will build/repair it. When you're next to a gap in the tower, the hammer will construct a new tower piece for you.", 0],
["Try standing in front of the tower, and using the hammer by pressing the [color=#FFAAAA]?[/color] key, until one tower piece is fully repaired", 0],
["Additionally, by pressing [color=#FFAAAA]SHIFT[/color] (while holding the hammer), you can open the shop. You can select what you want, and press [color=#FFAAAA]SHIFT[/color] again to buy it.", 1],
["Constructing new tower pieces costs resources. There's three types: wood, stone, and diamonds. Both wood and stone can be gathered by using the correct tool, whilst diamonds are dropped by enemies.", 1],
["Now get yourself the axe. (Don't forget to throw away the hammer at a strategic location first.)", 0],
["Again, by standing near a tree and holding the [color=#FFAAAA]?[/color] key, you can chop a tree. (Of course, you need to face the tree, and you'll need to keep chopping a few seconds until the tree falls to the ground.)", 0],
["Now get yourself the pickaxe. (Don't forget to throw away your previous tool at a convenient spot.)", 0],
["Again, if you stand near some stone, hold the [color=#FFAAAA]?[/color] key until the stone breaks.", 0],
["If you ever seem to run out of resources, you can go to the store (using the hammer, remember?) and replenish the trees or stones.", 1],
["Of course, the tower isn't so easily built. There are monsters waiting to tear it apart, or even worse, tear you apart! The last three tools are for killing the monsters.", 1],
["Oh no, a Rampaging Rhino is about to enter the world! Quick, get yourself the sword", 0],
["Kill the rhino before it reaches the tower! Again, hold the [color=#FFAAAA]?[/color] key to use the sword, and stand close to the monster. (Beware, though, rhinos are invincible when they stand still.)", 0],
["Well done! Now on to more sophisticated weaponry. Get yourself the bow.", 0],
["To load the bow, hold the [color=#FFAAAA]?[/color] key. To actually shoot it, press [color=#FFAAAA]SHIFT[/color]. Beware, though, as the longer you hold that [color=#FFAAAA]SHIFT[/color] button, the further and faster you will shoot!", 1],
["Oh no, a Pestering Panda is rolling towards the tower! Kill it, kill it with fire! Erm, I mean, arrows.", 0],
["Well done! Now get yourself the bomb.", 0],
["It works the same way as the arrow: press the [color=#FFAAAA]?[/color] key to load, hold and release [color=#FFAAAA]SHIFT[/color] to aim and shoot. Beware, though, that bombs can hurt yourself too, and that they take time to explode. Try it out!", 0],
["If you ever load a bow or a bomb, but decide you don't want to use it, press [color=#FFAAAA]DOWN[/color] to let go.", 1],
["As you will have noticed by now, monsters drop diamonds. You can use them to buy special and very useful stuff from the store.", 1],
["Also, every tower piece automatically has a black ladder you can use to climb up and down the tower.", 1],
["Lastly, to pause the game at any moment, simply press [color=#FFAAAA]ESC[/color]", 1],
["That's all! Start a new game to get to know all the monsters, and build your own tower to greatness.", 0]
]

var regular_messages = [
"You do not have enough resources to build a new tower piece!",
"Oh no, a part of the tower has been destroyed!",
"Bad news: you lost a life!",
"Le Rhino was killed!",
"Praise the lord, that panda is gone!",
"You destroyed that monkey!",
"You're too far away to build something on the tower!",
"You can't build on top of solely wooden tower blocks! Make the foundation stronger, if you want to not die.",
"Five trees were regrown!",
"Five stones have been recreated!",
"Wow, you're much faster now!",
"You gained a life!",
"Voila, a kind ghost to help you with your quest.",
"Your weapons are like SUPER STRONG now.",
"All tower blocks have increased health!",
"Resources will now grow back automatically"
]

var cur_tut_num = -1
var gui_node = null
var main_node = null
var paused = false

func _ready():
	gui_node = get_tree().get_root().get_node("Main/GUI/Control")
	main_node = get_tree().get_root().get_node("Main")
	if(GLOBAL.tutorial_mode):
		send_signal(-1)
	set_process_input(true)

func _input(ev):
	if(ev.is_action_released("ui_accept")):
		if(paused):
			cur_tut_num -= 1;
		
		if(GLOBAL.tutorial_mode):
			if(tutorial[cur_tut_num][1] == 1 || paused):
				send_signal(cur_tut_num)
		elif(!GLOBAL.tutorial_mode):
			gui_node.toggle_message(0)
		
		get_tree().set_pause(false)
		paused = false
	elif(ev.is_action_released("ui_cancel")):
		if(paused):
			get_tree().set_pause(false)
			paused = false
			main_node.end_game("lose")
		else:
			get_tree().set_pause(true)
			paused = true
			gui_node.display_message("[color=#FFAAAA]Game paused![/color] Press [color=#CCCCCC]ENTER[/color] to continue, press [color=#CCCCCC]ESC[/color] to surrender and quit.")
	
	if(ev.is_action_released("ui_zoom_in")):
		main_node.external_change_zoom = max(main_node.external_change_zoom-0.25, 0)
	elif(ev.is_action_released("ui_zoom_out")):
		main_node.external_change_zoom = max(main_node.external_change_zoom+0.25, 0)

func send_signal(num):
	if(GLOBAL.tutorial_mode):
		if(num == cur_tut_num):
			cur_tut_num += 1
			if(tutorial[cur_tut_num][1] == 1):
				gui_node.display_message(str(tutorial[cur_tut_num][0], " [color=#CCCCCC](Press ENTER to continue.)[/color]"))
			else:
				gui_node.display_message(tutorial[cur_tut_num][0])
			
			# a rhino enters!
			if(cur_tut_num == 15):
				main_node.add_monster(0)
			# a panda enters!
			elif(cur_tut_num == 18):
				main_node.add_monster(1)
	else:
		if(num >= 0):
			return
		gui_node.display_message(regular_messages[abs(num)-1])
		gui_node.toggle_message(1)

