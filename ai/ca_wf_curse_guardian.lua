local AH = wesnoth.require "ai/lua/ai_helper.lua"
local H = wesnoth.require "helper"
local M = wesnoth.map

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
    local enemy = wf_get_target(cfg)
    local reach = wesnoth.find_reach(guardian)

        local min_dist, target = 9e99
            local dist = M.distance_between(guardian.x, guardian.y, enemy.x, enemy.y)
            if (dist < min_dist) then
                target, min_dist = enemy, dist
            end

        -- If a valid target was found, guardian attacks this target, or moves toward it
        if target then
            -- Find tiles adjacent to the target
            -- Save the one with the highest defense rating that guardian can reach
            local best_defense, attack_loc = -9e99
            for xa,ya in H.adjacent_tiles(target.x, target.y) do
                -- Only consider unoccupied hexes
                local unit_in_way = wesnoth.get_unit(xa, ya)
                if (not AH.is_visible_unit(wesnoth.current.side, unit_in_way))
                    or (unit_in_way == guardian)
                then
                    local defense = 100 - wesnoth.unit_defense(guardian, wesnoth.get_terrain(xa, ya))
                    local nh = AH.next_hop(guardian, xa, ya)
                    if nh then
                        if (nh[1] == xa) and (nh[2] == ya) and (defense > best_defense) then
                            best_defense, attack_loc = defense, { xa, ya }
                        end
                    end
                end
            end

            -- If a valid hex was found: move there and attack
            if attack_loc then
                AH.robust_move_and_attack(ai, guardian, attack_loc, target)
            else  -- Otherwise move toward that enemy
                local reach = wesnoth.find_reach(guardian)

                -- Go through all hexes the guardian can reach, find closest to target
                -- Cannot use next_hop here since target hex is occupied by enemy
                local min_dist, nh = 9e99
                for _,hex in ipairs(reach) do
                    -- Only consider unoccupied hexes
                    local unit_in_way = wesnoth.get_unit(hex[1], hex[2])
                    if (not AH.is_visible_unit(wesnoth.current.side, unit_in_way))
                        or (unit_in_way == guardian)
                    then
                        local dist = M.distance_between(hex[1], hex[2], target.x, target.y)
                        if (dist < min_dist) then
                            min_dist, nh = dist, { hex[1], hex[2] }
                        end
                    end
                end

                AH.movefull_stopunit(ai, guardian, nh)
            end
        end

    if (not guardian) or (not guardian.valid) then return end

    AH.checked_stopunit_moves(ai, guardian)
    -- If there are attacks left and guardian ended up next to an enemy, we'll leave this to RCA AI
end

return ca_wf_curse_guardian
