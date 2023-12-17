# OLD LEVEL CREATION ALGORITHM

for i in range(lev_height):
	for j in range(lev_width):
	if(i == 0):
		lev[i][j] = -1
	else:
		if(i == 1):
			lev[i][j] = round(randf()*3.99-0.49)
		else:
			if(lev[i][j] == -5):
				lev[i][j] = 0
				continue
			
			# if there's three "empty" spaces below us, we place grass
			if(lev[i-1][j] != -1 && lev[i-2][j] >= 0 && (i < 3 || lev[i-3][j] >= 0)):
				# always at least two next to each other
				if(j > 1 && lev[i][j-1] <= 0 && lev[i][j-2] >= 0):
					lev[i][j] = -1
				
				# always at least three next to each other
				if(j > 2 && lev[i][j-1] <= 0 && lev[i][j-2] <= 0 && lev[i][j-3] >= 0):
					lev[i][j] = -1
				
				# don't always start a new row, and don't start when there's trouble ahead (underneath us)
				if((j < (lev_width-2) && lev[i-1][j+1] >= 0 && lev[i-1][j+2] >= 0 && lev[i-2][j+1] >= 0 && lev[i-2][j+2] >= 0)):
					if(randf() > 0.1):
						lev[i][j] = -1
				else:
					lev[i][j] = 0
				
			# place the correct side tile (left)
			if(j > 1 && lev[i][j-2] >= 0 && lev[i][j-1] == -1 && lev[i][j] == -1):
				lev[i][j-1] = -2
			
			# place the correct side tile (right)
			if(j > 2 && lev[i][j-1] >= 0 && lev[i][j-2] == -1 && lev[i][j-3] <= 0):
				lev[i][j-2] = -3
			
			# if there's ground beneath us, place something (with high probability)
			if(lev[i-1][j] < 0):
				lev[i][j] = round(randf()*3.99-0.49)
				
		# if we've placed a tree, disallow any grass over it
		if(lev[i][j] == 3):
			lev[i][j] += round(randf()*10)
			
			for a in range(1, lev[i][j]):
				print(i+a)
				if((i+a) < (lev_height-1)):
					lev[(i+a)][j] = -5
		
		# don't place anything over the tower
		if(j == round(lev_width*0.5)-1 || j == round(lev_width*0.5)):
			lev[i][j] = 0













#### OLD PROJECTILE CHECKING FUNCTION - will be done with individual scripts and Godot's physics system, 
#### because it can't be done (easily) this way
func check_projectiles():
	var vec
	var count_nulls = 0
	for i in range(projectiles.size()):
		var cur_proj = projectiles[i]
		if(cur_proj == null):
			count_nulls += 1
			continue
		
		# destroy projectile if below level surface
		if(cur_proj.get_pos().y > level_size.y):
			cur_proj.queue_free()
			projectiles[i] = null
			continue
		
		# keep arrows from rotating indefinitely (pointy thing downwards)
		if(cur_proj.get_angular_velocity() != 0):
			if(abs(abs(cur_proj.get_rot()) - 0.5*PI) < 0.15):
				cur_proj.set_angular_velocity(0)
		
		# check projectile against all monsters
		# TO DO: hurt monster, explode bomb
		for j in range(monsters.size()):
			vec = cur_proj.get_pos() - monsters[j].get_pos()
			if(vec.length() < 150):
				cur_proj.queue_free()
				projectiles[i] = null
				break

	if(projectiles.size() == count_nulls):
		projectiles.clear()


###### OLD TOWER PULLING DOWN FUNCTION ####
func pull_down_tower():
	print(str(flip, " || ", num, " || ", tower_info))
	# tower_info[flip][num] = 0
	if(num == (tower_info[flip].size()-1)):
		var removals = 1
		tower_info[flip].pop_back()
		# also remove all empty spaces underneath us
		while(tower_info[flip][tower_info[flip].size()-1] == 0):
			removals += 1
			tower_info[flip].pop_back()
		tower_top_blocks[flip].set_pos(Vector2(tower_top_blocks[flip].get_pos().x, pos.y + removals*tower_block_height))
	else:
		var other_side = (flip+1)%2
		var get_towers = get_tree().get_nodes_in_group("TowerBlocks")
		if(num >= tower_info[other_side].size() || tower_info[other_side][num] == 0):
			tower_info[flip].remove(num)
			tower_top_blocks[flip].set_pos(Vector2(tower_top_blocks[flip].get_pos().x, tower_pos[flip].y - tower_block_height*(tower_info[flip].size()-1)))
			# move everything down in this column
			for tower in get_towers:
				var temp_pos = tower.get_pos()
				if((tower.is_flipped == flip) && temp_pos.y < pos.y):
					tower.set_pos(temp_pos+Vector2(0,tower_block_height))
			if(num < tower_info[other_side].size() && tower_info[other_side][num] == 0):
				tower_info[other_side].remove(num)
				tower_top_blocks[other_side].set_pos(Vector2(tower_top_blocks[other_side].get_pos().x, tower_pos[other_side].y - tower_block_height*(tower_info[other_side].size()-1)))
				# move everything down in other column
				for tower in get_towers:
					var temp_pos = tower.get_pos()
					if((tower.is_flipped != flip) && temp_pos.y < pos.y):
						tower.set_pos(temp_pos+Vector2(0,tower_block_height))