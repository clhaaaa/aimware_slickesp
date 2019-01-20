local font_main = draw.CreateFont( "Tahoma Bold", 12, 12 )
local font_secondary = draw.CreateFont( "Small Fonts", 10, 10 )

-- Script --------
local cur_scriptname = GetScriptName()
local cur_version = "1.1"
local git_version = "https://raw.githubusercontent.com/itisluiz/aimware_slickesp/master/version.txt"
local git_repository = "https://raw.githubusercontent.com/itisluiz/aimware_slickesp/master/slickesp.lua"
local cur_updated = false
------------------

-- GUI Elements --
local ref_vis_enemy_options = gui.Reference( "VISUALS", "ENEMIES", "Options" )
local ref_vis_team_options = gui.Reference( "VISUALS", "TEAMMATES", "Options" )

local gb_slickesp_enemy = gui.Groupbox(ref_vis_enemy_options, "Slick ESP by Nyanpasu!", 0, 775, 213, 170)
local gb_slickesp_team = gui.Groupbox(ref_vis_team_options, "Slick ESP by Nyanpasu!", 0, 775, 213, 170)

local chb_enemy_name = gui.Checkbox(gb_slickesp_enemy, "esp_enemy_slickesp_name", "Name", 1)
local chb_team_name = gui.Checkbox(gb_slickesp_team, "esp_team_slickesp_name", "Name", 1)

local cob_enemy_health = gui.Combobox(gb_slickesp_enemy, "esp_enemy_slickesp_health", "Health", "Off", "Bar", "Bar and Number")
local cob_team_health = gui.Combobox(gb_slickesp_team, "esp_team_slickesp_health", "Health", "Off", "Bar", "Bar and Number")

local cob_enemy_ping = gui.Combobox(gb_slickesp_enemy, "esp_enemy_slickesp_ping", "Latency", "Off", "Entity", "Difference")
local cob_team_ping = gui.Combobox(gb_slickesp_team, "esp_team_slickesp_ping", "Latency", "Off", "Entity", "Difference")

local chb_enemy_weapon = gui.Checkbox(gb_slickesp_enemy, "esp_enemy_slickesp_weapon", "Weapon", 1)
local chb_team_weapon = gui.Checkbox(gb_slickesp_team, "esp_team_slickesp_weapon", "Weapon", 1)
------------------

-- Check for updates
local function git_update()
	if cur_version ~= http.Get(git_version) then
		if not gui.GetValue("lua_allow_cfg") then
			print("[Update] " .. cur_scriptname .. " is outdated. Please enable Lua Allow Config and Lua Editing under Settings")
			print(http.Get(git_version))
			print(cur_version)
		else
			local this_script = file.Open(cur_scriptname, "w")
			this_script:Write(http.Get(git_repository))
			this_script:Close()
			print("[Update] " .. cur_scriptname .. " has updated itself from version " .. cur_version .. " to " .. http.Get(git_version))
			RunScript(cur_scriptname)
		end
	else
		print("[Update] " .. cur_scriptname .. " is up-to-date")
	end
	cur_updated = true
end

if not cur_updated then
	git_update()
end


local Misc_bottomsize = 25
local PlayerData = {}

local function color_gradient(input0, input1, input2)
	input0 = (math.max(math.min(input0, 1), 0))
	
	local red = math.floor(  input0 * input2[1]) + ( (1 - input0) * input1[1] )
	local green = math.floor(  input0 * input2[2]) + ( (1 - input0) * input1[2] )
	local blue = math.floor(  input0 * input2[3]) + ( (1 - input0) * input1[3] )
	local alpha = math.floor(  input0 * input2[4]) + ( (1 - input0) * input1[4] )
	
	return red, green, blue, alpha;
end

