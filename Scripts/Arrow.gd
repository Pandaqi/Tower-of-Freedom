
extends RigidBody2D

var level_bottom
var MY_STRENGTH = 1

func _ready():
	set_fixed_process(true)
	if(!GLOBAL.night_mode):
		get_node("Torch").queue_free()

func _fixed_process(delta):
	if(get_pos().y > level_bottom):
		set_fixed_process(false)
		self.queue_free()
	
	if(get_angular_velocity() != 0):
		if(abs(abs(get_rot()) - 0.5*PI) < 0.15):
			set_angular_velocity(0)
