--[[
Doom 2D Enemies: Pain Elemental
Script by Lekken
--]]

--------------------------------------------------------------------------------
-- Object: Pain Elemental
--------------------------------------------------------------------------------

-----------------------
-- Initialization
-----------------------
assert(d2d ~= nil, "Error: Initialization table (d2d) wasn't create!")

if d2d.mob == nil then d2d.mob = {} end
d2d.mob.painelemental = {}

-- ANIMATION
local animations = {}
-- Move
animations.move = {}
animations.move.frames = 4
animations.move.duration = d2d.default_fps / 1.2
-- Attack
animations.attack = {}
animations.attack.frames = 4
animations.attack.duration = d2d.default_fps / 3
-- Death
animations.death = {}
animations.death.frames = 7
animations.death.duration = d2d.default_fps / 2

-- GENERAL
local distance_view = 700
local distance_approach = 100
local max_count_of_summons = 10
local speed_coef = 0.6

-- This constant for checking collisions accuracy (see colNxN in function d2d.mob.*.can_see)
local size_of_collisions_matrix_rectangle = 30

-- Timers constants
local min_waiting = d2d.default_fps * 1
local max_waiting = d2d.default_fps * 3
local max_delay_between_summons = animations.attack.duration
local max_delay_between_attacks = (d2d.default_fps * 4) - max_delay_between_summons

-- GFX
local sprites = {}
-- Sprite size (average)
sprites.width = 34
sprites.height = 36
-- Move
sprites.move = {}
for i = 1, animations.move.frames do
	sprites.move[i] = loadgfx("Doom2D/mobs/PainElemental/PAIN_GO_"..i..".png")
	setmidhandle(sprites.move[i])
end
-- Attack
sprites.attack = {}
for i = 1, animations.attack.frames do
	sprites.attack[i] = loadgfx("Doom2D/mobs/PainElemental/PAIN_ATTACK_"..i..".png")
	setmidhandle(sprites.attack[i])
end
-- Death
sprites.death = {}
for i = 1, animations.death.frames do
	sprites.death[i] = loadgfx("Doom2D/mobs/PainElemental/PAIN_DIE_"..i..".png")
	setmidhandle(sprites.death[i])
end

-- SFX
local sounds = {}
sounds.sight = loadsfx("Doom2D/mobs/PainElemental/PAIN_ALERT.ogg")
sounds.death = loadsfx("Doom2D/mobs/PainElemental/PAIN_DIE.ogg")

-----------------------
-- Main
-----------------------

-- Creating
d2d.mob.painelemental.id = addobject("d2d.mob.painelemental", sprites.move[1])

function d2d.mob.painelemental.setup(id, parameter)
	if objects == nil then objects = {} end
	objects[id] = {}
	
	-- General
	objects[id].id = id
	objects[id].state = d2d.mob_states.SLEEP
	objects[id].prev_state = objects[id].state
	--
	objects[id].health = 200
	objects[id].count_of_summons = 0
	--
	objects[id].view_matrix_of_collisions = { {} }	-- see function d2d.mob.painelemental.can_see
	
	-- Stationing
	objects[id].horizon = getobjecty(id)				-- Initial position on the y-axis
	objects[id].direction = 1							-- 1 = right, -1 = left
	objects[id].vdirection = 0							-- 1 = up, -1 = down, 0 = none)
	objects[id].elevation_relative_to_horizon = 1		-- 1 = above, -1 = below (see function d2d.mob.*.calculate_elevation)
	objects[id].elevation_relative_to_player = nil		-- see function d2d.mob.*.calculate_elevation

	-- Timers
	objects[id].timers = {}
	objects[id].timers.delay_between_summons = 0
	objects[id].timers.delay_between_attacks = 0
	objects[id].timers.wait = 0
	objects[id].timers.firedamage_tick = d2d.fire.max_timer
	objects[id].timers.disappear_after_death = d2d.default_fps / 10
	
	-- Flags
	objects[id].is_seeing = false
	objects[id].pause_moving = true
	objects[id].delay_attack = false
	--
	objects[id].oneshot_playsound_sigh = false
	objects[id].oneshot_playsound_death = false
	
	-- Graphics	
	objects[id].current_gfx = sprites.move[1]
	d2d.mob.painelemental.reset_animation(id)
