#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	setDvar("scr_mapvote_enable", 1);
	setDvar("scr_mapvote_time", 15);
	setDvar("scr_mapvote_allow_dlc", 0);
	setDvar("scr_mapvote_options", 6);
	setDvar("scr_mapvote_change_delay", 3);
	setDvar("scr_mapvote_snd_allowed", 1);
	setDvar("scr_mapvote_ffa_allowed", 0);
	setDvar("scr_mapvote_allow_end", 1);

	if(!getDvarInt("scr_mapvote_enable"))
		return;

	level.mapvote_active = false;
	level.mapvote_finished = false;
	level.votemaps = [];
	level.mapvote_winning_index = -1;
	level.mapvote_winning_map = "";
	level.mapvote_winning_gametype = "";
	level.mapvote_winning_is_random = false;
	level.mapvote_timeleft = 0;

	
	precacheShader("minimap_scanlines");

	mapvote_build_map_pool();
	mapvote_build_gametypes();

	if(getDvarInt("scr_mapvote_allow_end"))
		level thread onPlayerConnectHook();
}

onPlayerConnectHook()
{
    while(true)
    {
        level waittill("connected", player);
        if(!player maps\mp\bots\_bot_utility::is_bot())
            player thread onMenuResponseHook();
    }
}

onMenuResponseHook()
{
	self endon("disconnect");
    level endon("round_end_finished");
	
	while(true)
	{
		self waittill("menuresponse", menu, response);
		
		if ( response == "endround" )
            exitLevel( false );
    }
}

mapvote_build_map_pool()
{
	level.mapvote_all_maps = [];
	level.mapvote_mapnames = [];
	level.mapvote_dlc_maps = [];

	mapvote_add_map("mp_afghan", "Afghan", false);
	mapvote_add_map("mp_derail", "Derail", false);
	mapvote_add_map("mp_estate", "Estate", false);
	mapvote_add_map("mp_favela", "Favela", false);
	mapvote_add_map("mp_highrise", "Highrise", false);
	mapvote_add_map("mp_invasion", "Invasion", false);
	mapvote_add_map("mp_checkpoint", "Karachi", false);
	mapvote_add_map("mp_quarry", "Quarry", false);
	mapvote_add_map("mp_rundown", "Rundown", false);
	mapvote_add_map("mp_rust", "Rust", false);
	mapvote_add_map("mp_boneyard", "Scrapyard", false);
	mapvote_add_map("mp_nightshift", "Skidrow", false);
	mapvote_add_map("mp_subbase", "Sub Base", false);
	mapvote_add_map("mp_terminal", "Terminal", false);
	mapvote_add_map("mp_underpass", "Underpass", false);
	mapvote_add_map("mp_brecourt", "Wasteland", false);
	mapvote_add_map("mp_complex", "Bailout", true);
	mapvote_add_map("mp_abandon", "Carnival", true);
	mapvote_add_map("mp_crash", "Crash", true);
	mapvote_add_map("mp_overgrown", "Overgrown", true);
	mapvote_add_map("mp_compact", "Salvage", true);
	mapvote_add_map("mp_storm", "Storm", true);
	mapvote_add_map("mp_vacant", "Vacant", true);
	mapvote_add_map("mp_trailerpark", "Trailer Park", true);
	mapvote_add_map("mp_strike", "Strike", true);
	mapvote_add_map("mp_fuel2", "Fuel", true);
}

mapvote_add_map(mapname, pretty, dlc)
{
	level.mapvote_all_maps[level.mapvote_all_maps.size] = mapname;
	level.mapvote_mapnames[mapname] = pretty;

	if(dlc)
		level.mapvote_dlc_maps[level.mapvote_dlc_maps.size] = mapname;
}

mapvote_build_gametypes()
{
	level.mapvote_gametypes = [];
	level.mapvote_gametype_names = [];

	mapvote_add_gametype("war", "TDM");
	mapvote_add_gametype("dom", "DOM");

	if(getDvarInt("scr_mapvote_snd_allowed"))
		mapvote_add_gametype("sd", "S&D");

	if(getDvarInt("scr_mapvote_ffa_allowed"))
		mapvote_add_gametype("dm", "FFA");
}

