local AH = wesnoth.require "ai/lua/ai_helper.lua"

local function wf_get_guardian(cfg)
    local filter = wml.get_child(cfg, "filter") or { id = cfg.id }
    local guardian = AH.get_units_with_moves {
        side = wesnoth.current.side,
        { "and", filter }
    }[1]
    return guardian
end

local ca_wf_loiter_guardian = {}

function ca_wf_loiter_guardian:evaluation(cfg)
    if wf_get_guardian(cfg) then return cfg.ca_score end
    return 0
end

function ca_wf_loiter_guardian:execution(cfg)
    local guardian = wf_get_guardian(cfg)

    if (guardian.moves > 0) and (not cfg.stationary) then
            local zone = wml.get_child(cfg, "filter_location")
            local width, height = wesnoth.get_map_size()
            local locs_map = LS.of_pairs(wesnoth.get_locations {
                x = '1-' .. width,
                y = '1-' .. height,
                { "and", zone }
            })

            -- Check out which of those hexes the guardian can reach
            local reach_map = LS.of_pairs(wesnoth.find_reach(guardian))
            reach_map:inter(locs_map)

            -- If it can reach some hexes, use only reachable locations,
            -- otherwise move toward any (random) one from the entire set
            if (reach_map:size() > 0) then
                locs_map = reach_map
            end

            local locs = locs_map:to_pairs()

            if (#locs > 0) then
                local newind = math.random(#locs)
                newpos = { locs[newind][1], locs[newind][2] }
            else
                newpos = { guardian.x, guardian.y }
            end
        end

        -- Next hop toward that position
        local nh = AH.next_hop(guardian, newpos[1], newpos[2])
        if nh then
            AH.movefull_stopunit(ai, guardian, nh)
        end
    end
    if (not guardian) or (not guardian.valid) then return end

    AH.checked_stopunit_moves(ai, guardian)
    -- If there are attacks left and guardian ended up next to an enemy, we'll leave this to RCA AI
end

return ca_wf_loiter_guardian
