--[[
Doom 2D Enemies: Lost Soul
Script by Lekken
--]]

--------------------------------------------------------------------------------
-- Object: Lost Soul
--------------------------------------------------------------------------------

-----------------------
-- Initialization
-----------------------
assert(d2d ~= nil, "Error: Initialization table (d2d) wasn't create!")

if d2d.mob == nil then d2d.mob = {} end
d2d.mob.lostsoul = {}

-- GENERAL
local damage = 15
--
local distance_view = 700
local min_speed_coef = 0.5
local max_speed_coef = 2

-- This constant for checking collisions accuracy (see colNxN in function d2d.mob.*.can_see)
local size_of_collisions_matrix_rectangle = 20

-- Timers constants
local min_waiting = d2d.default_fps * 1
local max_waiting = d2d.default_fps * 3
local max_reverse_speed_timer = d2d.default_fps
local max_delay_between_attacks = d2d.default_fps
local max_delay_between_damage = d2d.default_fps / 4

-- ANIMATION
local animations = {}
-- Move
animations.move = {}
animations.move.frames = 2
animations.move.duration = d2d.default_fps / 3
-- Attack
animations.attack = {}
animations.attack.frames = 2
animations.attack.duration = d2d.default_fps / 4
-- Death
animations.death = {}
animations.death.frames = 7
animations.death.duration = d2d.default_fps / 2

-- GFX
local sprites = {}
-- Sprite size (average)
sprites.width = 16
sprites.height = 26
-- Move
sprites.move = {}
for i = 1, animations.move.frames do
	sprites.move[i] = loadgfx("Doom2D/mobs/LostSoul/SOUL_GO_"..i..".png")
	setmidhandle(sprites.move[i])
end
-- Attack
sprites.attack = {}
for i = 1, animations.attack.frames do
	sprites.attack[i] = loadgfx("Doom2D/mobs/LostSoul/SOUL_ATTACK_"..i..".png")
	setmidhandle(sprites.attack[i])
end
-- Death
sprites.death = {}
for i = 1, animations.death.frames do
	sprites.death[i] = loadgfx("Doom2D/mobs/LostSoul/SOUL_DIE_"..i..".png")
	setmidhandle(sprites.death[i])
end

-- SFX
local sounds = {}
sounds.sight = loadsfx("Doom2D/mobs/LostSoul/SOUL_ATTACK.ogg")
sounds.death = loadsfx("Doom2D/mobs/LostSoul/SOUL_DIE.ogg")

-----------------------
-- Main
-----------------------

-- Creating
d2d.mob.lostsoul.id = addobject("d2d.mob.lostsoul", sprites.move[1])

function d2d.mob.lostsoul.setup(id, direction_arg)
	if objects == nil then objects = {} end
	objects[id] = {}
	
	-- General
	objects[id].id = id
	objects[id].state = d2d.mob_states.SLEEP
	objects[id].prev_state = objects[id].state
	--
	objects[id].health = 50
	--
	objects[id].view_matrix_of_collisions = { {} }	-- see function d2d.mob.*.can_see
	
	-- Stationing
	objects[id].horizon = getobjecty(id)				-- Initial position on the y-axis
	objects[id].direction = (direction_arg == 1 or direction_arg == -1) and direction_arg or 1	-- 1 = right, -1 = left
	objects[id].vdirection = 0							-- 1 = up, -1 = down, 0 = none
	objects[id].elevation_relative_to_horizon = 1		-- 1 = above, -1 = below (see function d2d.mob.*.calculate_elevation)
	objects[id].elevation_relative_to_player = nil		-- see function d2d.mob.*.calculate_elevation
	objects[id].speed_coef = min_speed_coef
	
	-- Timers
	objects[id].timers = {}
	objects[id].timers.delay_between_attacks = max_delay_between_attacks
	objects[id].timers.delay_between_damage = 0	-- This timer is needed because the collision with the player lasts longer than one frame
	objects[id].timers.reverse	= max_reverse_speed_timer
	objects[id].timers.wait = 0
	objects[id].timers.firedamage_tick = d2d.fire.max_timer
	objects[id].timers.disappear_after_death = d2d.default_fps / 10
	
	-- Flags
	objects[id].is_seeing = false
	objects[id].pause_moving = true
	objects[id].reverse = false
	objects[id].delay_between_damage = false
	--
	objects[id].oneshot_playsound_sigh = false
	objects[id].oneshot_playsound_death = false

	-- Graphics
	objects[id].current_gfx = sprites.move[1]
	d2d.mob.lostsoul.reset_animation(id)
end

