local AH = wesnoth.require "ai/lua/ai_helper.lua"
local MAIUV = wesnoth.require "ai/micro_ais/micro_ai_unit_variables.lua"

local function get_last_unit(cfg)
	local filter = wml.get_child(cfg, "filter") or { id = cfg.id }
	local last_unit = AH.get_units_with_moves {
		side = wesnoth.current.side,
		{ "and", filter }
	}[1]

	return last_unit
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

	local last_unit_frozen = get_last_unit_frozen(cfg)
	local last_unit = get_last_unit(cfg)

	local other_unit = get_other_unit(cfg)

	if not other_unit then
		if last_unit_frozen then
			return score
		end
	end

	local last_unit = get_last_unit(cfg)
	if last_unit then
		return score
	end

	return 0
end

-- params for exec_parms (ai, cfg, self)
function ca_wf_move_last:execution(cfg, data, filter_own)

	local last_unit = get_last_unit(cfg)
	local other_unit = get_other_unit(cfg)

	if other_unit and last_unit then
		while last_unit do
			MAIUV.set_mai_unit_variables(last_unit, cfg.ai_id, { frozen = true, moves = last_unit.moves, attacks_left = last_unit.attacks_left, resting = last_unit.resting })
			AH.checked_stopunit_all(ai, last_unit)
			last_unit = get_last_unit(cfg)
		end
		return
	end

	last_unit = get_last_unit_frozen(cfg)
	while last_unit do
		last_unit.resting = MAIUV.get_mai_unit_variables(last_unit, cfg.ai_id, "resting" )
		last_unit.attacks_left = MAIUV.get_mai_unit_variables(last_unit, cfg.ai_id, "attacks_left" )
		last_unit.moves = MAIUV.get_mai_unit_variables(last_unit, cfg.ai_id, "moves" )
		MAIUV.delete_mai_unit_variables(last_unit, cfg.ai_id)
		last_unit = get_last_unit_frozen(cfg)
	end
end

return ca_wf_move_last
