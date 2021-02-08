--[[
These code snippets are modified versions of code by silene and melinath on the
Wesnoth forums.  I do not know Lua, so several features of this campaign would
not have been possible without the helpful posts of these fine individuals!

http://forums.wesnoth.org/viewtopic.php?f=21&t=27450
http://forums.wesnoth.org/viewtopic.php?t=28306&p=414894
--]]

-- Save and load the map using a WML variable
local helper = wesnoth.require "lua/helper.lua"

function wesnoth.wml_actions.save_map(cfg)
  local v = cfg.variable or helper.wml_error("save_map missing required variable= attribute.")
  local b = cfg.border_size or 1
  local w, h = wesnoth.get_map_size()
  local t = {}
  for y = 1 - b, h + b do
    local r = {}
    for x = 1 - b, w + b do r[x + b] = wesnoth.get_terrain(x, y) end
    t[y + b] = table.concat(r, ',')
  end
  local s = table.concat(t, '\n')
  -- Remove side locations
  s = string.gsub(s, "%s*%d+%s*", "")
  -- Set side 1 keep location
  s = string.gsub(s, "K(%a+)^Yk", "1 K%1^Yk")
  wesnoth.set_variable(v, string.format("border_size=%d\nusage=map\n\n%s", b, s))
end


function wesnoth.wml_actions.load_map(cfg)
  local v = cfg.variable or helper.wml_error("load_map missing required variable= attribute.")
  wesnoth.fire("replace_map", { map = wesnoth.get_variable(v), expand = true, shrink = true })
end



-- Save and load the shroud using a WML variable
function wesnoth.wml_actions.store_shroud(args)
   local team_num = args.side or helper.wml_error("~wml:[store_shroud] expects a side= attribute.")
   local storage = args.variable or helper.wml_error("~wml:[store_shroud] expects a variable= attribute.")
   local team = wesnoth.sides[team_num]
   local current_shroud = team.__cfg.shroud_data
   wesnoth.set_variable(storage,current_shroud)
end


function wesnoth.wml_actions.set_shroud(args)
   local team_num = tonumber(args.side) or helper.wml_error("[store_shroud] expects a side= attribute.")
   local shroud = args.shroud_data or helper.wml_error("[store_shroud] expects a shroud_data= attribute.")
   if string.sub(shroud,1,1) ~= "|" then
      helper.wml_error("[set_shroud] was passed an invalid shroud string.")
   else
      local w,h,b = wesnoth.get_map_size()
      local shroud_x = 1 - b
      for r in string.gmatch(shroud, "|(%d*)") do
         local shroud_y = 1 - b
         for c in string.gmatch(r, "%d") do
            if c == "1" then
               wesnoth.fire("remove_shroud", { side=team_num, x=shroud_x, y=shroud_y })
            end
            shroud_y = shroud_y + 1
         end
         shroud_x = shroud_x + 1
      end
   end
end

function wesnoth.wml_actions.deselect()
  wesnoth.delay(600)
  wesnoth.select_unit(nil, true)
  wesnoth.deselect_hex()
  wesnoth.fire("redraw")
--  wesnoth.wml_actions.redraw {}
end

local LS = wesnoth.require "location_set"

local function on_board(x, y)
        if type(x) ~= "number" or type(y) ~= "number" then
                return false
        end
        local w, h = wesnoth.get_map_size()
        return x >= 1 and y >= 1 and x <= w and y <= h
end

local function insert_locs(x, y, locs_set)
	if locs_set:get(x,y) or not on_board(x, y) then
		return
	end
	locs_set:insert(x,y)
end

local function place_road(to_x, to_y, from_x, from_y, road_ops)
	if not on_board(to_x, to_y) then
		return
	end

	local tile_op = road_ops[wesnoth.get_terrain(to_x, to_y)]
	if tile_op then
		if tile_op.convert_to_bridge and from_x and from_y then
			local bridges = {}
			for elem in tile_op.convert_to_bridge:gmatch("[^%s,][^,]*") do
				table.insert(bridges, elem)
			end
			local dir = wesnoth.map.get_relative_dir(from_x, from_y, to_x, to_y)
			if dir == 'n' or dir == 's' then
				wesnoth.set_terrain(to_x, to_y, bridges[1])
			elseif dir == 'sw' or dir == 'ne' then
				wesnoth.set_terrain(to_x, to_y, bridges[2])
			elseif dir == 'se' or dir == 'nw' then
				wesnoth.set_terrain(to_x, to_y, bridges[3])
			end
		elseif tile_op.convert_to then
			local tile = helper.rand(tile_op.convert_to)
			wesnoth.set_terrain(to_x, to_y, tile)
		end
	end
