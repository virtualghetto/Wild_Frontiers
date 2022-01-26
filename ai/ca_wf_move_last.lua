local utils = wesnoth.require "wml-utils"
local AH = wesnoth.require "ai/lua/ai_helper.lua"
local MAIUV = wesnoth.require "ai/micro_ais/micro_ai_unit_variables.lua"

local function get_last_unit(cfg)
	local filter = wml.get_child(cfg, "filter") or { id = cfg.id }
	local all_units = AH.get_units_with_moves {
		side = wesnoth.current.side,
		{ "and", filter }
	}

	local units = {}
	for _,unit in ipairs(all_units) do
            if not MAIUV.get_mai_unit_variables(unit, cfg.ai_id, "frozen") then
                table.insert(units, unit)
            end
        end

	return units[1]
end

local function get_last_unit_frozen(cfg)
	local filter = wml.get_child(cfg, "filter") or { id = cfg.id }
	local all_units = wesnoth.get_units {
		side = wesnoth.current.side,
		{ "and", filter }
	}

	local units = {}
	for _,unit in ipairs(all_units) do
            if MAIUV.get_mai_unit_variables(unit, cfg.ai_id, "frozen") then
                table.insert(units, unit)
            end
        end

	return units[1]
end

local function get_other_unit(cfg)
	local filter = wml.get_child(cfg, "filter") or { id = cfg.id }
	local other_unit = AH.get_units_with_moves {
		side = wesnoth.current.side,
		{ "not", filter }
	}[1]

	return other_unit
end

local ca_wf_move_last = {}

-- params for eval_parms (ai, cfg, self)
function ca_wf_move_last:evaluation(cfg, data, filter_own)
	local score = cfg.ca_score or 300000

	local other_unit = get_other_unit(cfg)

	if other_unit then
		local last_unit = get_last_unit(cfg)
		if last_unit then
			return score
		end
	else
		local last_unit_frozen = get_last_unit_frozen(cfg)
		if last_unit_frozen then
			return score
		end
	end

	return 0
end

-- params for exec_parms (ai, cfg, self)
function ca_wf_move_last:execution(cfg, data, filter_own)

	local other_unit = get_other_unit(cfg)
	local last_unit = nil

	if other_unit then
		last_unit = get_last_unit(cfg)
		while last_unit do
			local is_resting = false
			local last_x = MAIUV.get_mai_unit_variables(last_unit, cfg.ai_id, "last_x" ) or 0
			local last_y = MAIUV.get_mai_unit_variables(last_unit, cfg.ai_id, "last_y" ) or 0
			if last_x == 0 and last_y == 0 then
				-- they start off false always.
				is_resting = false
			else
				if last_unit.x == last_x and last_unit.y == last_y then
					is_resting = true
				else
					is_resting = false
				end
			end
			if last_unit.attacks_left == 0 then
				is_resting = false
			end
			MAIUV.delete_mai_unit_variables(last_unit, cfg.ai_id)
			MAIUV.set_mai_unit_variables(last_unit, cfg.ai_id, { frozen = true, moves = last_unit.moves, attacks_left = last_unit.attacks_left, resting = is_resting, last_x = last_unit.x, last_y = last_unit.y })
			--ai.stopunit_moves(last_unit)
			AH.checked_stopunit_all(ai, last_unit)
			last_unit = nil
			--last_unit = get_last_unit(cfg)
		end
		return
	end

	last_unit = get_last_unit_frozen(cfg)
	while last_unit do
		local cfg_reset_moves = { id = last_unit.id,
			moves = MAIUV.get_mai_unit_variables(last_unit, cfg.ai_id, "moves" ),
			resting = MAIUV.get_mai_unit_variables(last_unit, cfg.ai_id, "resting" ),
			attacks_left = MAIUV.get_mai_unit_variables(last_unit, cfg.ai_id, "attacks_left" ),
		}
		wesnoth.invoke_synced_command('reset_moves', cfg_reset_moves)
		MAIUV.delete_mai_unit_variables(last_unit, cfg.ai_id)
		MAIUV.set_mai_unit_variables(last_unit, cfg.ai_id, { last_x = last_unit.x, last_y = last_unit.y })
		last_unit = nil
		--last_unit = get_last_unit_frozen(cfg)
	end
	utils.force_gamestate_change(ai)
end

return ca_wf_move_last
