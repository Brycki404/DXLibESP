-- DX9Ware ESP Drawing Library (main2.lua)
-- Unified box drawing function: 2D corners, 2D box, 3D box, with anchor return

local esp = {}

-- Get the squared distance between two 3D points {x, y, z}
function esp.get_distance_sqrd(pos1, pos2)
    local a = (pos1.x - pos2.x) * (pos1.x - pos2.x)
    local b = (pos1.y - pos2.y) * (pos1.y - pos2.y)
    local c = (pos1.z - pos2.z) * (pos1.z - pos2.z)
    return a + b + c
end

-- Get distance between two 3D points {x, y, z}
function esp.get_distance(pos1, pos2)
    local sqrd = esp.get_distance_sqrd(pos1, pos2)
    return math.sqrt(sqrd)
end

function esp.draw_line_2d_anchored(p1, p2, color, thickness, return_anchors)
	dx9.DrawLine({p1.x, p1.y}, {p2.x, p2.y}, color or {255,255,255}, thickness or 1)
    if return_anchors ~= true then return end
    local anchors = {
        ["start"] = { x = p1.x, y = p1.y },
        ["end"] = { x = p2.x, y = p2.y },
        ["center"] = { x = (p1.x + p2.x) / 2, y = (p1.y + p2.y) / 2 }
    }
    return anchors
end

-- Draw a ground circle and return 2D anchor points (center, top, bottom, left, right, corners)
function esp.draw_ground_circle(params, return_anchors)
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

    if return_anchors ~= true then return end

	-- Project key points for anchors
	local anchors3d = {
		center = { x = groundposition.x, y = groundposition.y, z = groundposition.z },
		top = { x = groundposition.x, y = groundposition.y, z = groundposition.z + radius },
		bottom = { x = groundposition.x, y = groundposition.y, z = groundposition.z - radius },
		left = { x = groundposition.x - radius, y = groundposition.y, z = groundposition.z },
		right = { x = groundposition.x + radius, y = groundposition.y, z = groundposition.z },
		topleft = { x = groundposition.x - radius * 0.707, y = groundposition.y, z = groundposition.z + radius * 0.707 },
		topright = { x = groundposition.x + radius * 0.707, y = groundposition.y, z = groundposition.z + radius * 0.707 },
		bottomleft = { x = groundposition.x - radius * 0.707, y = groundposition.y, z = groundposition.z - radius * 0.707 },
		bottomright = { x = groundposition.x + radius * 0.707, y = groundposition.y, z = groundposition.z - radius * 0.707 },
	}
	local anchors2d = {}
	for k, v in pairs(anchors3d) do
		local s = dx9.WorldToScreen({ v.x, v.y, v.z })
		if s and s.x and s.y then anchors2d[k] = { x = s.x, y = s.y } end
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
	return anchors2d
end

