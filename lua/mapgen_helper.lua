local LS = wesnoth.require "location_set"
local helper = wesnoth.require "helper"

local mapgen_helper, map_mt = {}, {__index = {}}

function mapgen_helper.create_map(width,height,default_terrain)
	local map = setmetatable({w = width, h = height}, map_mt)
	for i = 1, width * height do
		table.insert(map, default_terrain or 'Gg')
	end
	return map
end

local function comma_split(x_list,y_list)
	-- Force convert them to strings
	x_list = tostring(x_list)
	y_list = tostring(y_list)

	local t = {}

	local xi = 0
	for v in x_list:gmatch('[^,%s]+') do
	        xi = xi + 1
	end

	local yi = 0
	for v in y_list:gmatch('[^,%s]+') do
	        yi = yi + 1
	end

	local min_xy = math.min(xi, yi)

	local i = 1
	for v in x_list:gmatch('[^,%s]+') do
		if i > min_xy then
			break
		end
		t[i] = {}
		t[i][1] = v
	        i = i + 1
	end
	local i = 1
	for v in y_list:gmatch('[^,%s]+') do
		if i > min_xy then
			break
		end
		t[i][2] = v
	        i = i + 1
	end
	return table.unpack(t[wesnoth.random(1,#t)])
end

function mapgen_helper.random_location(x_list, y_list)
	x_list, y_list = comma_split(x_list, y_list)
	local x, y
	if type(x_list) == "number" then
		x = x_list
	elseif type(x_list) == "string" then
		local hyphen = x_list:find('-')
		if hyphen then
			x_list = x_list:sub(1, hyphen - 1) .. '..' .. x_list:sub(hyphen + 1)
		end
		x = tonumber(helper.rand(x_list))
	end
	if type(y_list) == "number" then
		y = y_list
	elseif type(y_list) == "string" then
		local hyphen = y_list:find('-')
		if hyphen then
			y_list = y_list:sub(1, hyphen - 1) .. '..' .. y_list:sub(hyphen + 1)
		end
		y = tonumber(helper.rand(y_list))
	end
	return x or 0, y or 0
end

local valid_transforms = {
	flip_x = true,
	flip_y = true,
	flip_xy = true,
}

function mapgen_helper.is_valid_transform(t)
	return valid_transforms[t]
end

local function loc_to_index(map,x,y)
	return x + 1 + y * map.w
end

function map_mt.__index.set_tile(map, x, y, val)
	map[loc_to_index(map, x, y)] = val
end

function map_mt.__index.get_tile(map, x, y)
	return map[loc_to_index(map,x,y)]
end

function map_mt.__index.on_board(map, x, y)
	return x >= 0 and y >= 0 and x < map.w and y < map.h
end

function map_mt.__index.on_inner_board(map, x, y)
	return x >= 1 and y >= 1 and x < map.w - 1 and y < map.h -  1
end

function map_mt.__index.add_location(map, x, y, name)
	if not map.locations then
		map.locations = LS.create()
	end
	if map.locations:get(x, y) then
		table.insert(map.locations:get(x, y), name)
	else
		map.locations:insert(x, y, {name})
	end
end

function map_mt.__index.flip_x(map)
	for y = 0, map.h - 1 do
		for x = 0, map.w - 1 do
			local i = loc_to_index(map, x, y)
			local j = loc_to_index(map, map.w - x - 1, y)
			map[i], map[j] = map[j], map[i]
		end
	end
end

function map_mt.__index.flip_y(map)
	for x = 0, map.w - 1 do
		for y = 0, map.h - 1 do
			local i = loc_to_index(map, x, y)
			local j = loc_to_index(map, x, map.h - y - 1)
			map[i], map[j] = map[j], map[i]
		end
	end
end

function map_mt.__index.flip_xy(map)
	map:flip_x()
	map:flip_y()
end

function map_mt.__tostring(map)
	local map_builder = {}
	-- The coordinates are 0-based to match the in-game coordinates
	for y = 0, map.h - 1 do
		local string_builder = {}
		for x = 0, map.w - 1 do
			local tile_string = map:get_tile(x, y) or 'Xv'
			if map.locations and map.locations:get(x,y) then
				for i,v in ipairs(map.locations:get(x,y)) do
					tile_string = v .. ' ' .. tile_string
				end
			end
			table.insert(string_builder, tile_string)
		end
		assert(#string_builder == map.w)
		table.insert(map_builder, table.concat(string_builder, ', '))
	end
	assert(#map_builder == map.h)
	return table.concat(map_builder, '\n')
end

local adjacent_offset = {
	{ {0,-1}, {1,-1}, {1,0}, {0,1}, {-1,0}, {-1,-1} },
	{ {0,-1}, {1,0}, {1,1}, {0,1}, {-1,1}, {-1,0} }
}
function mapgen_helper.adjacent_tiles(x, y)
	local offset = adjacent_offset[2 - (x % 2)]
	local i = 0
	return function()
		i = i + 1
		if i <= 6 then
			return offset[i][1] + x, offset[i][2] + y
		else
			return nil
		end
	end
end

return mapgen_helper
