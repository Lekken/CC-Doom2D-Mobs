--------------------------------------------------------------------------------
-- DEBUG
--------------------------------------------------------------------------------

assert(d2d, "Error: Initialization table (d2d) wasn't create!")

if d2d.debug == nil then d2d.debug = {} end

-- Switch on/off debugging
d2d.debug.DEBUG_LOG = true
d2d.debug.DEBUGGING_COLLISIONS_MATRIX = false
d2d.debug.DEBUGGING_LIQUIDS_FOR_EDITOR = false


function d2d.debug.print(title, var)
	if 		var == nil 		then var = "NaN"
	elseif 	var == true 	then var = "true"
	elseif 	var == false	then var = "false"
	end
	
	print(title..": "..var)
end

function d2d.debug.decode_state(state)
	if state == d2d.mob_states.DEAD then
		return "DEAD"
	elseif state == d2d.mob_states.SLEEP then
		return "SLEEP"
	elseif state == d2d.mob_states.MOVE then
		return "MOVE"
	elseif state == d2d.mob_states.ATTACK then
		return "ATTACK"
	end
end

function d2d.debug.log_player()
	print("**********")
	print("Player")
	d2d.debug.print("health", getplayerhealth(playercurrent()))
	d2d.debug.print("x", getplayerx(playercurrent()))
	d2d.debug.print("y", getplayery(playercurrent()))
end

function d2d.debug.log(title, object)
	d2d.debug.log_player()
	print("**********")
	print(title..": "..object.id)
	if object.health then d2d.debug.print("health", object.health) end
	if object.x then d2d.debug.print("x", object.x) end
	if object.y then d2d.debug.print("y", object.y) end
	if object.dx then d2d.debug.print("dx", object.dx) end
	if object.dy then d2d.debug.print("dy", object.dy) end
	if object.distance then d2d.debug.print("distance", object.distance) end
	if object.relative_angle_to_player then d2d.debug.print("relative_angle_to_player", object.relative_angle_to_player) end 
	if object.direction then d2d.debug.print("direction", object.direction) end
	if object.vdirection then d2d.debug.print("vdirection", object.vdirection) end
	if object.elevation_relative_to_horizon then d2d.debug.print("elevation_relative_to_horizon", object.elevation_relative_to_horizon) end
	if object.elevation_relative_to_player then d2d.debug.print("elevation_relative_to_player", object.elevation_relative_to_player) end
	if object.is_seeing then d2d.debug.print("see", object.is_seeing) end
	if object.state then d2d.debug.print("state", d2d.debug.decode_state(object.state)) end
end

function d2d.debug.draw_view_collisions_matrix(object, rect_size)
	setblend(blend_alpha)
	setrotation(0)
	setscale(1, 1)

	local rows = #object.view_matrix_of_collisions
	local cols = #object.view_matrix_of_collisions[1]
	
	for row = 1, rows do
		for col = 1, cols do			
			-- drawing the center point of collision check
			setalpha(0.8)
			setcolor(0, 0, 255)
			drawrect(object.x + object.direction * (col * rect_size),
					object.y + object.elevation_relative_to_player * (row - 1) * rect_size,
					1, 1)
					
			-- drawing the rectangle of collision
			setalpha(0.4)
			if object.view_matrix_of_collisions[row][col] == 1 then
				setcolor(255, 0, 0)
			elseif object.view_matrix_of_collisions[row][col] == 0 then
				setcolor(0, 255, 0)
			else
				etcolor(0, 0, 255)
			end
			drawrect(object.x + object.direction * (col * rect_size) - rect_size / 2,
					object.y + object.elevation_relative_to_player * ((row - 1) * rect_size) - rect_size / 2,
					rect_size - 1, rect_size - 1)	-- minus 1 px for view borders between rects
		end
	end
end
