local AH = wesnoth.require "ai/lua/ai_helper.lua"

local function wf_get_guardian(cfg)
    local filter = wml.get_child(cfg, "filter") or { id = cfg.id }
    local guardian = AH.get_units_with_moves {
        side = wesnoth.current.side,
        { "and", filter }
    }[1]

    return guardian
end

local function wf_get_target(cfg)
    local target = wesnoth.get_units {
        { "filter_side", { { "enemy_of", { side = wesnoth.current.side } } } },
        { "and", wml.get_child(cfg, "filter_second") }
    }[1]

    return target
end
local ca_wf_curse_guardian = {}

function ca_wf_curse_guardian:evaluation(cfg)
    local guardian = wf_get_guardian(cfg)
    if (not guardian) then return 0 end

    local target = wf_get_target(cfg)
    if (not target) then return 0 end

    return cfg.ca_score
end

function ca_wf_curse_guardian:execution(cfg)
    local guardian = wf_get_guardian(cfg)
    local target = wf_get_target(cfg)

    -- In case the return hex is occupied:
    local x, y = target.x, target.y 
    if (guardian.x ~= x) or (guardian.y ~= y) then
        x, y = wesnoth.find_vacant_tile(x, y, guardian)
    end

    local nh = AH.next_hop(guardian, x, y)
    if (not nh) then nh = { guardian.x, guardian.y } end

    AH.movefull_stopunit(ai, guardian, nh)
end

return ca_wf_curse_guardian
