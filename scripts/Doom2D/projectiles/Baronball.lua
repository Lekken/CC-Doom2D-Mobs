--[[
Doom 2D Projectiles: Baronball
Script by Lekken

Original algorithm by DC (Original Carnage Contest Weapon)
--]]

--------------------------------------------------------------------------------
-- Projectile: baronball
--------------------------------------------------------------------------------

-----------------------
-- Initialization
-----------------------
assert(d2d ~= nil, "Error: Initialization table (d2d) wasn't create!")

if d2d.projectiles == nil then d2d.projectiles = {} end
d2d.projectiles.baronball = {}

-- ANIMATION
local animations = {}
-- Projectile
animations.move = {}
animations.move.frames = 2
animations.move.duration = d2d.default_fps / 4
-- Explosion
animations.explosion = {}
animations.explosion.frames = 3
animations.explosion.duration = d2d.default_fps / 5

-- GFX
local sprites = {}
-- Size (average)
sprites.width = 7
sprites.height = 30
-- Projectile
sprites.move = {}
for i = 1, animations.move.frames do
	sprites.move[i] = loadgfx("Doom2D/effects/BBARONFIRE_"..i..".png")
	setmidhandle(sprites.move[i])
end
-- Explosion
sprites.explosion = {}
for i = 1, animations.explosion.frames do
	sprites.explosion[i] = loadgfx("Doom2D/effects/EBARONFIRE_"..i..".png")
	setmidhandle(sprites.explosion[i])
end

-- SFX
local sounds = {}
sounds.explosion = loadsfx("Doom2D/effects/EXPLODEBALL.ogg")

-----------------------
-- Main
-----------------------

-- Creating
d2d.projectiles.baronball.id = addprojectile("d2d.projectiles.baronball")

function d2d.projectiles.baronball.create(x, y, rotation_angle, speed, damage, accuracy, ignored_object)
	pid = createprojectile(d2d.projectiles.baronball.id)
	projectiles[pid] = {}
	projectiles[pid].ignore = ignored_object
	projectiles[pid].lifetime = d2d.max_projectile_lifetime
	--
	projectiles[pid].damage = damage
	projectiles[pid].accuracy = accuracy
	-- Positioning
	projectiles[pid].x = x
	projectiles[pid].y = y
	-- Speed
	projectiles[pid].sx = math.sin(math.rad(rotation_angle + math.random(-projectiles[pid].accuracy, projectiles[pid].accuracy))) * speed
	projectiles[pid].sy = math.cos(math.rad(rotation_angle + math.random(-projectiles[pid].accuracy, projectiles[pid].accuracy))) * speed
	
	-- Flags
	projectiles[pid].is_explosed = false
	
	-- Timers
	projectiles[pid].timers = {}
	projectiles[pid].timers.disappear_after_explosion = animations.explosion.duration

	-- Graphics
	projectiles[pid].current_gfx = sprites.move[1]
	projectiles[pid].current_animation_frame = 1
	projectiles[pid].timers.animation = 0
end

function d2d.projectiles.baronball.draw(id)
	setblend(blend_alpha)
	setalpha(1)
	setcolor(255,255,0)
	setscale(1, 1)
	setrotation(math.deg(math.atan2(projectiles[id].sx, -projectiles[id].sy)))
	drawimage(projectiles[id].current_gfx, projectiles[id].x, projectiles[id].y)
end

function d2d.projectiles.baronball.animation(id)
	if projectiles[id].is_explosed then
		if (projectiles[id].timers.animation % math.ceil(animations.explosion.duration / animations.explosion.frames)) == 0
		then
			if projectiles[id].current_animation_frame >= animations.explosion.frames then
				projectiles[id].current_animation_frame = animations.explosion.frames
			else
				projectiles[id].current_animation_frame = projectiles[id].current_animation_frame + 1
			end
		end
		projectiles[id].timers.animation = projectiles[id].timers.animation + 1
		projectiles[id].current_gfx = sprites.explosion[projectiles[id].current_animation_frame]
	else
		projectiles[id].current_gfx = sprites.move
	end
