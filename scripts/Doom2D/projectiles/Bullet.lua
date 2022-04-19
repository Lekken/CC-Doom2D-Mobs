--[[
Doom 2D Projectiles: Bullet
Script by Lekken

Original algorithm by DC (Original Carnage Contest Weapon)
--]]

--------------------------------------------------------------------------------
-- Projectile: Bullet
--------------------------------------------------------------------------------

-----------------------
-- Initialization
-----------------------
assert(d2d ~= nil, "Error: Initialization table (d2d) wasn't create!")

if d2d.projectiles == nil then d2d.projectiles = {} end
d2d.projectiles.bullet = {}

-- GFX
sprite = loadgfx("Doom2D/effects/SHOT.bmp")
setmidhandle(sprite)

-----------------------
-- Main
-----------------------

-- Creating
d2d.projectiles.bullet.id = addprojectile("d2d.projectiles.bullet")

function d2d.projectiles.bullet.create(x, y, rotation_angle, speed, damage, accuracy, ignored_object)
	pid = createprojectile(d2d.projectiles.bullet.id)
	projectiles[pid] = {}
	projectiles[pid].ignore = ignored_object
	--
	projectiles[pid].damage = damage
	projectiles[pid].accuracy = accuracy
	-- Positioning
	projectiles[pid].x = x
	projectiles[pid].y = y
	-- Speed
	projectiles[pid].sx = math.sin(math.rad(rotation_angle + math.random(-projectiles[pid].accuracy, projectiles[pid].accuracy))) * speed
	projectiles[pid].sy = math.cos(math.rad(rotation_angle + math.random(-projectiles[pid].accuracy, projectiles[pid].accuracy))) * speed
end

function d2d.projectiles.bullet.draw(id)
	setblend(blend_light)
	setalpha(1)
	setcolor(255,255,0)
	setscale(0.5, 0.5)
	setrotation(math.deg(math.atan2(projectiles[id].sx, -projectiles[id].sy)))
	drawimage(sprite, projectiles[id].x, projectiles[id].y)
end

function d2d.projectiles.bullet.update(id)
	d2d.projectiles.bullet.move(id)
end

function d2d.projectiles.bullet.move(id)
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
					projectiles[id].x + math.sin(math.rad(rotation)) * 20,
					projectiles[id].y - math.cos(math.rad(rotation)) * 20
					) == 1
		then
			if terraincollision() == 1 or playercollision() ~= 0 or (objectcollision() > 0 and objectcollision() ~= projectiles[id].ignore)  then
				-- Damage to player
				if playercollision() ~= 0 then
					playerdamage(playercollision(), projectiles[id].damage)
					blood(projectiles[id].x + math.sin(math.rad(rotation)) * 20, projectiles[id].y - math.cos(math.rad(rotation)) * 20)
				-- Damage to objects
				elseif objectcollision() > 0 and objectcollision() ~= projectiles[id].ignore then
					objectdamage(objectcollision(), projectiles[id].damage)
				end

				freeprojectile(id)
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