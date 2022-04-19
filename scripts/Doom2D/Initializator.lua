--[[
Doom 2D: Initializator
Script by Lekken

This file was created for initialization global variables, states and functions in other scripts.
--]]

if d2d == nil then d2d = {} end

-- General
d2d.default_fps = 50

-- Liquids
d2d.liquids = {}
d2d.liquids.player_push_speed_x = 0
d2d.liquids.player_push_speed_y = -2
--
d2d.magma = {}
d2d.magma.damage = 5
d2d.magma.timer_damage_tick = {0}
d2d.magma.max_timer_damage_tick = d2d.default_fps / 2

-- Mobs
d2d.mob_states = {
					DEAD = 1, 
					SLEEP = 2, 
					MOVE = 3, 
					ATTACK = 4
				}

-- Effects and projectiles
d2d.max_projectile_lifetime = d2d.default_fps * 10

-- Fire damage constants for common cases
d2d.fire = {}
d2d.fire.min_damage = 4
d2d.fire.max_damage = 8
d2d.fire.max_timer = d2d.default_fps / 2


-- TEST
function d2d.mediaplayer(sound)
	return function(once)
		if once then
			playsound(sfx)
			once = false
		else
			playsound(sfx)
		end
	end
end