end

function d2d.projectiles.baronball.update(id)
	-- Lifetime
	projectiles[id].lifetime = projectiles[id].lifetime - 1
	if projectiles[id].lifetime <= 0 then	
		freeprojectile(id)
	end

	d2d.projectiles.baronball.animation(id)
	d2d.projectiles.baronball.move(id)
end

function d2d.projectiles.baronball.move(id)
	if projectiles[id].is_explosed then
		projectiles[id].timers.disappear_after_explosion = projectiles[id].timers.disappear_after_explosion - 1
		if projectiles[id].timers.disappear_after_explosion < 0 then
			freeprojectile(id)
		end
		return
	end

	local rotation = math.deg(math.atan2(projectiles[id].sx, -projectiles[id].sy))
	-- Move (in substep loop for optimal collision precision)
	local msubt = math.ceil(math.max(math.abs(projectiles[id].sx), math.abs(projectiles[id].sy)) / 3)
	local msubx = projectiles[id].sx / msubt
	local msuby = projectiles[id].sy / msubt
	
	for i=1, msubt, 1 do
		projectiles[id].x = projectiles[id].x + msubx
		projectiles[id].y = projectiles[id].y + msuby
		
		-- Collision
		if collision(col3x3,
					projectiles[id].x + math.sin(math.rad(rotation)) * (sprites.height / 2),
					projectiles[id].y - math.cos(math.rad(rotation)) * (sprites.height / 2)
			) == 1
		then
			if terraincollision() == 1 or playercollision() ~= 0 or (objectcollision() > 0 and objectcollision() ~= projectiles[id].ignore)  then
				-- Damage to player
				if playercollision() ~= 0 then
					playerdamage(playercollision(), projectiles[id].damage)
					blood(projectiles[id].x + math.sin(math.rad(rotation)) * (sprites.height / 2), projectiles[id].y - math.cos(math.rad(rotation)) * (sprites.height / 2))
				-- Damage to objects
				elseif objectcollision() > 0 and objectcollision() ~= projectiles[id].ignore then
					objectdamage(objectcollision(), projectiles[id].damage)
				end

				-- Explosion
				projectiles[id].is_explosed = true
				projectiles[id].current_animation_frame = 1
				playsound(sounds.explosion)
				return 1
			end
		else
			projectiles[id].ignore = 0
		end
		
		-- Water
		if (projectiles[id].y) > getwatery()+5 then
			particle(p_waterhit,projectiles[id].x,projectiles[id].y)
			
			if math.random(1,2) == 1 then
				playsound(sfx_hitwater2)
			else
				playsound(sfx_hitwater3)
			end
			
			freeprojectile(id)
			return 1
		end
	end
end

-----------------------
-- Animation
-----------------------

function d2d.projectiles.baronball.animation(id)
	if projectiles[id].is_explosed then
		d2d.projectiles.baronball.animation_explosion(id)
	else
		d2d.projectiles.baronball.animation_move(id)
	end
end

function d2d.projectiles.baronball.animation_move(id)
	d2d.projectiles.baronball.play_animation(id, animations.move)
	projectiles[id].current_gfx = sprites.move[projectiles[id].current_animation_frame]
end

function d2d.projectiles.baronball.animation_explosion(id)	
	d2d.projectiles.baronball.play_animation(id, animations.explosion, true)
	projectiles[id].current_gfx = sprites.explosion[projectiles[id].current_animation_frame]
end

function d2d.projectiles.baronball.play_animation(id, animation, once)
	if (projectiles[id].timers.animation % math.ceil(animation.duration / animation.frames)) == 0
	then
		if once and projectiles[id].current_animation_frame >= animation.frames then
			projectiles[id].current_animation_frame = animation.frames
		else
			projectiles[id].current_animation_frame = projectiles[id].current_animation_frame + 1
			if projectiles[id].current_animation_frame > animation.frames then
				projectiles[id].current_animation_frame = 1
				projectiles[id].timers.animation = 1
			end
		end
	end
	projectiles[id].timers.animation = projectiles[id].timers.animation + 1
end