local esp = {}

local function box_3d(pos1, pos2, box_color)
	assert(
		type(pos1) == "table" and #pos1 == 3,
		"[Error] Box3d: First Argument needs to be a table with 3 position values!"
	)
	assert(
		type(pos2) == "table" and #pos2 == 3,
		"[Error] Box3d: Second Argument needs to be a table with 3 position values!"
	)
	assert(
		type(box_color) == "table" and #box_color == 3,
		"[Error] Box3d: Third Argument needs to be a table with 3 RGB values!"
	)

	local box_matrix = {
		1,
		1,
		1,
		-1,
		1,
		1,
		-1,
		1,
		1,
		-1,
		-1,
		1,
		1,
		1,
		1,
		1,
		-1,
		1,
		1,
		-1,
		1,
		-1,
		-1,
		1,
		1,
		1,
		-1,
		1,
		1,
		1,
		1,
		-1,
		-1,
		1,
		-1,
		1,
		1,
		1,
		-1,
		1,
		-1,
		-1,
		1,
		1,
		-1,
		-1,
		1,
		-1,
		-1,
		-1,
		-1,
		-1,
		1,
		-1,
		1,
		-1,
		-1,
		-1,
		-1,
		-1,
		-1,
		-1,
		-1,
		-1,
		-1,
		1,
		-1,
		1,
		-1,
		-1,
		1,
		1,
	}

	local x = pos1[1] - pos2[1]
	local y = pos1[2] - pos2[2]
	local z = pos1[3] - pos2[3]

	local size = { x, y, z }

	dx9.Box3d(
		box_matrix,
		{ (pos1[1] + pos2[1]) / 2, (pos1[2] + pos2[2]) / 2, (pos1[3] + pos2[3]) / 2 },
		{ 0, 0, 0 },
		size,
		box_color
	)
end

local function get_distance(part)
	local v1 = dx9.get_localplayer().Position
	local v2 = part

	local a = (v1.x - v2.x) * (v1.x - v2.x)
	local b = (v1.y - v2.y) * (v1.y - v2.y)
	local c = (v1.z - v2.z) * (v1.z - v2.z)

	return math.floor(math.sqrt(a + b + c) + 0.5)
end

function esp.ground_circle(params)
	local target = params.target or nil
	local hipheight = params.hipheight or 3
	local nametagheight = params.nametagheight or 0
	local nametag = params.nametag or false
	local custom_nametag = params.custom_nametag or false
	local distance = params.distance or false
	local custom_distance = params.custom_distance or false
	local radius = params.radius or 2.5
	local color = params.color or { 255, 255, 255 }
	local steps = params.steps or 36
	local tracer = params.tracer or false
	local tracertype = params.tracer_type or 1 --// 1 = near-bottom, 2 = bottom, 3 = top, 4 = Mouse

	local pi = math.pi
	local position = params.position or nil

	if position == nil then
		position = target ~= nil and target ~= 0 and dx9.GetPosition(target) or nil
	end

	if position == nil then
		print("[Error] GroundCircle: either params.target or params.position can't be nil")
		return
	end

	local groundposition = {x = position.x, y = position.y - hipheight, z = position.z}
	local nametagposition = {x = position.x, y = position.y + nametagheight, z = position.z}

	if nametag and custom_nametag then
		if distance and custom_distance then
			custom_nametag = custom_nametag .. " [" .. tostring(custom_distance) .. " m]"
		end

		local world_to_screen = dx9.WorldToScreen({ nametagposition.x, nametagposition.y, nametagposition.z })
		dx9.DrawString({ world_to_screen.x - (dx9.CalcTextWidth(custom_nametag) / 2), world_to_screen.y + 20 }, color, custom_nametag)
	end

	if tracer then
		local loc

		if tracertype == 1 then
			loc = { dx9.size().width / 2, dx9.size().height / 1.1 }
		elseif tracertype == 2 then
			loc = { dx9.size().width / 2, dx9.size().height }
		elseif tracertype == 3 then
			loc = { dx9.size().width / 2, 1 }
		else
			loc = { dx9.GetMouse().x, dx9.GetMouse().y }
		end

		local world_to_screen = dx9.WorldToScreen({ position.x, position.y, position.z })
		dx9.DrawLine(loc, { world_to_screen.x, world_to_screen.y, world_to_screen.z }, color)
	end

	for i = 0, steps - 1 do
		local angle_1 = (2 * pi * i) / steps
		local angle_2 = (2 * pi * (i + 1)) / steps

		local point_1 = {
			x = groundposition.x + radius * math.cos(angle_1),
			y = groundposition.y,
			z = groundposition.z + radius * math.sin(angle_1),
		}
		local point_2 = {
			x = groundposition.x + radius * math.cos(angle_2),
			y = groundposition.y,
			z = groundposition.z + radius * math.sin(angle_2),
		}

		local screen_1 = dx9.WorldToScreen({ point_1.x, point_1.y, point_1.z })
		local screen_2 = dx9.WorldToScreen({ point_2.x, point_2.y, point_2.z })

		if screen_1 and screen_2 and screen_1.x and screen_2.x then
			dx9.DrawLine({ screen_1.x, screen_1.y }, { screen_2.x, screen_2.y }, color)
		end
	end
