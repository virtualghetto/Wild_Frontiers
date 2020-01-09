--[[
These code snippets are modified versions of code by silene and melinath on the
Wesnoth forums.  I do not know Lua, so several features of this campaign would
not have been possible without the helpful posts of these fine individuals!

http://forums.wesnoth.org/viewtopic.php?f=21&t=27450
http://forums.wesnoth.org/viewtopic.php?t=28306&p=414894
--]]

-- Save and load the map using a WML variable
local helper = wesnoth.require "lua/helper.lua"

local function save_map(cfg)
  local b = cfg.border_size or 1
  local w, h = wesnoth.get_map_size()
  local t = {}
  for y = 1 - b, h + b do
    local r = {}
    for x = 1 - b, w + b do r[x + b] = wesnoth.get_terrain(x, y) end
    t[y + b] = table.concat(r, ',')
  end
  local s = table.concat(t, '\n')
  local v = cfg.variable or helper.wml_error "save_map missing required variable= attribute."
  wesnoth.set_variable(v, string.format("border_size=%d\nusage=map\n\n%s", b, s))
end
wesnoth.wml_actions["save_map"] = save_map


local function load_map(cfg)
  local v = cfg.variable or helper.wml_error "load_map missing required variable= attribute."
  wesnoth.fire("replace_map", { map = wesnoth.get_variable(v), expand = true, shrink = true })
end
wesnoth.wml_actions["load_map"] = load_map



-- Save and load the shroud using a WML variable
local function store_shroud(args)
   local team_num = args.side or error("~wml:[store_shroud] expects a side= attribute.",0)
   local storage = args.variable or error("~wml:[store_shroud] expects a variable= attribute.",0)
   local team = wesnoth.sides[team_num]
   local current_shroud = team.__cfg.shroud_data
   wesnoth.set_variable(storage,current_shroud)
end
wesnoth.wml_actions["store_shroud"] = store_shroud


local helper = wesnoth.require "lua/helper.lua"
local function set_shroud(args)
   local team_num = tonumber(args.side) or helper.wml_error "[store_shroud] expects a side= attribute."
   local shroud = args.shroud_data or helper.wml_error "[store_shroud] expects a shroud_data= attribute."
   if string.sub(shroud,1,1) ~= "|" then
      helper.wml_error "[set_shroud] was passed an invalid shroud string."
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
wesnoth.wml_actions["set_shroud"] = set_shroud