mapvote_add_gametype(gt, pretty)
{
	level.mapvote_gametypes[level.mapvote_gametypes.size] = gt;
	level.mapvote_gametype_names[gt] = pretty;
}

mapvote_in_array(array, value)
{
	for(i = 0; i < array.size; i++)
	{
		if(array[i] == value)
			return true;
	}

	return false;
}

mapvote_allow_map(mapname)
{
	if(getDvarInt("scr_mapvote_allow_dlc"))
		return true;

	if(mapvote_in_array(level.mapvote_dlc_maps, mapname))
		return false;

	return true;
}

mapvote_remove_array_index(array, remove_index)
{
	out = [];
	for(i = 0; i < array.size; i++)
	{
		if(i != remove_index)
			out[out.size] = array[i];
	}

	return out;
}

mapvote_get_valid_pool()
{
	pool = [];
	for(i = 0; i < level.mapvote_all_maps.size; i++)
	{
		mapname = level.mapvote_all_maps[i];

		if(!mapvote_allow_map(mapname))
			continue;

		pool[pool.size] = mapname;
	}

	return pool;
}

mapvote_build_options()
{
	level.votemaps = [];
	option_count = getDvarInt("scr_mapvote_options");

	if(option_count < 2)
		option_count = 2;
	if(option_count > 6)
		option_count = 6;

	pool = mapvote_get_valid_pool();

	normal_count = option_count - 1;
	for(i = 0; i < normal_count; i++)
	{
		if(pool.size <= 0)
			break;

		map_index = randomInt(pool.size);
		mapvote_add_option(pool[map_index], level.mapvote_gametypes[randomInt(level.mapvote_gametypes.size)], false);
		pool = mapvote_remove_array_index(pool, map_index);
	}

	mapvote_add_option("", level.mapvote_gametypes[randomInt(level.mapvote_gametypes.size)], true);
}

mapvote_add_option(mapname, gametype, random_option)
{
	entry = spawnStruct();
	entry.map = mapname;
	entry.gametype = gametype;
	entry.is_random = random_option;
	entry.votes = 0;
	level.votemaps[level.votemaps.size] = entry;
}

start_mapvote()
{
	if(isDefined(level.mapvote_active) && level.mapvote_active)
		return;

	level.mapvote_active = true;
	level.mapvote_finished = false;
	level.mapvote_timeleft = getDvarInt("scr_mapvote_time");
	level.mapvote_winning_index = -1;
	level.mapvote_winning_map = "";
	level.mapvote_winning_gametype = "";
	level.mapvote_winning_is_random = false;

	mapvote_build_options();
	level thread mapvote_timer();
	level thread OverflowFixInit();

	foreach(player in level.players)
	{
		if(!isDefined(player))
			continue;

		if(player maps\mp\bots\_bot_utility::is_bot())
			kick(player getEntityNumber());

		player.mapvote_selection = 0;
		player.vote_id = undefined;
		player thread mapvote_player_init();
	}
}

mapvote_player_init()
{
	self endon("disconnect");
	level endon("mapvote_ended");

	self freezeControlsWrapper(true);
	self thread mapvote_monitor_disconnect();
	self thread mapvote_create_hud();
	self thread mapvote_input_monitor();
	self thread mapvote_cinematic();
}

mapvote_monitor_disconnect()
{
	level endon("mapvote_ended");
	self waittill("disconnect");

	if(isDefined(self.vote_id) && self.vote_id >= 0 && self.vote_id < level.votemaps.size && level.votemaps[self.vote_id].votes > 0)
		level.votemaps[self.vote_id].votes--;
}