function d2d.mob.lostsoul.update(id, x, y)
	-- Processing
	objects[id].x = x
	objects[id].y = y
	objects[id].elevation_relative_to_horizon = d2d.mob.lostsoul.calculate_elevation_horizon(id)
	objects[id].elevation_relative_to_player = d2d.mob.lostsoul.calculate_elevation_player(id)
	--
	objects[id].dx = getplayerx(playercurrent()) - x
	objects[id].dy = getplayery(playercurrent()) - y
	objects[id].distance = math.sqrt((objects[id].dx)^2 + (objects[id].dy)^2)
	--
	objects[id].relative_angle_to_player = math.atan2(-objects[id].dx, objects[id].dy) / math.pi * 180

	d2d.mob.lostsoul.fire_damage(id)
	d2d.mob.lostsoul.animation(id)
	d2d.mob.lostsoul.actions(id)
	
	-- Debug
	if d2d.debug ~= nil and d2d.debug.DEBUG_LOG then
		d2d.debug.log("Lost Soul", objects[id])
	end
end

function d2d.mob.lostsoul.draw(id, x, y)
	setblend(blend_alpha)
	setalpha(1)
	setcolor(255, 255, 255)
	setscale(objects[id].direction, 1)
	
	if objects[id].state == d2d.mob_states.ATTACK and not objects[id].reverse then
		setrotation(objects[id].relative_angle_to_player)
	else
		setrotation(objects[id].direction)
	end
	
	drawimage(objects[id].current_gfx, x, y)
	
	-- Debug
	if d2d.debug ~= nil and d2d.debug.DEBUGGING_COLLISIONS_MATRIX then
		d2d.debug.draw_view_collisions_matrix(objects[id], size_of_collisions_matrix_rectangle)
	end
end

function d2d.mob.lostsoul.damage(id, damage)
	objects[id].is_seeing = true
	
	objects[id].health = objects[id].health - damage
	blood(objects[id].x, objects[id].y)
		
	if objects[id].health <= 0 then
		d2d.mob.lostsoul.change_state_to(id, d2d.mob_states.DEAD)
		if not objects[id].oneshot_playsound_death then
			playsound(sounds.death)
			objects[id].oneshot_playsound_death = true
		end
	end
end

function d2d.mob.lostsoul.fire_damage(id)	
	if firecollision(objects[id].current_gfx, objects[id].x, objects[id].y) > 0 then
		objects[id].timers.firedamage_tick = objects[id].timers.firedamage_tick - 1
		if objects[id].timers.firedamage_tick <= 0 then
			objectdamage(id, math.random(d2d.fire.min_damage, d2d.fire.max_damage))
			objects[id].timers.firedamage_tick = d2d.fire.max_timer
		end
	end
end

-----------------------
-- Animations
-----------------------

function d2d.mob.lostsoul.animation(id)
	if  objects[id].state ~= objects[id].prev_state then
		d2d.mob.lostsoul.reset_animation(id)
		objects[id].prev_state = objects[id].state
	end

	-- Death
	if objects[id].state == d2d.mob_states.DEAD then
		d2d.mob.lostsoul.animation_death(id)
		return
	end
	-- Attack
	if objects[id].state == d2d.mob_states.ATTACK and not objects[id].reverse then
		d2d.mob.lostsoul.animation_attack(id)
	-- Move
	else
		d2d.mob.lostsoul.animation_move(id)
	end
end

function d2d.mob.lostsoul.animation_move(id)
	d2d.mob.lostsoul.play_animation(id, animations.move)
	objects[id].current_gfx = sprites.move[objects[id].current_animation_frame]
end

function d2d.mob.lostsoul.animation_attack(id)
	d2d.mob.lostsoul.play_animation(id, animations.attack)
	objects[id].current_gfx = sprites.attack[objects[id].current_animation_frame]
end

function d2d.mob.lostsoul.animation_death(id)
	d2d.mob.lostsoul.play_animation(id, animations.death, true)
	objects[id].current_gfx = sprites.death[objects[id].current_animation_frame]
end

function d2d.mob.lostsoul.play_animation(id, animation, once)
	if (objects[id].timers.animation % math.ceil(animation.duration / animation.frames)) == 0
	then
		if once and objects[id].current_animation_frame >= animation.frames then
			objects[id].current_animation_frame = animation.frames
		else
			objects[id].current_animation_frame = objects[id].current_animation_frame + 1
			if objects[id].current_animation_frame > animation.frames then
				d2d.mob.lostsoul.reset_animation(id)
			end
		end
	end
	objects[id].timers.animation = objects[id].timers.animation + 1
end

function d2d.mob.lostsoul.reset_animation(id)
	objects[id].current_animation_frame = 1
	objects[id].timers.animation = 1
end

-----------------------
-- Mechanics
-----------------------

function d2d.mob.lostsoul.calculate_direction(id)
	if getplayerx(playercurrent()) < objects[id].x then
		return -1	-- left
	else
		return 1	-- right
	end
end