end

function esp.circle(params)
	local target = params.target or nil
	local nametag = params.nametag or false
	local radius = params.radius or 5
	local color = params.color or { 255, 255, 255 }
	local no_circle = params.no_circle or false

	if target == nil then
		print("[Error] CircleESP: Target can't be nil")
		return false
	end

	local position = dx9.GetPosition(target)
	local world_to_screen = dx9.WorldToScreen({ position.x, position.y, position.z })

	if nametag then
		dx9.DrawString({ world_to_screen.x - (dx9.CalcTextWidth(nametag) / 2), world_to_screen.y + 20 }, color, nametag)
	end

	if not no_circle then
		dx9.DrawCircle({ world_to_screen.x, world_to_screen.y }, color, radius)
	end
end

function esp.draw(params) -- params = {*Target = model, Color = {r,g,b}, Healthbar = false, Distance = false, Nametag = false, Tracer = false, TracerType = 1, BoxType = 1}
	local target = params.target or nil
	local esp_type = params.esp_type or nil
	local box_color = params.color or { 255, 255, 255 }
	local healthbar = params.healthbar or false
	local distance = params.distance or false
	local nametag = params.nametag or false
	local custom_nametag = params.custom_nametag or false
	local custom_distance = params.custom_distance or nil
	local custom_root = params.custom_root or "HumanoidRootPart"
	local custom_size = params.custom_size or nil
	local tracer = params.tracer or false
	local tracertype = params.tracer_type or 1 --// 1 = near-bottom, 2 = bottom, 3 = top, 4 = Mouse
	local box_type = params.box_type or 1 --// 1 = corners, 2 = 2d box, 3 = 3d box

	--// Error Handling
	assert(
		type(tracertype) == "number" and (tracertype == 1 or tracertype == 2 or tracertype == 3 or tracertype == 4),
		"[Error] BoxESP: TracerType Argument needs to be a number! (1 - 4)"
	)
	assert(
		type(box_type) == "number" and (box_type == 1 or box_type == 2 or box_type == 3),
		"[Error] BoxESP: BoxType Argument needs to be a number! (1 - 3)"
	)
	assert(
		type(target) == "number" and dx9.GetChildren(target) ~= nil,
		"[Error] BoxESP: Target Argument needs to be a number (pointer) to character!"
	)
	assert(
		type(box_color) == "table" and #box_color == 3,
		"[Error] BoxESP: Color Argument needs to be a table with 3 RGB values!"
	)

	if esp_type == "misc" then
		local position = dx9.GetPosition(target)
		local offset_top = 3
		local offset_bottom = 3
		local custom_width = nil -- Default width value

		if custom_size then
			offset_top = custom_size.top or offset_top
			offset_bottom = custom_size.bottom or offset_bottom
			custom_width = custom_size.width
		end

		local Top = dx9.WorldToScreen({ position.x, position.y + offset_top, position.z })
		local Bottom = dx9.WorldToScreen({ position.x, position.y - offset_bottom, position.z })

		local height = math.abs(Top.y - Bottom.y)
		local width = custom_width or (height / 2)

		if box_type == 1 then -- corners
			dx9.DrawLine({ Top.x + width, Top.y }, { Top.x + (width / 2), Top.y }, box_color)
			dx9.DrawLine({ Top.x + width, Top.y }, { Top.x + width, Top.y + (height / 4) }, box_color)

			dx9.DrawLine({ Top.x - width, Top.y }, { Top.x - (width / 2), Top.y }, box_color)
			dx9.DrawLine({ Top.x - width, Top.y }, { Top.x - width, Top.y + (height / 4) }, box_color)

			dx9.DrawLine({ Bottom.x + width, Bottom.y }, { Bottom.x + (width / 2), Bottom.y }, box_color)
			dx9.DrawLine({ Bottom.x + width, Bottom.y }, { Bottom.x + width, Bottom.y - (height / 4) }, box_color)

			dx9.DrawLine({ Bottom.x - width, Bottom.y }, { Bottom.x - (width / 2), Bottom.y }, box_color)
			dx9.DrawLine({ Bottom.x - width, Bottom.y }, { Bottom.x - width, Bottom.y - (height / 4) }, box_color)
		elseif box_type == 2 then
			dx9.DrawBox({ Bottom.x - width, Top.y }, { Top.x + width, Bottom.y }, box_color)
		else
			box_3d(
				{ position.x - 2, position.y + 2, position.z - 2 },
				{ position.x + 2, position.y - 2, position.z + 2 },
				box_color
			)
		end

		if nametag and custom_nametag then
			local name = custom_nametag

			dx9.DrawString({ Top.x - (dx9.CalcTextWidth(name) / 2), Top.y - 20 }, box_color, name)
		end

		if distance then
			local dist = custom_distance or "" .. get_distance(position)
			dx9.DrawString({ Bottom.x - (dx9.CalcTextWidth(dist) / 2), Bottom.y }, box_color, dist)
		end

		if tracer then
			local loc

			if tracertype == 1 then
				loc = { dx9.size().width / 2, dx9.size().height / 1.1 }
			elseif tracertype == 2 then
				loc = { dx9.size().width / 2, dx9.size().height }
			elseif tracertype == 3 then
				loc = { dx9.size().width / 2, 1 }
			else
				loc = { dx9.GetMouse().x, dx9.GetMouse().y }
			end

			if (Top.x + width + (((Bottom.x - width) - (Top.x + width)) / 2)) + Bottom.y ~= 0 then
				dx9.DrawLine(loc, { Top.x + width + (((Bottom.x - width) - (Top.x + width)) / 2), Bottom.y }, box_color)
			end
		end
	else
		if dx9.FindFirstChild(target, custom_root) and dx9.GetPosition(dx9.FindFirstChild(target, custom_root)) then
			local torso = dx9.GetPosition(dx9.FindFirstChild(target, custom_root))

			local HeadPosY = torso.y + 2.5
			local LegPosY = torso.y - 3.5

			local Top = dx9.WorldToScreen({ torso.x, HeadPosY, torso.z })
			local Bottom = dx9.WorldToScreen({ torso.x, LegPosY, torso.z })

			local height = Top.y - Bottom.y

			local width = (height / 2)
			width = width / 1.2

			--// Draw Box
			if box_type == 1 then --// cormers
				dx9.DrawLine({ Top.x + width + 2, Top.y }, { Top.x + (width / 2) + 2, Top.y }, box_color) -- TopLeft 1
				dx9.DrawLine({ Top.x + width + 2, Top.y }, { Top.x + width + 2, Top.y - (height / 4) }, box_color) -- TopLeft 2

				dx9.DrawLine({ Bottom.x - width, Top.y }, { Bottom.x - (width / 2), Top.y }, box_color) -- TopRight 1
				dx9.DrawLine({ Bottom.x - width, Top.y }, { Bottom.x - width, Top.y - (height / 4) }, box_color) -- TopRight 2

				dx9.DrawLine({ Top.x + width + 2, Bottom.y }, { Top.x + (width / 2) + 2, Bottom.y }, box_color) -- BottomLeft 1
				dx9.DrawLine({ Top.x + width + 2, Bottom.y }, { Top.x + width + 2, Bottom.y + (height / 4) }, box_color) -- BottomLeft 2

				dx9.DrawLine({ Bottom.x - width, Bottom.y }, { Bottom.x - (width / 2), Bottom.y }, box_color) -- BottomRight 1
				dx9.DrawLine({ Bottom.x - width, Bottom.y }, { Bottom.x - width, Bottom.y + (height / 4) }, box_color) -- BottomRight 2
			elseif box_type == 2 then
				dx9.DrawBox({ Bottom.x - width, Top.y }, { Top.x + width, Bottom.y }, box_color)
			else
				box_3d({ torso.x - 2, HeadPosY, torso.z - 2 }, { torso.x + 2, LegPosY, torso.z + 2 }, box_color)
			end

			if healthbar then
				if dx9.FindFirstChild(target, "Humanoid") then
					local tl = { Top.x + width - 5, Top.y + 1 }
					local br = { Top.x + width - 1, Bottom.y - 1 }

					local humanoid = dx9.FindFirstChild(target, "Humanoid")
					local hp = dx9.GetHealth(humanoid)
					local maxhp = dx9.GetMaxHealth(humanoid)

					--// A lot of math stuff, dont mess with it unless u know what ur doing
					local addon = ((height + 2) / (maxhp / math.max(0, math.min(maxhp, hp))))

					dx9.DrawBox({ tl[1] - 1, tl[2] - 1 }, { br[1] + 1, br[2] + 1 }, box_color) -- Outer
					dx9.DrawFilledBox({ tl[1], tl[2] }, { br[1], br[2] }, { 0, 0, 0 }) -- Inner Black
					dx9.DrawFilledBox(
						{ tl[1] + 1, br[2] - 1 },
						{ br[1] - 1, (br[2] + addon + 1) },
						{ 255 - 255 / (maxhp / hp), 255 / (maxhp / hp), 0 }
					) -- Inner
				else
					error("[Error] BoxESP: Target has no humanoid, healthbar not added")
				end
			end

			if distance then
				local dist = custom_distance or "" .. get_distance(torso)
				dx9.DrawString({ Bottom.x - (dx9.CalcTextWidth(dist) / 2), Bottom.y }, box_color, dist)
			end

			if nametag then
				local name = dx9.GetName(target)

				if custom_nametag then
					name = custom_nametag
				end

				dx9.DrawString({ Top.x - (dx9.CalcTextWidth(name) / 2), Top.y - 20 }, box_color, name)
			end

			if tracer then
				local loc -- Location of tracer start

				if tracertype == 1 then
					loc = { dx9.size().width / 2, dx9.size().height / 1.1 }
				elseif tracertype == 2 then
					loc = { dx9.size().width / 2, dx9.size().height }
				elseif tracertype == 3 then
					loc = { dx9.size().width / 2, 1 }
				else
					loc = { dx9.GetMouse().x, dx9.GetMouse().y }
				end

				if (Top.x + width + (((Bottom.x - width) - (Top.x + width)) / 2)) + Bottom.y ~= 0 then
					dx9.DrawLine(
						loc,
						{ Top.x + width + (((Bottom.x - width) - (Top.x + width)) / 2), Bottom.y },
						box_color
					)
				end
			end
		else
			print("[Error] BoxESP: Passed in target has no HumanoidRootPart")
		end
	end
end

return esp