-- Draw a rotated box around a part using its CFrame and size
-- Draw a rotated box around a part using its CFrame and size, return 2D anchors
function esp.draw_part_box(part, size, color, return_anchors)
	-- part: part instance (number)
	-- size: {x, y, z} (half extents)
	-- color: {r, g, b}
	assert(part and type(size) == "table" and #size == 3 and type(color) == "table" and #color == 3, "draw_part_box: bad args")
	local cframe = dx9.GetCFrame(part)
	if not cframe then return end
	local r = cframe.RightVector
	local u = cframe.UpVector
	local l = cframe.LookVector
	local matrix = {
		r.x, u.x, l.x,
		r.y, u.y, l.y,
		r.z, u.z, l.z
	}
	local pos = cframe.Position
	local BoxCoords = {
		1,1,1,  -1,1,1,  -1,-1,1,  1,-1,1,
		1,1,-1, -1,1,-1, -1,-1,-1, 1,-1,-1
	}
	local box_size = { size[1]*2, size[2]*2, size[3]*2 }
	dx9.Box3d(BoxCoords, {pos.x, pos.y, pos.z}, matrix, box_size, color)

    if return_anchors ~= true then return end

	-- Project 8 corners to screen for anchors
	local corners3d = {
		{ 1, 1, 1 }, { -1, 1, 1 }, { -1, -1, 1 }, { 1, -1, 1 },
		{ 1, 1, -1 }, { -1, 1, -1 }, { -1, -1, -1 }, { 1, -1, -1 }
	}
	local anchors2d = {}
	for i, c in ipairs(corners3d) do
		-- Transform corner to world
		local wx = pos.x + r.x * size[1] * c[1] + u.x * size[2] * c[2] + l.x * size[3] * c[3]
		local wy = pos.y + r.y * size[1] * c[1] + u.y * size[2] * c[2] + l.y * size[3] * c[3]
		local wz = pos.z + r.z * size[1] * c[1] + u.z * size[2] * c[2] + l.z * size[3] * c[3]
		local s = dx9.WorldToScreen({ wx, wy, wz })
		if s and s.x and s.y then anchors2d[i] = { x = s.x, y = s.y } end
	end
	-- Optionally, return center and bounding box
	if #anchors2d > 0 then
		local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
		for _, pt in pairs(anchors2d) do
			if pt.x < minx then minx = pt.x end
			if pt.y < miny then miny = pt.y end
			if pt.x > maxx then maxx = pt.x end
			if pt.y > maxy then maxy = pt.y end
		end
		anchors2d.center = { x = (minx + maxx) / 2, y = (miny + maxy) / 2 }
		anchors2d.topleft = { x = minx, y = miny }
		anchors2d.topright = { x = maxx, y = miny }
		anchors2d.bottomleft = { x = minx, y = maxy }
		anchors2d.bottomright = { x = maxx, y = maxy }
		anchors2d.top = { x = (minx + maxx) / 2, y = miny }
		anchors2d.bottom = { x = (minx + maxx) / 2, y = maxy }
		anchors2d.left = { x = minx, y = (miny + maxy) / 2 }
		anchors2d.right = { x = maxx, y = (miny + maxy) / 2 }
	end
	return anchors2d
end

-- Wrapper for dx9.DrawBox with anchor support
function esp.draw_box_2d_anchored(topleft, bottomright, color, thickness, return_anchors)
	dx9.DrawBox({topleft.x, topleft.y}, {bottomright.x, bottomright.y}, color or {255,255,255}, thickness or 1)
    if return_anchors ~= true then return end
	local x1, y1 = topleft.x, topleft.y
	local x2, y2 = bottomright.x, bottomright.y
	local anchors = {
		center      = { x = (x1 + x2) / 2, y = (y1 + y2) / 2 },
		top         = { x = (x1 + x2) / 2, y = y1 },
		bottom      = { x = (x1 + x2) / 2, y = y2 },
		left        = { x = x1, y = (y1 + y2) / 2 },
		right       = { x = x2, y = (y1 + y2) / 2 },
		topleft     = { x = x1, y = y1 },
		topright    = { x = x2, y = y1 },
		bottomleft  = { x = x1, y = y2 },
		bottomright = { x = x2, y = y2 },
	}
	return anchors
end

-- Wrapper for dx9.DrawCircle with anchor support
function esp.draw_circle_2d_anchored(center, radius, color, steps, return_anchors)
	dx9.DrawCircle({center.x, center.y}, color or {255,255,255}, radius, steps or 36)
    if return_anchors ~= true then return end
	local anchors = {
		center = { x = center.x, y = center.y },
		top = { x = center.x, y = center.y - radius },
		bottom = { x = center.x, y = center.y + radius },
		left = { x = center.x - radius, y = center.y },
		right = { x = center.x + radius, y = center.y },
		topleft = { x = center.x - radius * 0.707, y = center.y - radius * 0.707 },
		topright = { x = center.x + radius * 0.707, y = center.y - radius * 0.707 },
		bottomleft = { x = center.x - radius * 0.707, y = center.y + radius * 0.707 },
		bottomright = { x = center.x + radius * 0.707, y = center.y + radius * 0.707 },
	}
	return anchors
end

-- Draw a vertical healthbar next to a 2D box
function esp.draw_healthbar(top_left, bottom_right, health, maxhealth, color, fill_direction, return_anchors)
	-- top_left, bottom_right: {x, y} (bounding box of the bar)
	-- health, maxhealth: numbers
	-- color: {r, g, b}
	-- fill_direction: "vertical" (bottom-up, default), "horizontal" (left-right), "right-left", "top-down", "center-vertical", "center-horizontal"
	fill_direction = fill_direction or "vertical"
	local bar_color = color or {0, 255, 0}
	local outline_color = { 255, 255, 255 }
	local bg_color = { 0, 0, 0 }
	dx9.DrawBox({ top_left.x - 1, top_left.y - 1 }, { bottom_right.x + 1, bottom_right.y + 1 }, outline_color)
	dx9.DrawFilledBox({ top_left.x, top_left.y }, { bottom_right.x, bottom_right.y }, bg_color)
	local percent = math.max(0, math.min(1, health / math.max(1, maxhealth)))
	local x1, y1 = top_left.x, top_left.y
	local x2, y2 = bottom_right.x, bottom_right.y
	local anchors = {}
	if fill_direction == "horizontal" or fill_direction == "left-right" then
		-- Fill left to right
		local bar_len = x2 - x1
		local fill_len = percent * bar_len
		dx9.DrawFilledBox(
			{ x1, y1 },
			{ x1 + fill_len, y2 },
			bar_color
		)
		if return_anchors ~= true then return end
		anchors.fill = {
			topleft = { x = x1, y = y1 },
			bottomleft = { x = x1, y = y2 },
			topright = { x = x1 + fill_len, y = y1 },
			bottomright = { x = x1 + fill_len, y = y2 },
			center = { x = x1 + fill_len / 2, y = (y1 + y2) / 2 },
		}
	elseif fill_direction == "right-left" then
		-- Fill right to left
		local bar_len = x2 - x1
		local fill_len = percent * bar_len
		dx9.DrawFilledBox(
			{ x2 - fill_len, y1 },
			{ x2, y2 },
			bar_color
		)
		if return_anchors ~= true then return end
		anchors.fill = {
			topleft = { x = x2 - fill_len, y = y1 },
			bottomleft = { x = x2 - fill_len, y = y2 },
			topright = { x = x2, y = y1 },
			bottomright = { x = x2, y = y2 },
			center = { x = x2 - fill_len / 2, y = (y1 + y2) / 2 },
		}
	elseif fill_direction == "vertical" or fill_direction == "bottom-up" then
		-- Fill bottom to top
		local bar_height = y2 - y1
		local fill_height = percent * bar_height
		dx9.DrawFilledBox(
			{ x1, y2 - fill_height },
			{ x2, y2 },
			bar_color
		)
		if return_anchors ~= true then return end
		anchors.fill = {
			topleft = { x = x1, y = y2 - fill_height },
			bottomleft = { x = x1, y = y2 },
			topright = { x = x2, y = y2 - fill_height },
			bottomright = { x = x2, y = y2 },
			center = { x = (x1 + x2) / 2, y = y2 - fill_height / 2 },
		}
	elseif fill_direction == "top-down" then
		-- Fill top to bottom
		local bar_height = y2 - y1
		local fill_height = percent * bar_height
		dx9.DrawFilledBox(
			{ x1, y1 },
			{ x2, y1 + fill_height },
			bar_color
		)
		if return_anchors ~= true then return end
		anchors.fill = {
			topleft = { x = x1, y = y1 },
			bottomleft = { x = x1, y = y1 + fill_height },
			topright = { x = x2, y = y1 },
			bottomright = { x = x2, y = y1 + fill_height },
			center = { x = (x1 + x2) / 2, y = y1 + fill_height / 2 },
		}
	elseif fill_direction == "center-vertical" then
		-- Fill from center outwards vertically
		local bar_height = y2 - y1
		local fill_height = percent * bar_height / 2
		local center_y = (y1 + y2) / 2
		dx9.DrawFilledBox(
			{ x1, center_y - fill_height },
			{ x2, center_y + fill_height },
			bar_color
		)
		if return_anchors ~= true then return end
		anchors.fill = {
			topleft = { x = x1, y = center_y - fill_height },
			bottomleft = { x = x1, y = center_y + fill_height },
			topright = { x = x2, y = center_y - fill_height },
			bottomright = { x = x2, y = center_y + fill_height },
			center = { x = (x1 + x2) / 2, y = center_y },
		}
	elseif fill_direction == "center-horizontal" then
		-- Fill from center outwards horizontally
		local bar_len = x2 - x1
		local fill_len = percent * bar_len / 2
		local center_x = (x1 + x2) / 2
		dx9.DrawFilledBox(
			{ center_x - fill_len, y1 },
			{ center_x + fill_len, y2 },
			bar_color
		)
		if return_anchors ~= true then return end
		anchors.fill = {
			topleft = { x = center_x - fill_len, y = y1 },
			bottomleft = { x = center_x - fill_len, y = y2 },
			topright = { x = center_x + fill_len, y = y1 },
			bottomright = { x = center_x + fill_len, y = y2 },
			center = { x = center_x, y = (y1 + y2) / 2 },
		}
	end
	if return_anchors ~= true then return end
	anchors.bounding_box = {
		topleft = { x = x1, y = y1 },
		topright = { x = x2, y = y1 },
		bottomleft = { x = x1, y = y2 },
		bottomright = { x = x2, y = y2 },
		center = { x = (x1 + x2) / 2, y = (y1 + y2) / 2 },
	}
	return anchors
end

-- Draw a 2D corner box (just corners, not full box) and return anchors
function esp.draw_box_2d_corners_anchored(topleft, bottomright, color, thickness, corner_len, return_anchors)
	-- Draws only the corners of a 2D box
	color = color or {255,255,255}
	thickness = thickness or 1
	corner_len = corner_len or math.min((bottomright.x-topleft.x), (bottomright.y-topleft.y)) * 0.25
	local x1, y1 = topleft.x, topleft.y
	local x2, y2 = bottomright.x, bottomright.y
	-- Top left
	dx9.DrawLine({x1, y1}, {x1 + corner_len, y1}, color, thickness)
	dx9.DrawLine({x1, y1}, {x1, y1 + corner_len}, color, thickness)
	-- Top right
	dx9.DrawLine({x2, y1}, {x2 - corner_len, y1}, color, thickness)
	dx9.DrawLine({x2, y1}, {x2, y1 + corner_len}, color, thickness)
	-- Bottom left
	dx9.DrawLine({x1, y2}, {x1 + corner_len, y2}, color, thickness)
	dx9.DrawLine({x1, y2}, {x1, y2 - corner_len}, color, thickness)
	-- Bottom right
	dx9.DrawLine({x2, y2}, {x2 - corner_len, y2}, color, thickness)
	dx9.DrawLine({x2, y2}, {x2, y2 - corner_len}, color, thickness)
	if return_anchors ~= true then return end
	local anchors = {
		center      = { x = (x1 + x2) / 2, y = (y1 + y2) / 2 },
		topleft     = { x = x1, y = y1 },
		topright    = { x = x2, y = y1 },
		bottomleft  = { x = x1, y = y2 },
		bottomright = { x = x2, y = y2 },
		top         = { x = (x1 + x2) / 2, y = y1 },
		bottom      = { x = (x1 + x2) / 2, y = y2 },
		left        = { x = x1, y = (y1 + y2) / 2 },
		right       = { x = x2, y = (y1 + y2) / 2 },
	}
	return anchors
end

-- Draw a 3D corner box (just corners, not full box) and return anchors
function esp.draw_box_3d_corners_anchored(cframe, size, color, thickness, corner_len, return_anchors)
	-- cframe: table with .Position, .RightVector, .UpVector, .LookVector
	-- size: {x, y, z} (half extents)
	-- Draws only the corners of a 3D box
	color = color or {255,255,255}
	thickness = thickness or 1
	corner_len = corner_len or math.min(size[1], size[2], size[3]) * 0.5
	local r = cframe.RightVector
	local u = cframe.UpVector
	local l = cframe.LookVector
	local pos = cframe.Position
	-- 8 corners in local space
	local corners = {
		{ 1, 1, 1 }, { -1, 1, 1 }, { -1, -1, 1 }, { 1, -1, 1 },
		{ 1, 1, -1 }, { -1, 1, -1 }, { -1, -1, -1 }, { 1, -1, -1 }
	}
	local world = {}
	for i, c in ipairs(corners) do
		world[i] = {
			x = pos.x + r.x * size[1] * c[1] + u.x * size[2] * c[2] + l.x * size[3] * c[3],
			y = pos.y + r.y * size[1] * c[1] + u.y * size[2] * c[2] + l.y * size[3] * c[3],
			z = pos.z + r.z * size[1] * c[1] + u.z * size[2] * c[2] + l.z * size[3] * c[3],
		}
	end
	-- Draw corner lines for each corner
	local function draw_corner_lines(idx, dx, dy, dz)
		local p = world[idx]
		local px, py, pz = p.x, p.y, p.z
		local function to_screen(x, y, z)
			return dx9.WorldToScreen({x, y, z})
		end
		-- X axis
		local sx1 = to_screen(px, py, pz)
		local sx2 = to_screen(px + dx, py, pz)
		if sx1 and sx2 and sx1.x and sx2.x then dx9.DrawLine({sx1.x, sx1.y}, {sx2.x, sx2.y}, color, thickness) end
		-- Y axis
		local sy2 = to_screen(px, py + dy, pz)
		if sx1 and sy2 and sx1.x and sy2.x then dx9.DrawLine({sx1.x, sx1.y}, {sy2.x, sy2.y}, color, thickness) end
		-- Z axis
		local sz2 = to_screen(px, py, pz + dz)
		if sx1 and sz2 and sx1.x and sz2.x then dx9.DrawLine({sx1.x, sx1.y}, {sz2.x, sz2.y}, color, thickness) end
	end
	-- For each corner, draw 3 lines (along +X, +Y, +Z directions)
	local dx = corner_len * r.x
	local dy = corner_len * u.y
	local dz = corner_len * l.z
	draw_corner_lines(1,  corner_len, 0, 0)
	draw_corner_lines(1, 0,  corner_len, 0)
	draw_corner_lines(1, 0, 0,  corner_len)
	draw_corner_lines(2, -corner_len, 0, 0)
	draw_corner_lines(2, 0,  corner_len, 0)
	draw_corner_lines(2, 0, 0,  corner_len)
	draw_corner_lines(3, -corner_len, 0, 0)
	draw_corner_lines(3, 0, -corner_len, 0)
	draw_corner_lines(3, 0, 0,  corner_len)
	draw_corner_lines(4,  corner_len, 0, 0)
	draw_corner_lines(4, 0, -corner_len, 0)
	draw_corner_lines(4, 0, 0,  corner_len)
	draw_corner_lines(5,  corner_len, 0, 0)
	draw_corner_lines(5, 0,  corner_len, 0)
	draw_corner_lines(5, 0, 0, -corner_len)
	draw_corner_lines(6, -corner_len, 0, 0)
	draw_corner_lines(6, 0,  corner_len, 0)
	draw_corner_lines(6, 0, 0, -corner_len)
	draw_corner_lines(7, -corner_len, 0, 0)
	draw_corner_lines(7, 0, -corner_len, 0)
	draw_corner_lines(7, 0, 0, -corner_len)
	draw_corner_lines(8,  corner_len, 0, 0)
	draw_corner_lines(8, 0, -corner_len, 0)
	draw_corner_lines(8, 0, 0, -corner_len)
	if return_anchors ~= true then return end
	-- Project all corners to screen
	local anchors2d = {}
	for i, p in ipairs(world) do
		local s = dx9.WorldToScreen({p.x, p.y, p.z})
		if s and s.x and s.y then anchors2d[i] = { x = s.x, y = s.y } end
	end
	if #anchors2d > 0 then
		local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
		for _, pt in pairs(anchors2d) do
			if pt.x < minx then minx = pt.x end
			if pt.y < miny then miny = pt.y end
			if pt.x > maxx then maxx = pt.x end
			if pt.y > maxy then maxy = pt.y end
		end
		anchors2d.center = { x = (minx + maxx) / 2, y = (miny + maxy) / 2 }
		anchors2d.topleft = { x = minx, y = miny }
		anchors2d.topright = { x = maxx, y = miny }
		anchors2d.bottomleft = { x = minx, y = maxy }
		anchors2d.bottomright = { x = maxx, y = maxy }
		anchors2d.top = { x = (minx + maxx) / 2, y = miny }
		anchors2d.bottom = { x = (minx + maxx) / 2, y = maxy }
		anchors2d.left = { x = minx, y = (miny + maxy) / 2 }
		anchors2d.right = { x = maxx, y = (miny + maxy) / 2 }
	end
	return anchors2d
end

return esp