mapvote_create_hud()
{
	self endon("disconnect");
	level endon("mapvote_ended");

	self mapvote_destroy_hud();

	self.mapvote_title = createFontString("objective", 2.0);
	self.mapvote_title setPoint("TOP", "TOP", 0, 24);
	self.mapvote_title.alpha = 1;
	self.mapvote_title _setText("^1MAP VOTING");

	self.mapvote_help = createFontString("default", 1.25);
	self.mapvote_help setPoint("TOP", "TOP", 0, 48);
	self.mapvote_help.alpha = 1;
	self.mapvote_help _setText("[{+attack}] | [{+speed_throw}] - Navigate - [{+activate}] | [{+usereload}] Vote");

	self.mapvote_timer_text = createFontString("default", 1.35);
	self.mapvote_timer_text setPoint("TOP", "TOP", 0, 68);
	self.mapvote_timer_text.alpha = 1;
	self.mapvote_timer_text _setText("Time Left: ^1" + level.mapvote_timeleft);

	self.mapvote_rows = [];
	self.mapvote_highlights = [];

	for(i = 0; i < level.votemaps.size; i++)
	{
		self.mapvote_highlights[i] = createIcon("minimap_scanlines", 275, 18);
		self.mapvote_highlights[i] setPoint("TOP", "TOP", 0, 96 + (i * 22));
		self.mapvote_highlights[i].color = rgb(255, 0, 0);
		self.mapvote_highlights[i].alpha = 0;

		self.mapvote_rows[i] = createFontString("default", 1.4);
		self.mapvote_rows[i] setPoint("TOP", "TOP", 0, 95 + (i * 22));
		self.mapvote_rows[i].alpha = 1;
		self.mapvote_rows[i] _setText("");
	}

	self thread mapvote_hud_loop();
}

mapvote_destroy_hud()
{
	if(isDefined(self.mapvote_title)) self.mapvote_title destroy();
	if(isDefined(self.mapvote_help)) self.mapvote_help destroy();
	if(isDefined(self.mapvote_timer_text)) self.mapvote_timer_text destroy();

	if(isDefined(self.mapvote_highlights))
	{
		for(i = 0; i < self.mapvote_highlights.size; i++)
			if(isDefined(self.mapvote_highlights[i])) self.mapvote_highlights[i] destroy();
	}

	if(isDefined(self.mapvote_rows))
	{
		for(i = 0; i < self.mapvote_rows.size; i++)
			if(isDefined(self.mapvote_rows[i])) self.mapvote_rows[i] destroy();
	}

	self.mapvote_title = undefined;
	self.mapvote_help = undefined;
	self.mapvote_timer_text = undefined;
	self.mapvote_highlights = undefined;
	self.mapvote_rows = undefined;
}

mapvote_hud_loop()
{
	self endon("disconnect");
	level endon("mapvote_ended");

	while(level.mapvote_active && !level.mapvote_finished)
	{
		if(isDefined(self.mapvote_timer_text))
			self.mapvote_timer_text _setText("Time Left: ^1" + level.mapvote_timeleft);

		for(i = 0; i < level.votemaps.size; i++)
		{
			if(isDefined(self.mapvote_rows[i]))
				self.mapvote_rows[i] _setText(mapvote_build_row_text(i, self));

			if(isDefined(self.mapvote_highlights[i]))
				if(self.mapvote_selection == i)
					self.mapvote_highlights[i].alpha = 0.25;
				else
					self.mapvote_highlights[i].alpha = 0;
		}

		wait 0.05;
	}
}

mapvote_build_row_text(index, player)
{
	if(index < 0 || index >= level.votemaps.size)
		return "";

	entry = level.votemaps[index];

	if(entry.is_random)
		label = "Random Map";
	else
		label = level.mapvote_mapnames[entry.map];

	mode = level.mapvote_gametype_names[entry.gametype];

	if(isDefined(player.mapvote_selection) && player.mapvote_selection == index)
		text = "^1" + label;
	else
		text = "^7" + label;

	text += " ^7- ^3" + mode + " ^7- " + entry.votes;

	if(entry.votes == 1)
		text += " vote";
	else
		text += " votes";

	if(isDefined(player.vote_id) && player.vote_id == index)
		text += " ^1[X]";

	return text;
}

mapvote_input_monitor()
{
	self endon("disconnect");
	level endon("mapvote_ended");

	while(level.mapvote_active && !level.mapvote_finished)
	{
		if(self adsbuttonpressed()) self mapvote_move_selection(-1);
		if(self attackbuttonpressed()) self mapvote_move_selection(1);
		if(self usebuttonpressed()) self cast_vote(self.mapvote_selection);
		wait 0.25;
	}
}