function d2d.mob.lostsoul.calculate_elevation_player(id)
	if objects[id].y <= getplayery(playercurrent()) then
		return 1		-- The object is above the player  
	else
		return -1		-- The object is below the player 
	end
end

function d2d.mob.lostsoul.calculate_elevation_horizon(id)
	if objects[id].y <= objects[id].horizon then
		return 1		-- The object is above the horizon
	else
		return -1		-- The object is below the horizon
	end
end

function d2d.mob.lostsoul.change_state_to(id, state)
	objects[id].prev_state = objects[id].state
	objects[id].state = state
end

-----------------------

function d2d.mob.lostsoul.actions(id)	
	if objects[id].state == d2d.mob_states.DEAD then
		d2d.mob.lostsoul.death(id)
		return
	end
	
	d2d.mob.lostsoul.move(id)
	d2d.mob.lostsoul.look_for(id)
	
	if objects[id].state == d2d.mob_states.ATTACK then
		d2d.mob.lostsoul.attack(id)
	end
end

function d2d.mob.lostsoul.process_collisions(id)
	if collision(col5x5, objects[id].x, objects[id].y - objects[id].elevation_relative_to_horizon * sprites.height / 2, 1, 0, 1, 0, id) == 1 then
		objects[id].y = objects[id].y + objects[id].elevation_relative_to_horizon * objects[id].speed_coef
	end
	
	if collision(col5x5, objects[id].x, objects[id].y + objects[id].elevation_relative_to_horizon * sprites.height / 2, 1, 0, 1, 0, id) == 1 then
		objects[id].y = objects[id].y - objects[id].elevation_relative_to_horizon * objects[id].speed_coef
		objects[id].reverse = false
	end
	
	if collision(col5x5, objects[id].x + objects[id].direction * sprites.width / 2, objects[id].y, 1, 0, 1, 0, id) == 1 then
		if terraincollision() == 1 then
			objects[id].x = objects[id].x - objects[id].direction * objects[id].speed_coef
			objects[id].timers.wait = min_waiting
			objects[id].pause_moving = true
		end
		
		if objectcollision() ~= 0 then 
			objects[id].x = objects[id].x - objects[id].direction * objects[id].speed_coef
		end
	end
	
	if collision(col5x5, objects[id].x - objects[id].direction * sprites.width / 2, objects[id].y, 1, 0, 1, 0, id) == 1 then
		if terraincollision() == 1 then
			objects[id].x = objects[id].x + objects[id].direction * objects[id].speed_coef
			objects[id].timers.wait = min_waiting
			objects[id].pause_moving = true
			objects[id].reverse = false
		end
		
		if objectcollision() ~= 0 then 
			objects[id].x = objects[id].x + objects[id].direction * objects[id].speed_coef
			objects[id].reverse = false
		end
	end
end

function d2d.mob.lostsoul.move(id)
	if objects[id].is_seeing then
		objects[id].direction = d2d.mob.lostsoul.calculate_direction(id)
		d2d.mob.lostsoul.chase(id)
	else
		d2d.mob.lostsoul.waiting(id)
	end
	d2d.mob.lostsoul.process_collisions(id)

	objectposition(id, objects[id].x, objects[id].y)
end

function d2d.mob.lostsoul.chase(id)
	objects[id].speed_coef = (objects[id].state == d2d.mob_states.ATTACK) and max_speed_coef or min_speed_coef
	
	if not objects[id].reverse then
		objects[id].x = objects[id].x + objects[id].direction * objects[id].speed_coef
		objects[id].y = objects[id].y + objects[id].elevation_relative_to_player * objects[id].speed_coef
	else
		objects[id].timers.reverse = objects[id].timers.reverse - 1
		objects[id].x = objects[id].x - objects[id].direction * objects[id].speed_coef
		--objects[id].y = y - objects[id].elevation_relative_to_player * objects[id].speed_coef
		
		if objects[id].timers.reverse <= 0 then
			objects[id].reverse = false
			objects[id].timers.reverse = max_reverse_speed_timer
		end
	end
end


-- For function d2d.mob.lostsoul.waiting(id)
local count_of_choosed_direction = 0
local count_of_choosed_vdirection = 0
-- Minimum and maximum distance of movement by coordinate 
local dist_x_min = 50
local dist_x_max = 150
local dist_y_min = 10
local dist_y_max = 50
--  Selected the movement end point
local endpoint_x = 0
local endpoint_y = 0