local function ESPCallback(EspBuilder)
	
	local EspEnt = EspBuilder:GetEntity()
	
	if not EspEnt:IsPlayer() or entities.GetLocalPlayer() == nil then
		return	
	end
	
	local EspRect = {EspBuilder:GetRect()} -- x1, y1, x2, y2
	local Rect_width = EspRect[3] - EspRect[1]
	local Rect_height = EspRect[4] - EspRect[2]
	
	local EntLocal = entities.GetLocalPlayer()
	local Local_ping = entities.GetPlayerResources():GetPropInt("m_iPing", EntLocal:GetIndex())
	
	draw.SetFont(font_secondary)
	local Misc_hp_size = {draw.GetTextSize("HP:")}
	local Misc_hp_width = (EspRect[3] - Rect_width/2 +  Misc_bottomsize - 2) - (1 + EspRect[1] + Rect_width/2 - Misc_bottomsize + Misc_hp_size[1])
	local Misc_hp = EspEnt:GetHealth() / EspEnt:GetMaxHealth()
	local Misc_hp_gap = 0
	
	draw.SetFont(font_main)
	local Ent_index = EspEnt:GetIndex()
	local Ent_name = client.GetPlayerNameByIndex(EspEnt:GetIndex())
	local Ent_name_size = {draw.GetTextSize(Ent_name)}
	local Ent_isLocal = false
	local Ent_isTeam = false
	local Ent_weapon = EspEnt:GetPropEntity("m_hActiveWeapon") 
	local Ent_ping = entities.GetPlayerResources():GetPropInt("m_iPing", EspEnt:GetIndex())
	
	if EspEnt:GetTeamNumber() == EntLocal:GetTeamNumber() then
		Ent_isTeam = true
	end
	
	if EspEnt:GetIndex() == EntLocal:GetIndex() then
		Ent_isLocal = true
	end
	
	if PlayerData[Ent_index] == nil then
		PlayerData[Ent_index] = {globals.RealTime(), 0}
	elseif PlayerData[Ent_index][1] + 0.25 < globals.RealTime() or PlayerData[Ent_index][1] > globals.RealTime() then
		PlayerData[Ent_index][2] = 0
	elseif PlayerData[Ent_index][2] < 255 and PlayerData[Ent_index][1] + 1 >= globals.RealTime() then
		PlayerData[Ent_index][2] = PlayerData[Ent_index][2] + 5
	end
	
	PlayerData[EspEnt:GetIndex()][1] = globals.RealTime()
	
	local Misc_fadealpha = PlayerData[EspEnt:GetIndex()][2] / 255	
	
	-- Info rectangle
	if (Ent_isTeam and chb_team_name:GetValue()) or (not Ent_isTeam and chb_enemy_name:GetValue()) then
		local Misc_TLine_color = {255, 255, 255, 255}
		draw.Color( 40, 40, 40, 170 * Misc_fadealpha)
		draw.FilledRect(EspRect[1] + Rect_width/2 - Ent_name_size[1] / 2 - 5, EspRect[2] - Ent_name_size[2], EspRect[3] - Rect_width/2 + Ent_name_size[1] / 2 + 5, EspRect[2])
		draw.Color( 10, 10, 10, 170 * Misc_fadealpha)
		draw.OutlinedRect(EspRect[1] + Rect_width/2 - Ent_name_size[1] / 2 - 5, EspRect[2] - Ent_name_size[2], EspRect[3] - Rect_width/2 + Ent_name_size[1] / 2 + 5, EspRect[2])	
		if EspEnt:GetTeamNumber() == 3 then
			Misc_TLine_color = {gui.GetValue("clr_chams_ct_vis")}
		elseif EspEnt:GetTeamNumber() == 2 then
			Misc_TLine_color = {gui.GetValue("clr_chams_t_vis")}
		end
		draw.Color(Misc_TLine_color[1], Misc_TLine_color[2], Misc_TLine_color[3], Misc_TLine_color[4] * Misc_fadealpha)
		draw.Line(EspRect[1] + Rect_width/2 - Ent_name_size[1] / 2 - 5, EspRect[2] - Ent_name_size[2], EspRect[3] - Rect_width/2 + Ent_name_size[1] / 2 + 4, EspRect[2] - Ent_name_size[2])
		draw.Color( 200, 200, 200, 255 * Misc_fadealpha)
		draw.Text(EspRect[1] + Rect_width/2 - Ent_name_size[1]/2, EspRect[2] - Ent_name_size[2], Ent_name)
	end
	
	local BRect_width = (EspRect[3] - Rect_width/2 +  Misc_bottomsize) - (EspRect[1] + Rect_width/2 - Misc_bottomsize)
	
	-- HP rectangle
	if (Ent_isTeam and cob_team_health:GetValue() > 0) or (not Ent_isTeam and cob_enemy_health:GetValue() > 0) then
		local Misc_hp_color = {color_gradient(Misc_hp, {gui.GetValue("clr_esp_bar_health2")}, {gui.GetValue("clr_esp_bar_health1")})}
		draw.Color( 40, 40, 40, 170 * Misc_fadealpha)
		draw.FilledRect(EspRect[1] + Rect_width/2 - Misc_bottomsize, EspRect[4], EspRect[3] - Rect_width/2 +  Misc_bottomsize, EspRect[4] + Misc_hp_size[2])
		draw.Color( 10, 10, 10, 170 * Misc_fadealpha)
		draw.OutlinedRect(EspRect[1] + Rect_width/2 - Misc_bottomsize, EspRect[4], EspRect[3] - Rect_width/2 +  Misc_bottomsize, EspRect[4] + Misc_hp_size[2])
		draw.OutlinedRect(EspRect[1] + Rect_width/2 - Misc_bottomsize + Misc_hp_size[1], EspRect[4] + Misc_hp_size[2]/3, EspRect[3] - Rect_width/2 + Misc_bottomsize - 1, 1 + EspRect[4] + (Misc_hp_size[2]/3) * 2)
		draw.Color(Misc_hp_color[1], Misc_hp_color[2], Misc_hp_color[3], Misc_hp_color[4] * Misc_fadealpha)
		draw.FilledRect( 1 + EspRect[1] + Rect_width/2 - Misc_bottomsize + Misc_hp_size[1], 1 + EspRect[4] + Misc_hp_size[2]/3, (1 + EspRect[1] + Rect_width/2 - Misc_bottomsize + Misc_hp_size[1]) + (Misc_hp_width * Misc_hp), EspRect[4] + (Misc_hp_size[2]/3) * 2)
		draw.Color( 200, 200, 200, 255 * Misc_fadealpha)
		draw.SetFont(font_secondary)
		draw.Text( (EspRect[1] + Rect_width/2) - BRect_width/2, EspRect[4] + Misc_hp_size[2]/2 - Ent_name_size[2]/2, "HP:")
		if (Ent_isTeam and cob_team_health:GetValue() > 1) or (not Ent_isTeam and cob_enemy_health:GetValue() > 1) then
			draw.TextShadow( (1 + EspRect[1] + Rect_width/2 - Misc_bottomsize + Misc_hp_size[1]) + (Misc_hp_width * Misc_hp) - select(1, draw.GetTextSize(EspEnt:GetHealth())) / 2, EspRect[4] + Misc_hp_size[2]/2 - Ent_name_size[2]/2, EspEnt:GetHealth())
		end
		Misc_hp_gap = 1
	end
	
	-- Weapon rectangle
	if (Ent_isTeam and chb_team_weapon:GetValue()) or (not Ent_isTeam and chb_enemy_weapon:GetValue()) then
		draw.Color( 40, 40, 40, 170 * Misc_fadealpha)
		draw.FilledRect(EspRect[1] + Rect_width/2 - Misc_bottomsize, EspRect[4] + (Misc_hp_size[2] * Misc_hp_gap) + 1, EspRect[3] - Rect_width/2 +  Misc_bottomsize, EspRect[4] + Misc_hp_size[2] + (Misc_hp_size[2] * Misc_hp_gap))
		draw.Color( 10, 10, 10, 170 * Misc_fadealpha)
		draw.OutlinedRect(EspRect[1] + Rect_width/2 - Misc_bottomsize, EspRect[4] + (Misc_hp_size[2] * Misc_hp_gap) + 1, EspRect[3] - Rect_width/2 +  Misc_bottomsize, EspRect[4] + Misc_hp_size[2] + (Misc_hp_size[2] * Misc_hp_gap))
		draw.Color( 200, 200, 200, 255 * Misc_fadealpha)
		-- draw.Line(EspRect[1] + Rect_width/2 - Misc_bottomsize, EspRect[4] + Misc_hp_size[2] + 1, EspRect[1] + Rect_width/2 - Misc_bottomsize + (BRect_width * 1) - 1, EspRect[4] + Misc_hp_size[2] + 1) -- For future use
		draw.SetFont(font_secondary)
		draw.Text(EspRect[1] + Rect_width/2 - select(1, draw.GetTextSize(Ent_weapon:GetName())) / 2, EspRect[4] + Misc_hp_size[2]/2 - Ent_name_size[2]/2 + (Misc_hp_size[2] * Misc_hp_gap) + 1, Ent_weapon:GetName() )
	end
	
	-- Side ping difference
	if ( (Ent_isTeam and cob_team_ping:GetValue() == 1) or (not Ent_isTeam and cob_enemy_ping:GetValue() == 1) ) and Ent_ping > 0 then
		local pingColor = {color_gradient(Ent_ping/300, {255, 255, 255, 255}, {255, 70, 0, 255})}
		
		draw.SetFont(font_secondary)	
		draw.Color(pingColor[1], pingColor[2], pingColor[3], pingColor[4] * Misc_fadealpha)
		draw.TextShadow(EspRect[3], EspRect[2], Ent_ping)
		draw.Color( 200, 200, 200, 255 * Misc_fadealpha)
		draw.TextShadow(EspRect[3] + select(1, draw.GetTextSize(Ent_ping)), EspRect[2], "ms")
		
	elseif ( (Ent_isTeam and cob_team_ping:GetValue() == 2) or (not Ent_isTeam and cob_enemy_ping:GetValue() == 2) ) and not Ent_isLocal then
		draw.SetFont(font_secondary)
		local pingColor = {0, 120, 200, 255}
		local plusSign = ""
		if Local_ping - Ent_ping > 0 then
			pingColor = {200, 120, 0, 255}
			plusSign = "+"
		end
		draw.Color(pingColor[1], pingColor[2], pingColor[3], pingColor[4] * Misc_fadealpha)
		draw.TextShadow(EspRect[3], EspRect[2], plusSign .. Local_ping - Ent_ping)
		draw.Color( 200, 200, 200, 255 * Misc_fadealpha)
		draw.TextShadow(EspRect[3] + select(1, draw.GetTextSize(plusSign .. Local_ping - Ent_ping)), EspRect[2], "ms")
	end
	
end

-- Slick ESP by Nyanpasu!

callbacks.Register("DrawESP", ESPCallback);