end

function d2d.mob.painelemental.update(id, x, y)
	-- Processing
	objects[id].x = x
	objects[id].y = y
	objects[id].elevation_relative_to_horizon = d2d.mob.painelemental.calculate_elevation_horizon(id)
	objects[id].elevation_relative_to_player = d2d.mob.painelemental.calculate_elevation_player(id)
	--
	objects[id].dx = getplayerx(playercurrent()) - x
	objects[id].dy = getplayery(playercurrent()) - y
	objects[id].distance = math.sqrt((objects[id].dx)^2 + (objects[id].dy)^2)
	
	d2d.mob.painelemental.fire_damage(id)
	d2d.mob.painelemental.animation(id)
	d2d.mob.painelemental.actions(id)
	
	-- Debug
	if d2d.debug ~= nil and d2d.debug.DEBUG_LOG then
		d2d.debug.log("Pain Elemental", objects[id])
	end
end

function d2d.mob.painelemental.draw(id, x, y)
	setblend(blend_alpha)
	setalpha(1)
	setcolor(255, 255, 255)
	setrotation(0)
	setscale(objects[id].direction, 1)
	drawimage(objects[id].current_gfx, x, y)
	
	-- Debug
	if d2d.debug ~= nil and d2d.debug.DEBUGGING_COLLISIONS_MATRIX then
		d2d.debug.draw_view_collisions_matrix(objects[id], size_of_collisions_matrix_rectangle)
	end
end

function d2d.mob.painelemental.damage(id, damage)
	objects[id].is_seeing = true
	
	objects[id].health = objects[id].health - damage
	blood(getobjectx(id), getobjecty(id))
	
	if objects[id].health <= 0 then
		d2d.mob.painelemental.change_state_to(id, d2d.mob_states.DEAD)
		if not objects[id].oneshot_playsound_death then
			playsound(sounds.death)
			objects[id].oneshot_playsound_death = true
		end
	end
end

function d2d.mob.painelemental.fire_damage(id)	
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

function d2d.mob.painelemental.animation(id)
	if  objects[id].state ~= objects[id].prev_state then
		d2d.mob.painelemental.reset_animation(id)
		objects[id].prev_state = objects[id].state
	end
	
	-- Death
	if objects[id].state == d2d.mob_states.DEAD then
		d2d.mob.painelemental.animation_death(id)
		return
	end
	-- Attack
	if objects[id].state == d2d.mob_states.ATTACK then
		d2d.mob.painelemental.animation_attack(id)
	-- Move
	else
		d2d.mob.painelemental.animation_move(id)
	end
end

function d2d.mob.painelemental.animation_move(id)
	d2d.mob.painelemental.play_animation(id, animations.move)
	objects[id].current_gfx = sprites.move[objects[id].current_animation_frame]
end

function d2d.mob.painelemental.animation_attack(id)
	if not objects[id].delay_attack then
		d2d.mob.painelemental.play_animation(id, animations.attack)
	else
		objects[id].current_animation_frame = 1
	end
	objects[id].current_gfx = sprites.attack[objects[id].current_animation_frame]
end

function d2d.mob.painelemental.animation_death(id)
	d2d.mob.painelemental.play_animation(id, animations.death, true)
	objects[id].current_gfx = sprites.death[objects[id].current_animation_frame]
end

function d2d.mob.painelemental.play_animation(id, animation, once)
	if (objects[id].timers.animation % math.ceil(animation.duration / animation.frames)) == 0
	then
		if once and objects[id].current_animation_frame >= animation.frames then
			objects[id].current_animation_frame = animation.frames
		else
			objects[id].current_animation_frame = objects[id].current_animation_frame + 1
			if objects[id].current_animation_frame > animation.frames then
				d2d.mob.painelemental.reset_animation(id)
			end
		end
	end
	objects[id].timers.animation = objects[id].timers.animation + 1
