
extends Particles2D

var timer = 1
var should_time = false

func _process(delta):
	if(should_time):
		timer -= delta
		if(timer <= 0):
			queue_free()


