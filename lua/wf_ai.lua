local H = wesnoth.require "helper"

-- force_gamestate_change 1.14 by mattsc
local AH = wesnoth.require "ai/lua/ai_helper.lua"
local utils = wesnoth.require "wml-utils"
function utils.force_gamestate_change(ai)
	-- Can be done using any unit of the AI side with moves
	--local unit = wesnoth.get_units { side = wesnoth.current.side }[1]
	local unit = AH.get_units_with_moves { side = wesnoth.current.side }[1]
	local cfg_reset_moves = { id = unit.id, moves = unit.moves, resting = unit.resting, attacks_left = unit.attacks_left }
	ai.stopunit_all(unit)
-- if version >= 1.15.0
if wesnoth.compare_versions(wesnoth.game_config.version, ">=", "1.15.0") then
	wesnoth.sync.invoke_command('reset_moves', cfg_reset_moves)
-- else version < 1.15.0
else
	wesnoth.invoke_synced_command('reset_moves', cfg_reset_moves)
end
-- end version
end

-- reset_moves 1.14 by mattsc
function wesnoth.custom_synced_commands.reset_moves(cfg)
	local unit = wesnoth.get_units { id = cfg.id }[1]
	unit.resting = cfg.resting
	unit.attacks_left = cfg.attacks_left
	unit.moves = cfg.moves
end

-- force_gamestate_change 1.16 by mattsc
--function utils.force_gamestate_change(ai)
--	-- Can be done using any unit of the AI side; works even if the unit already has 0 moves
--	local unit = wesnoth.units.find_on_map { side = wesnoth.current.side }[1]
--	local cfg_reset_moves = { id = unit.id, moves = unit.moves }
--	ai.stopunit_moves(unit)
--	wesnoth.sync.invoke_command('reset_moves', cfg_reset_moves)
--end

-- reset_moves 1.16 by mattsc
--function wesnoth.custom_synced_commands.reset_moves(cfg)
--	local unit = wesnoth.units.find_on_map { id = cfg.id }[1]
--	unit.moves = cfg.moves
--end

function wesnoth.micro_ais.wf_zone_guardian(cfg)
	if (cfg.action ~= 'delete') and (not cfg.id) and (not wml.get_child(cfg, "filter")) then
		H.wml_error("WF Zone Guardian [micro_ai] tag requires either id= key or [filter] tag")
	end
	local required_keys = { "[filter_location]" }
	local optional_keys = { "id", "[filter]", "[filter_location_enemy]", "station_x", "station_y" }
	local CA_parms = {
		ai_id = 'mai_wf_zone_guardian',
		{ ca_id = 'move', location = '~add-ons/Wild_Frontiers/ai/ca_wf_zone_guardian.lua', score = cfg.ca_score or 300000 }
	}
    return required_keys, optional_keys, CA_parms
end

function wesnoth.micro_ais.wf_loiter_guardian(cfg)
	if (cfg.action ~= 'delete') and (not cfg.id) and (not wml.get_child(cfg, "filter")) then
		H.wml_error("WF Loiter Guardian [micro_ai] tag requires either id= key or [filter] tag")
	end
	local required_keys = { "[filter_location]" }
	local optional_keys = { "id", "[filter]", "stationary" }
	local CA_parms = {
		ai_id = 'mai_wf_loiter_guardian',
		{ ca_id = 'move', location = '~add-ons/Wild_Frontiers/ai/ca_wf_loiter_guardian.lua', score = cfg.ca_score or 99900 }
	}
    return required_keys, optional_keys, CA_parms
end

function wesnoth.micro_ais.wf_curse_guardian(cfg)
	if (cfg.action ~= 'delete') and (not cfg.id) and (not wml.get_child(cfg, "filter")) then
		H.wml_error("WF Curse Guardian [micro_ai] tag requires either id= key or [filter] tag")
	end
	local required_keys = { "[filter_second]" }
	local optional_keys = { "id", "[filter]" }
	local CA_parms = {
		ai_id = 'mai_wf_curse_guardian',
		{ ca_id = 'move', location = '~add-ons/Wild_Frontiers/ai/ca_wf_curse_guardian.lua', score = cfg.ca_score or 99900 }
	}
    return required_keys, optional_keys, CA_parms
end

function wesnoth.micro_ais.wf_goto(cfg)
	local required_keys = { "[filter_location]" }
	local optional_keys = {
		"avoid_enemies", "[filter]", "ignore_units", "ignore_enemy_at_goal",
		"release_all_units_at_goal", "release_unit_at_goal", "remove_movement", "unique_goals", "use_straight_line"
	}
	local CA_parms = {
		ai_id = 'mai_wf_goto',
		{ ca_id = 'move', location = '~add-ons/Wild_Frontiers/ai/ca_wf_goto.lua', score = cfg.ca_score or 300000 }
	}
    return required_keys, optional_keys, CA_parms
end

function wesnoth.micro_ais.wf_move_last(cfg)
        if (cfg.action ~= 'delete') and (not cfg.id) and (not wml.get_child(cfg, "filter")) then
                H.wml_error("WF Move Last [micro_ai] tag requires either id= key or [filter] tag")
        end
        local required_keys = { }
        local optional_keys = { "id", "[filter]" }
	local score = cfg.ca_score or 300000
        local CA_parms = {
                ai_id = 'mai_wf_move_last',
                { ca_id = 'move', location = '~add-ons/Wild_Frontiers/ai/ca_wf_move_last.lua', score = score }
        }
    return required_keys, optional_keys, CA_parms
end
