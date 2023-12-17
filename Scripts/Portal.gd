
extends Sprite

var thunders = ["PortalThunderBack1", "PortalThunderBack2", "PortalThunder1", "PortalThunder2"]
var active_thunder = null
var direction = 0

func _ready():
	if(!GLOBAL.night_mode):
		get_node("Light2D").queue_free()

func animate_portal():
	if(direction == -1):
		active_thunder += 0.035
		set_rot(get_rot()+0.035*PI)
		if(active_thunder >= 2):
			direction = 0
			set_rot(0)
			active_thunder = null
		return
	
	# no active thunder, initiate!
	if(active_thunder == null):
		if(randf() > 0.95):
			direction = -1
			active_thunder = 0
			return
		else:
			active_thunder = get_node(thunders[round(randf()*(thunders.size()-1))])
	
	if(direction == 0):
		active_thunder.set_opacity(active_thunder.get_opacity()+0.22)
	else:
		active_thunder.set_opacity(active_thunder.get_opacity()-0.03)
	
	if(active_thunder.get_opacity() >= 1):
		direction = 1
	elif(active_thunder.get_opacity() <= 0):
		direction = 0
		active_thunder = null