mapvote_move_selection(direction)
{
	if(!level.mapvote_active || level.votemaps.size <= 0)
		return;

	self.mapvote_selection += direction;

	if(self.mapvote_selection < 0)
		self.mapvote_selection = level.votemaps.size - 1;
	else if(self.mapvote_selection >= level.votemaps.size)
		self.mapvote_selection = 0;
}

cast_vote(idx)
{
	if(!level.mapvote_active || idx < 0 || idx >= level.votemaps.size)
		return;

	if(isDefined(self.vote_id))
	{
		if(self.vote_id == idx)
			return;

		if(self.vote_id >= 0 && self.vote_id < level.votemaps.size && level.votemaps[self.vote_id].votes > 0)
			level.votemaps[self.vote_id].votes--;
	}

	self.vote_id = idx;
	level.votemaps[idx].votes++;
}

mapvote_timer()
{
	while(level.mapvote_timeleft > 0 && level.mapvote_active && !level.mapvote_finished)
	{
		wait 1;
		level.mapvote_timeleft--;
		playSoundOnPlayers("ui_mp_timer_countdown");
	}

	if(level.mapvote_active && !level.mapvote_finished)
		finish_mapvote();
}

finish_mapvote()
{
	if(level.mapvote_finished)
		return;

	foreach(player in level.players)
	{
		if(isDefined(player))
			player mapvote_destroy_hud();
	}

	level.mapvote_finished = true;
	level.mapvote_active = false;
	mapvote_pick_winner();
}

mapvote_pick_winner()
{
	level notify("mapvote_ended");
	level.mapvote_winning_index = -1;
	level.mapvote_winning_map = "";
	level.mapvote_winning_gametype = "";
	level.mapvote_winning_is_random = false;

	if(level.votemaps.size <= 0)
		return;

	best_votes = -1;
	tied = [];

	for(i = 0; i < level.votemaps.size; i++)
	{
		votes = level.votemaps[i].votes;

		if(votes > best_votes)
		{
			best_votes = votes;
			tied = [];
			tied[0] = i;
		}
		else if(votes == best_votes)
			tied[tied.size] = i;
	}

	winner_index = tied[randomInt(tied.size)];
	entry = level.votemaps[winner_index];
	level.mapvote_winning_index = winner_index;
	level.mapvote_winning_map = entry.map;
	level.mapvote_winning_gametype = entry.gametype;
	level.mapvote_winning_is_random = entry.is_random;

	wait getDvarFloat("scr_mapvote_change_delay");
	commit_mapvote_winner();
}

mapvote_get_random_final_map()
{
	pool = mapvote_get_valid_pool();
	return pool[randomInt(pool.size)];
}

commit_mapvote_winner()
{
	if(level.mapvote_winning_gametype == "")
		return;

	if(level.mapvote_winning_is_random)
		winningmap = mapvote_get_random_final_map();
	else
		winningmap = level.mapvote_winning_map;

	winninggametype = level.mapvote_winning_gametype;

	if(winningmap == "" || winninggametype == "")
		return;

	apply_mapvote_winner(winningmap, winninggametype);
}

apply_mapvote_winner(winningmap, winninggametype)
{
	if(!isDefined(winningmap) || !isDefined(winninggametype) || winningmap == "" || winninggametype == "")
		return;

	setDvar("g_gametype", winninggametype);
	wait 0.05;
	map(winningmap, false);
}

mapvote_get_camera_data()
{
	data = spawnStruct();
	spawnPoints = getEntArray("mp_global_intermission", "classname");
	assertEx(spawnPoints.size, "NO mp_global_interMISSION SPAWNPOINTS IN MAP");

	spawnPoint = spawnPoints[0];
	data.origin = spawnPoint.origin + (0, 0, 12);
	data.endorigin = spawnPoint.origin + (0, 0, 72);
	data.startangles = (32, spawnPoint.angles[1], 0);
	data.endangles = (8, spawnPoint.angles[1], 0);

	return data;
}

