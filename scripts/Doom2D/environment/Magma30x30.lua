--[[
Doom 2D: Magma
Script by Lekken
--]]

--------------------------------------------------------------------------------
-- Object: Magma
--------------------------------------------------------------------------------

-----------------------
-- Initialization
-----------------------
assert(d2d, "Error: Initialization table (d2d) wasn't create!")

d2d.magma30x30 = {}
d2d.magma30x30.timer_damage_tick = d2d.magma.timer_damage_tick

-- GFX (for debugging)
local sprite = loadgfx("Doom2D/environment/magma30x30.png")
setmidhandle(sprite)

-----------------------
-- Main
-----------------------

-- Creating
if d2d.debug ~= nil and d2d.debug.DEBUGGING_LIQUIDS_FOR_EDITOR then
	d2d.magma30x30.id = addobject("d2d.magma30x30", sprite)
else
	d2d.magma30x30.id = addobject("d2d.magma30x30", 0)
end

function d2d.magma30x30.setup(id, parameter)
	if objects == nil then objects = {} end
	objects[id] = {}
end

function d2d.magma30x30.update(id, x, y)
	if collision(colplayer, x, y, 0, 1, 0) == 1 then
		-- d2d.magma.damage tick
		d2d.magma30x30.timer_damage_tick[1] = d2d.magma30x30.timer_damage_tick[1] - 1
		
		if d2d.magma30x30.timer_damage_tick[1] <= 0 then
			playerdamage(0, d2d.magma.damage)
			d2d.magma30x30.timer_damage_tick[1] = d2d.magma.max_timer_damage_tick
		end
		
		-- player push
		if keydown(key_left) == 1 or keydown(key_right) == 1 then
			playerpush(0, d2d.liquids.player_push_speed_x, d2d.liquids.player_push_speed_y, 1, 1)
		end
	end
end

function d2d.magma30x30.draw(id, x, y)
	setblend(blend_alpha)
	setalpha(0.6)
	setcolor(255, 255, 255)
	setrotation(0)
	setscale(1, 1)
	drawimage(sprite, x, y)
end

function d2d.magma30x30.damage(id, damage)

end