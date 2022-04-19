--[[
Doom 2D Enemies: Explosive Barrel
Script by Lekken
--]]

--------------------------------------------------------------------------------
-- Object: Explosive Barrel
--------------------------------------------------------------------------------

-----------------------
-- Initialization
-----------------------
assert(d2d, "Error: Initialization table (d2d) wasn't create!")

if d2d.mob == nil then d2d.mob = {} end
d2d.mob.barrel = {}

-- GENERAL
local gravity_coef = 20

-- Fire damage constants
local min_fire_damage = 4
local max_fire_damage = 7
local max_fire_damage_timer = d2d.default_fps / 2

-- ANIMATION
local animations = {}
-- Attack
animations.wait = {}
animations.wait.frames = 3
animations.wait.duration = d2d.default_fps / 3
-- Death
animations.death = {}
animations.death.frames = 4
animations.death.duration = d2d.default_fps / 3

-- GFX
local sprites = {}
-- Waiting
sprites.wait = {}
for i = 1, animations.wait.frames do
	sprites.wait[i] = loadgfx("Doom2D/mobs/ExplosiveBarrel/BARREL_SLEEP_"..i..".png")
	setmidhandle(sprites.wait[i])
end
-- Death
sprites.death = {}
for i = 1, animations.death.frames do
	sprites.death[i] = loadgfx("Doom2D/mobs/ExplosiveBarrel/BARREL_DIE_"..i..".png")
	setmidhandle(sprites.death[i])
end

-- SFX
local sounds = {}
sounds.death = loadsfx("Doom2D/mobs/ExplosiveBarrel/BARREL_DIE.ogg")

-----------------------
-- Main
-----------------------

-- Creating
d2d.mob.barrel.id = addobject("d2d.mob.barrel", sprites.wait[1])

function d2d.mob.barrel.setup(id, parameter)
	if objects == nil then objects = {} end
	objects[id] = {}
	
	-- General
	objects[id].id = id
	objects[id].state = d2d.mob_states.SLEEP
	--
	objects[id].health = 20
	objects[id].damage = 70
	objects[id].explosive_radius = 60
	
	-- Timers
	objects[id].timers = {}
	objects[id].timers.firedamage_tick = d2d.fire.max_timer 
	objects[id].timers.disappear_after_death = d2d.default_fps / 10
	
	-- Flags
	objects[id].is_explosed = false
	
	-- Graphics
	objects[id].current_gfx = sprites.wait[1]
	d2d.mob.barrel.reset_animation(id)
end

function d2d.mob.barrel.update(id, x, y)
	if objects[id].state ~= d2d.mob_states.DEAD then
		d2d.mob.barrel.position(id, x, y)
		d2d.mob.barrel.fire_damage(id, x, y)
	else
		d2d.mob.barrel.explosive(id, x, y)
	end
	
	d2d.mob.barrel.animation(id)
	
	-- Debug
	if d2d.debug ~= nil and d2d.debug.DEBUG_LOG then
		d2d.debug.log("Explosive Barrel", objects[id])
	end
end

function d2d.mob.barrel.draw(id, x, y)
	setblend(blend_alpha)
	setalpha(1)
	setcolor(255, 255, 255)
	setrotation(0)
	setscale(1, 1)

	drawimage(objects[id].current_gfx, x, y)
end

function d2d.mob.barrel.damage(id, damage)
	objects[id].health = objects[id].health - damage
	if objects[id].health <= 0 then
		objects[id].state = d2d.mob_states.DEAD
	end
end

function d2d.mob.barrel.fire_damage(id, x, y)
	if firecollision(objects[id].current_gfx, x, y) > 0 then
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

function d2d.mob.barrel.animation(id)
	if objects[id].state == d2d.mob_states.DEAD then
		d2d.mob.barrel.animation_death(id)
		return
	end

	d2d.mob.barrel.animation_waiting(id)
end

function d2d.mob.barrel.animation_waiting(id)
	d2d.mob.barrel.play_animation(id, animations.wait)
	objects[id].current_gfx = sprites.wait[objects[id].current_animation_frame]
end

function d2d.mob.barrel.animation_death(id)
	d2d.mob.barrel.play_animation(id, animations.death, true)
	objects[id].current_gfx = sprites.death[objects[id].current_animation_frame]
end

function d2d.mob.barrel.play_animation(id, animation, once)
	if (objects[id].timers.animation % math.ceil(animation.duration / animation.frames)) == 0
	then
		if once and objects[id].current_animation_frame >= animation.frames then
			objects[id].current_animation_frame = animation.frames
		else
			objects[id].current_animation_frame = objects[id].current_animation_frame + 1
			if objects[id].current_animation_frame > animation.frames then
				d2d.mob.barrel.reset_animation(id)
			end
		end
	end
	objects[id].timers.animation = objects[id].timers.animation + 1
end

function d2d.mob.barrel.reset_animation(id)
	objects[id].current_animation_frame = 1
	objects[id].timers.animation = 1
end

-----------------------
-- Mechanics
-----------------------

function d2d.mob.barrel.position(id, x, y)
	-- Gravity
	local offset_y = gravity_coef / (gravity_coef / 10)
	if collision(col5x5, x, y + offset_y, 1, 0, 1, 0, id) == 0 then
		y = y + getgravity() * gravity_coef
	end
	
	objectposition(id, x, y)
end

function d2d.mob.barrel.explosive(id, x, y)
	if not objects[id].is_explosed then
		playsound(sounds.death)
		arealdamage(x, y, objects[id].explosive_radius, objects[id].damage)
		objects[id].is_explosed = true
	elseif objects[id].current_animation_frame == animations.death.frames then
		objects[id].timers.disappear_after_death = objects[id].timers.disappear_after_death - 1
		if objects[id].timers.disappear_after_death <= 0 then
			removeobject(id)
		end
	end
end