end

function d2d.mob.painelemental.reset_animation(id)
	objects[id].current_animation_frame = 1
	objects[id].timers.animation = 1
end

-----------------------
-- Mechanics
-----------------------

function d2d.mob.painelemental.calculate_direction(id)
	if getplayerx(playercurrent()) < objects[id].x then
		return -1	-- left
	else
		return 1	-- right
	end
end

function d2d.mob.painelemental.calculate_elevation_player(id)
	if objects[id].y <= getplayery(playercurrent()) then
		return 1		-- The object is above the player  
	else
		return -1		-- The object is below the player 
	end
end

function d2d.mob.painelemental.calculate_elevation_horizon(id)
	if objects[id].y <= objects[id].horizon then
		return 1		-- The object is above the horizon
	else
		return -1		-- The object is below the horizon
	end
end

function d2d.mob.painelemental.change_state_to(id, state)
	objects[id].prev_state = objects[id].state
	objects[id].state = state
end

-----------------------

function d2d.mob.painelemental.actions(id)	
	if objects[id].state == d2d.mob_states.DEAD then
		d2d.mob.painelemental.death(id)
		return
	end	
	
	if objects[id].state == d2d.mob_states.ATTACK then
		d2d.mob.painelemental.attack(id)
	else
		d2d.mob.painelemental.move(id)
	end
	
	d2d.mob.painelemental.look_for(id)
end

function d2d.mob.painelemental.process_collisions(id)
	if collision(col5x5, objects[id].x, objects[id].y - objects[id].elevation_relative_to_horizon * sprites.height / 2) == 1 then
		if terraincollision() == 1 then
			objects[id].y = objects[id].y + objects[id].elevation_relative_to_horizon * speed_coef
		end
	end
	
	if collision(col5x5, objects[id].x, objects[id].y + objects[id].elevation_relative_to_horizon * sprites.height / 2) == 1 then
		if terraincollision() == 1 then
			objects[id].y = objects[id].y - objects[id].elevation_relative_to_horizon * speed_coef
		end
	end
	
	if collision(col5x5, objects[id].x + objects[id].direction * sprites.width / 2, objects[id].y) == 1 then
		if terraincollision() == 1 then
			objects[id].x = objects[id].x - objects[id].direction * speed_coef
			objects[id].timers.wait = min_waiting
			objects[id].pause_moving = true
		end
	end
	
	if collision(col5x5, objects[id].x - objects[id].direction * sprites.width / 2, objects[id].y) == 1 then
		if terraincollision() == 1 then
			objects[id].x = objects[id].x + objects[id].direction * speed_coef
			objects[id].timers.wait = min_waiting
			objects[id].pause_moving = true
		end
	end
end

function d2d.mob.painelemental.move(id)
	if objects[id].is_seeing then
		objects[id].direction = d2d.mob.painelemental.calculate_direction(id)
		d2d.mob.painelemental.chase(id)
	else
		d2d.mob.painelemental.waiting(id)
	end
	d2d.mob.painelemental.process_collisions(id)

	objectposition(id, objects[id].x, objects[id].y)
end

function d2d.mob.painelemental.chase(id)
	if math.abs(objects[id].dx) > distance_approach then
		objects[id].x = objects[id].x + objects[id].direction * speed_coef
	end
	
	if math.abs(objects[id].dy) > distance_approach then
		objects[id].y = objects[id].y + objects[id].elevation_relative_to_player * speed_coef
	end
end


-- For function d2d.mob.painelemental.waiting(id)
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