mapvote_cinematic()
{
	self endon("disconnect");
	level endon("mapvote_ended");

	if(!isDefined(level.mapvote_active) || !level.mapvote_active)
		return;

	cam = mapvote_get_camera_data();
	duration = getDvarFloat("scr_mapvote_time");
	if(duration <= 0) duration = 10;

	self freezeControls(true);
	self setOrigin(cam.origin);
	self setPlayerAngles(cam.startangles);
	self hide();
	self takeallweapons();
	self childthread cinematic_bars();

	cam_movement = int(duration / 0.05);
	if(cam_movement < 1) cam_movement = 1;

	for(i = 0; i <= cam_movement; i++)
	{
		if(!level.mapvote_active || level.mapvote_finished)
			break;

		f = i/cam_movement;
		self setPlayerAngles((cam.startangles[0] + ((cam.endangles[0] - cam.startangles[0]) * f), cam.startangles[1] + ((cam.endangles[1] - cam.startangles[1]) * f), cam.startangles[2] + ((cam.endangles[2] - cam.startangles[2]) * f)));
		wait 0.05;
	}
}

cinematic_bars()
{
	self endon("disconnect");
	level endon("mapvote_ended");

	bars = [];
	bars[0] = self hudCreateRectangle(640, 240, (0, 0, 0));
	bars[1] = self hudCreateRectangle(640, 240, (0, 0, 0));
	foreach(bar in bars)
	{
		bar.archived = false;
		bar.foreground = true;
		bar.x = -106.6666;
		bar.sort = 1000;
		bar.horzAlign = "fullscreen";
		bar.vertAlign = "middle";
	}
	bars[0].alignY = "bottom";
	bars[1].alignY = "top";
	foreach(bar in bars)
	{
		bar moveOverTime(0.35);
		bar.x = 0;
	}
	bars[0].y = -240;
	bars[1].y = 240;
	self setBlurForPlayer(10, getDvarFloat("scr_mapvote_time"));
	wait 1;
	foreach(bar in bars)
	{
		if(isDefined(bar))
			bar destroy();
	}
}

hudCreateRectangle(w, h, color, team)
{
	rect = undefined;
	if (isPlayer(self))
		rect = newClientHudElem(self);
	else if (isDefined(team))
		rect = newTeamHudElem(team);
	else
		rect = newHudElem();
	rect.elemType = "rect";
	rect.x = 0;
	rect.y = 0;
	rect.xOffset = 0;
	rect.yOffset = 0;
	rect.width = w;
	rect.height = h;
	rect.baseWidth = w;
	rect.baseHeight = h;
	rect.color = color;
	rect.alpha = 1.0;
	rect.children = [];
	rect maps\mp\gametypes\_hud_util::setParent(level.uiParent);
	rect.hidden = false;
	rect setShader("white", int(w), int(h));
	rect.shader = "white";
	return rect;
}

rgb(r, g, b)
{
	return (r/255, g/255, b/255);
}

OverflowFixInit()
{
	if(isDefined(level.overflowFixStarted) && level.overflowFixStarted)
		return;

	level.overflowFixStarted = true;
	level.strings = [];
	level.overflowElem = CreateServerFontString("default", 1.5);
	level.overflowElem _setText("");
	level.overflowElem.alpha = 0;
	level thread OverflowFixMonitor();
}

OverflowFixMonitor()
{
	level endon("game_ended");

	while(true)
	{
		level waittill("string_added");

		if(level.strings.size >= 55)
		{
			for(i = 0; i < 3; i++)
				level.overflowElem ClearAllTextAfterHudElem();

			level.strings = [];
			level notify("overflow_fixed");
			wait 0.05;
		}
	}
}

_setText(text)
{
	self.string = text;
	self setText(text);
	self childthread fix_string();
	self add_string(text);
}

add_string(string)
{
	level.strings[level.strings.size] = string;
	level notify("string_added");
}

fix_string()
{
	self notify("new_string");
	self endon("new_string");

	while(isDefined(self))
	{
		level waittill("overflow_fixed");
		self _setText(self.string);
	}
}