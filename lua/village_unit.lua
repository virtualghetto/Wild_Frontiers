-- Lifed from: campaigns/The_Hammer_of_Thursagan/lua/spawns.lua
local helper = wesnoth.require "lua/helper.lua"
local utils = wesnoth.require "lua/wml-utils.lua"
local wml_actions = wesnoth.wml_actions
local T = wml.tag

function wml_actions.village_unit(cfg)
        local done = 0
-- if wesnoth version >= 1.15.0
if wesnoth.compare_versions(wesnoth.game_config.version, ">=", "1.15.0") then

        local x = cfg.x or wml.error("[village_unit] missing required x= attribute.")
        local y = cfg.y or wml.error("[village_unit] missing required y= attribute.")
        local types = cfg.types or wml.error("[village_unit] missing required types= attribute.")
        local count = cfg.count or wml.error("[village_unit] missing required count= attribute.")
        local side = cfg.side or wml.error("[village_unit] missing required side= attribute.")

        for i=1,count do
                local locs = wesnoth.map.find({T["not"] { T.filter {} } , T["and"] { terrain = '!,*^V*,W*^*,M*^*,Q*^*,X*^*,*^Q*,*^X*,*^P*' } , T["and"] { x = x, y = y, radius = 1 } , include_borders = false })
                if #locs == 0 then locs = wesnoth.map.find({T["not"] { T.filter {} } , T["and"] { terrain = '!,*^V*,W*^*,M*^*,Q*^*,X*^*,*^Q*,*^X*,*^P*' } , T["and"] { x = x, y = y, radius = 2 } , include_borders = false }) end
                if #locs == 0 then break end

                done = done + 1

                local unit_type = mathx.random_choice(types)
                local loc_i = mathx.random_choice("1.."..#locs)

                wml_actions.move_unit_fake({x = string.format("%d,%d", x, locs[loc_i][1]) , y = string.format("%d,%d", y, locs[loc_i][2]) , type = unit_type , side = side})
                wesnoth.units.to_map({ type = unit_type , side = side, random_traits = "yes", generate_name = "yes" , role = "village_unit" }, locs[loc_i][1], locs[loc_i][2])
        end


-- else wesnoth version < 1.15.0
else

	local x = cfg.x or helper.wml_error("[village_unit] missing required x= attribute.")
	local y = cfg.y or helper.wml_error("[village_unit] missing required y= attribute.")
	local types = cfg.types or helper.wml_error("[village_unit] missing required types= attribute.")
	local count = cfg.count or helper.wml_error("[village_unit] missing required count= attribute.")
	local side = cfg.side or helper.wml_error("[village_unit] missing required side= attribute.")

	for i=1,count do
		local locs = wesnoth.get_locations({T["not"] { T.filter {} } , T["and"] { terrain = '!,*^V*,W*^*,M*^*,Q*^*,X*^*,*^Q*,*^X*,*^P*' } , T["and"] { x = x, y = y, radius = 1} , include_borders = false })
		if #locs == 0 then locs = wesnoth.get_locations({T["not"] { T.filter {} } , T["and"] { terrain = '!,*^V*,W*^*,M*^*,Q*^*,X*^*,*^Q*,*^X*,*^P*' } , T["and"] { x = x, y = y, radius = 2 } , include_borders = false  }) end
		if #locs == 0 then break end

		done = done + 1

		local unit_type = helper.rand(types)
		local loc_i = helper.rand("1.."..#locs)

		wml_actions.move_unit_fake({x = string.format("%d,%d", x, locs[loc_i][1]) , y = string.format("%d,%d", y, locs[loc_i][2]) , type = unit_type , side = side})
		wesnoth.put_unit({ type = unit_type , side = side, random_traits = "yes", generate_name = "yes" , role = "village_unit" }, locs[loc_i][1], locs[loc_i][2])
	end
-- end wesnoth version
end

	if done > 0 then
		for then_child in wml.child_range(cfg, "then") do
			local action = utils.handle_event_commands(then_child, "conditional")
			if action ~= "none" then return end
		end
	end
end