function d2d.mob.painelemental.waiting(id)
	objects[id].timers.wait = objects[id].timers.wait - 1
	if objects[id].timers.wait <= 0 then
	-- Restrictions on the choice of direction of movement
		if objects[id].pause_moving then
			-- vertical
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
			
			-- horizontal
			local last_direction = objects[id].direction
			objects[id].direction = math.random(-1, 1)
			
			if objects[id].direction == 0 then
				objects[id].direction = -last_direction
			end
			
			if objects[id].direction == last_direction then
				count_of_choosed_direction = count_of_choosed_direction + 1
			end
			
			if count_of_choosed_direction >= 2 then
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
			objects[id].x = objects[id].x + objects[id].direction * speed_coef
			
			if (dist_y < 0 and objects[id].vdirection == 1) or (dist_y > 0 and objects[id].vdirection == -1) then
				objects[id].y = objects[id].y - objects[id].vdirection * speed_coef
			end
		else
			objects[id].timers.wait = math.random(min_waiting, max_waiting)
			objects[id].pause_moving = true
		end
	end
end

function d2d.mob.painelemental.look_for(id)
	-- Can see the player?
	if d2d.mob.painelemental.can_see(id) then
		objects[id].is_seeing = true
		d2d.mob.painelemental.change_state_to(id, d2d.mob_states.ATTACK)
		
		if not objects[id].oneshot_playsound_sigh then
			playsound(sounds.sight)
			objects[id].oneshot_playsound_sigh = true
		end
	else
		objects[id].is_seeing = false
		d2d.mob.painelemental.change_state_to(id, d2d.mob_states.MOVE)
	end
end

function d2d.mob.painelemental.can_see(id)
	objects[id].view_matrix_of_collisions = {{}}

	if ((getplayerx(playercurrent()) < objects[id].x and objects[id].direction == -1) or
		(getplayerx(playercurrent()) > objects[id].x and objects[id].direction == 1)) 
		and	objects[id].distance < distance_view
	then
		local cols = math.ceil(math.abs(objects[id].dx / size_of_collisions_matrix_rectangle))
		local rows = math.ceil(math.abs(objects[id].dy / size_of_collisions_matrix_rectangle))

		for row = 1, rows do
			objects[id].view_matrix_of_collisions[row] = {}
			for col = 1, cols do
				objects[id].view_matrix_of_collisions[row][col] = 
					collision(col30x30, 
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

function d2d.mob.painelemental.attack(id)
	if objects[id].count_of_summons < max_count_of_summons then
		-- Delay before the next attack (so that the mob does not attack continuously) 
		objects[id].timers.delay_between_attacks = objects[id].timers.delay_between_attacks - 1
		
		if objects[id].timers.delay_between_attacks <= 0 then
			objects[id].delay_attack = false
		end
		
		if not objects[id].delay_attack then
			objects[id].timers.delay_between_attacks = max_delay_between_attacks
			objects[id].timers.delay_between_summons = objects[id].timers.delay_between_summons - 1
			-- Mob summons Lost Soul only after the completion of the animation 
			if objects[id].timers.delay_between_summons <= 0 and
				objects[id].current_gfx == sprites.attack[animations.attack.frames]
			then
				createobject(d2d.mob.lostsoul.id,
							objects[id].x + objects[id].direction * sprites.width / 2, 
							objects[id].y,
							objects[id].direction
							)
				objects[id].count_of_summons = objects[id].count_of_summons + 1
				objects[id].timers.delay_between_summons = max_delay_between_summons
				objects[id].delay_attack = true
			end
		end
	end
end

function d2d.mob.painelemental.death(id)
	if objects[id].current_animation_frame == animations.death.frames then
		objects[id].timers.disappear_after_death = objects[id].timers.disappear_after_death - 1
		if objects[id].timers.disappear_after_death <= 0 then
			removeobject(id)
			for i = 1, 3, 1 do
				createobject(d2d.mob.lostsoul.id,
					objects[id].x + objects[id].direction * sprites.width / 2, 
					objects[id].y - (i-1) * sprites.width / 2,
					objects[id].direction
				)
			end
		end
	end
end