end

function wesnoth.wml_actions.road_path(cfg)
	local from_x = tonumber(cfg.from_x) or helper.wml_error("[road_path] expects a from_x= attribute.")
	local from_y = tonumber(cfg.from_y) or helper.wml_error("[road_path] expects a from_y= attribute.")
	local to_x = tonumber(cfg.to_x) or helper.wml_error("[road_path] expects a to_x= attribute.")
	local to_y = tonumber(cfg.to_y) or helper.wml_error("[road_path] expects a to_y= attribute.")
	if not on_board(from_x, from_y) then
		return
	end

	if not on_board(to_x, to_y) then
		return
	end

	local windiness = tonumber(cfg.road_windiness) or 1

	local road_costs, road_ops = {}, {}
	for road in helper.child_range(cfg, "road_cost") do
		road_costs[road.terrain] = road.cost
		road_ops[road.terrain] = road
	end

	local path, cost

-- if wesnoth version >= 1.15.0
if wesnoth.compare_versions(wesnoth.game_config.version, ">=", "1.15.0") then


	path, cost = wesnoth.find_path(from_x, from_y, to_x, to_y, {
		viewing_side = 1, ignore_units = true, ignore_teleport = true,
		calculate = function(x, y, current_cost)
			local tile = wesnoth.get_terrain(x, y)
			local res = road_costs[tile] or 1.0
			if windiness > 1 then
				res = res * wesnoth.random(windiness)
			end
			return res
		end })


-- else wesnoth version < 1.15.0
else


	path, cost = wesnoth.find_path(from_x, from_y, to_x, to_y,
		function(x, y, current_cost)
			local tile = wesnoth.get_terrain(x, y)
			local res = road_costs[tile] or 1.0
			if windiness > 1 then
				res = res * wesnoth.random(windiness)
			end
			return res
		end )



end
-- end wesnoth version



	local prev_x, prev_y
	for i, loc in ipairs(path) do
		local locs_set = LS.create()
		insert_locs(loc[1], loc[2], locs_set)
		for x,y in locs_set:stable_iter() do
			place_road(x, y, prev_x, prev_y, road_ops)
			prev_x, prev_y = x, y
		end
	end
end

local utils = wesnoth.require "wml-utils"

function wesnoth.wml_actions.store_nearest_locations(cfg)
	local src_x = tonumber(cfg.x) or helper.wml_error("[store_nearest_locations] expects a x= attribute.")
	local src_y = tonumber(cfg.y) or helper.wml_error("[store_nearest_locations] expects a y= attribute.")
	local src_r = tonumber(cfg.radius) or helper.wml_error("[store_nearest_locations] expects a radius= attribute.")
	local filter_location = wml.get_child(cfg, "filter_location") or helper.wml_error("[store_nearest_locations] missing required [filter_location] tag")

	if not on_board(src_x, src_y) then
		return
	end

	if src_r < 0 then
		return
	end

	local distance = 0
	local distance_set = false

	-- the variable can be mentioned in a [find_in] subtag, so it
	-- cannot be cleared before the locations are recovered
	local writer = utils.vwriter.init(cfg, "location")

	local locs = LS.create()
	for i = 1, 65536 do
		locs = wesnoth.get_locations({
				{ "and", { x = src_x, y = src_y, radius = distance } },
				{ "and", filter_location }
			})

		if #locs > 0 then
			distance_set = true
			break
		end

		distance = distance + 1
		if distance > src_r then
			break
		end
	end

	if distance_set then
		wml.variables["nearest_radius"] = distance
	end

	for i, loc in ipairs(locs) do
		local x, y = loc[1], loc[2]
		local t = wesnoth.get_terrain(x, y)
		local res = { x = x, y = y, terrain = t }
		if wesnoth.get_terrain_info(t).village then
			res.owner_side = wesnoth.get_village_owner(x, y) or 0
		end
		utils.vwriter.write(writer, res)
	end
end

--[[
function wesnoth.effects.canrecruit(u, cfg)
	-- u.canrecruit = true
	-- helper.modify_unit({ id=u.id }, { canrecruit=yes })
	-- wesnoth.units.modify({ id=u.id }, { canrecruit=yes })
	wesnoth.add_modification(u, "object", { wml.tag.effect {
		apply_to = "status",
		add = "canrecruit",
	}}, false)
end
--]]
