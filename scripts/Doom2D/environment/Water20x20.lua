--[[
Doom 2D: Water
Script by Lekken
--]]

--------------------------------------------------------------------------------
-- Object: Water
--------------------------------------------------------------------------------

-----------------------
-- Initialization
-----------------------
assert(d2d, "Error: Initialization table (d2d) wasn't create!")

d2d.water20x20 = {}

-- GFX (for debugging)
local sprite = loadgfx("Doom2D/environment/water20x20.png")
setmidhandle(sprite)

-----------------------
-- Main
-----------------------

-- Creating
if d2d.debug ~= nil and d2d.debug.DEBUGGING_LIQUIDS_FOR_EDITOR then
	d2d.water20x20.id = addobject("d2d.water20x20", sprite)
else
	d2d.water20x20.id = addobject("d2d.water20x20", 0)
end

function d2d.water20x20.setup(id, parameter)
	if objects == nil then objects = {} end
	objects[id] = {}
end

function d2d.water20x20.update(id, x, y)
	if collision(colplayer, x, y, 0, 1, 0) == 1 then
		if keydown(key_left) == 1 or keydown(key_right) == 1 then
			playerpush(0, liquid_player_push_speed_x, liquid_player_push_speed_y, 1, 1)
		end
	end
end

function d2d.water20x20.draw(id, x, y)
	setblend(blend_alpha)
	setalpha(0.6)
	setcolor(255, 255, 255)
	setrotation(0)
	setscale(1, 1)
	drawimage(sprite, x, y)
end

function d2d.water20x20.damage(id, damage)

end