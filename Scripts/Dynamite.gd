
extends RigidBody2D

var timer = 0

func panda_died():
	self.queue_free()

func explode():
	var bodies = get_node("BlastRadius").get_overlapping_bodies()
	get_node("SamplePlayer2D").play("Explosion")

	for i in range(bodies.size()):
		if(bodies[i].is_in_group("Bombs") || bodies[i].is_in_group("TowerTopBlocks") || (bodies[i].is_in_group("Indestructibles") && bodies[i].is_in_group("GrassBlocks"))):
			continue
		elif(bodies[i].is_in_group("Players")):
			bodies[i].change_health(-randf()*150)
		elif(bodies[i].is_in_group("Monsters")):
			bodies[i].change_health(-3)
		elif(bodies[i].is_in_group("TowerBlocks")):
			bodies[i].change_health(-1-randf()*2)
		elif(bodies[i].is_in_group("Trees") || bodies[i].is_in_group("Stones")):
			bodies[i].queue_free()
		else:
			bodies[i].queue_free()
	
	get_node("DustParticles").set_emitting(true)
	get_node("FireParticles").set_emitting(true)
	set_fixed_process(true)

func _fixed_process(delta):
	timer -= delta
	if(timer < 0):
		get_node("FireParticles").set_emitting(false)
		if(timer <= -1):
			set_fixed_process(false)
			self.queue_free()


