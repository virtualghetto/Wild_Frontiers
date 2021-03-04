local H = wesnoth.require "helper"

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
