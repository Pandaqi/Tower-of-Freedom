
extends RigidBody2D

var timer = 5
var last_check = false
var MY_STRENGTH = 1

func _ready():
	set_fixed_process(true)

func _fixed_process(delta):
	timer -= delta
	if(timer <= 0 && timer >= -1):
		# EXPLODE!
		var bodies = get_node("BlastRadius").get_overlapping_bodies()
		get_node("SamplePlayer2D").play("Explosion")

		for i in range(bodies.size()):
			if(bodies[i].is_in_group("Bombs") || bodies[i].is_in_group("TowerTopBlocks") || (bodies[i].is_in_group("Indestructibles") && bodies[i].is_in_group("GrassBlocks"))):
				continue
			elif(bodies[i].is_in_group("Players")):
				bodies[i].change_health(-randf()*100*MY_STRENGTH-50)
			elif(bodies[i].is_in_group("Monsters")):
				bodies[i].change_health(-3*MY_STRENGTH)
			elif(bodies[i].is_in_group("TowerBlocks")):
				bodies[i].change_health(-1*MY_STRENGTH)
			elif(bodies[i].is_in_group("Trees") || bodies[i].is_in_group("Stones")):
				bodies[i].queue_free()
			else:
				bodies[i].queue_free()
		
		get_node("DustParticles").set_emitting(true)
		get_node("FireParticles").set_emitting(true)
		timer = -1
	elif(timer < -1):
		get_node("FireParticles").set_emitting(false)
		if(timer <= -2):
			set_fixed_process(false)
			self.queue_free()