function d2d.mob.lostsoul.waiting(id)
	objects[id].speed_coef = min_speed_coef
	
	objects[id].timers.wait = objects[id].timers.wait - 1
	if objects[id].timers.wait <= 0 then
		-- Restrictions on the choice of direction of movement 
		if objects[id].pause_moving then
			local last_vdirection = objects[id].vdirection
			objects[id].vdirection = math.random(-1, 1)
			
			if objects[id].vdirection == last_vdirection then
				count_of_choosed_vdirection = count_of_choosed_vdirection + 1
			else
				count_of_choosed_vdirection = 0
			end
			
			if count_of_choosed_vdirection >= 1 then
				objects[id].vdirection = -objects[id].vdirection
				count_of_choosed_vdirection = 0
			end
			
			local last_direction = objects[id].direction
			objects[id].direction = math.random(-1, 1)
			
			if (objects[id].direction == 0) then
				objects[id].direction = -last_direction
			end
			
			if (objects[id].direction == last_direction) then
				count_of_choosed_direction = count_of_choosed_direction + 1
			end
			
			if (count_of_choosed_direction >= 2) then
				objects[id].direction = -objects[id].direction
				count_of_choosed_direction = 0
			end

			endpoint_x = objects[id].x + objects[id].direction * math.random(dist_x_min, dist_x_max)
			endpoint_y = objects[id].y - objects[id].vdirection * math.random(dist_y_min, dist_y_max)
			
			objects[id].pause_moving = false
		end
		
		local dist_x = endpoint_x - objects[id].x
		local dist_y = endpoint_y - objects[id].y
		if (dist_x > 0 and objects[id].direction == 1) or (dist_x <= 0 and objects[id].direction == -1)
		then
			objects[id].x = objects[id].x + objects[id].direction * objects[id].speed_coef
			
			if ((dist_y < 0 and objects[id].vdirection == 1) or (dist_y > 0 and objects[id].vdirection == -1)) then
				objects[id].y = objects[id].y - objects[id].vdirection * objects[id].speed_coef
			end
		else
			objects[id].timers.wait = math.random(min_waiting, max_waiting)
			objects[id].pause_moving = true
		end
	end
end

function d2d.mob.lostsoul.look_for(id)
	-- Can see the player?	
	if d2d.mob.lostsoul.can_see(id) then
		objects[id].is_seeing = true
		d2d.mob.lostsoul.change_state_to(id, d2d.mob_states.ATTACK)
		if not objects[id].oneshot_playsound_sigh then
			playsound(sounds.sight)
			objects[id].oneshot_playsound_sigh = true
		end
	else
		objects[id].is_seeing = false
		d2d.mob.lostsoul.change_state_to(id, d2d.mob_states.MOVE)
		objects[id].oneshot_playsound_sigh = false
	end
end

function d2d.mob.lostsoul.can_see(id)
	objects[id].view_matrix_of_collisions = {{}}

	if ((getplayerx(playercurrent()) < objects[id].x and objects[id].direction == -1) or
		(getplayerx(playercurrent()) > objects[id].x and objects[id].direction == 1))
		and objects[id].distance < distance_view
	then
		local cols = math.ceil(math.abs(objects[id].dx / size_of_collisions_matrix_rectangle))
		local rows = math.ceil(math.abs(objects[id].dy / size_of_collisions_matrix_rectangle))

		for row = 1, rows do
			objects[id].view_matrix_of_collisions[row] = {}
			for col = 1, cols do
				objects[id].view_matrix_of_collisions[row][col] = 
					collision(col20x20, 
								objects[id].x + objects[id].direction * (col * size_of_collisions_matrix_rectangle),
								objects[id].y + objects[id].elevation_relative_to_player * (row - 1) * size_of_collisions_matrix_rectangle,
								1, 0, 0)
					-- end collision()
				-- end view_matrix_of_collisions[][]
			end
		end
	else
		return false
	end
	
	return true
end

function d2d.mob.lostsoul.attack(id)
	-- Delay before the next attack (so that the mob does not attack continuously) 
	objects[id].timers.delay_between_damage = objects[id].timers.delay_between_damage - 1
	
	if objects[id].timers.delay_between_damage <= 0 then
		objects[id].delay_between_damage = false
	end
	
	if collision(colplayer, objects[id].x + objects[id].direction * sprites.width / 2, objects[id].y) == 1 or
		collision(colplayer, objects[id].x, objects[id].y + objects[id].elevation_relative_to_player * sprites.height / 2) == 1
	then
		if playercollision() == playercurrent() then
			if not objects[id].reverse and not objects[id].delay_between_damage	then
				playerdamage(playercollision(), damage)
				objects[id].delay_between_damage = true
				objects[id].timers.delay_between_damage = max_delay_between_damage
			end
			objects[id].reverse = true
		end
	end
end

function d2d.mob.lostsoul.death(id)
	if objects[id].current_animation_frame == animations.death.frames then
		objects[id].timers.disappear_after_death = objects[id].timers.disappear_after_death - 1
		if objects[id].timers.disappear_after_death <= 0 then
			removeobject(id)
		end
	end
end