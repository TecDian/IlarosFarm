----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für Event-Verwaltung
----------------------------------------------------------------------------

function IlarosFarm.Event.RegisterEvents( frame )
	frame:RegisterEvent("WORLD_MAP_UPDATE")
	frame:RegisterEvent("CLOSE_WORLD_MAP"); -- never triggered apparently
	frame:RegisterEvent("SPELLS_CHANGED"); -- follow current skills
	frame:RegisterEvent("SKILL_LINES_CHANGED"); -- follow current skills
	frame:RegisterEvent("UI_ERROR_MESSAGE"); -- track failed farming
	frame:RegisterEvent("ZONE_CHANGED_NEW_AREA") -- for updating the minimap when we change zones
	frame:RegisterEvent("MINIMAP_UPDATE_TRACKING") -- for updating minimap when tracking changes

	-- Events for off world non processing
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("PLAYER_LEAVING_WORLD")

	-- Addon Loaded and player login/logout events
	frame:RegisterEvent("ADDON_LOADED")
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:RegisterEvent("PLAYER_LOGOUT")

	-- Communications
	frame:RegisterEvent("CHAT_MSG_ADDON")
end

function IlarosFarm.Event.OnLoad()
	
	local hookFunc = function( ... ) IlarosFarm.Event.OnSwag(...) end
	LibSwag.RegisterHook("IlarosFarm", hookFunc, hookFunc)
	LibSwag.Init()
	
	IlarosFarm.Config.Load()
	IlarosFarm.DropRates.Load()
	IlarosFarm.Var.Loaded = true
	
	IlarosFarm.MapNotes.Update()
	IlarosFarm.MiniNotes.Show()
	
	IlarosFarm.MiniIcon.CreateLDB()
	IlarosFarm.MiniIcon.Reposition()
	IlarosFarm.MiniIcon.Update()
	
	if ( IlarosFarm.Config.GetSetting("about.loaded") ) then
		IlarosFarm.Util.ChatPrint(string.format(FarmText_Load,IlarosFarm.Var.Version))
	end
end

function IlarosFarm.Event.OnEvent( event, ... )
	if (event == "PLAYER_ENTERING_WORLD" ) then
		IlarosFarm.MiniNotes.Show()

	elseif (event == "PLAYER_LEAVING_WORLD" ) then
		IlarosFarm.MiniNotes.Hide()

	elseif (event == "WORLD_MAP_UPDATE") then
		IlarosFarm.MapNotes.MapDraw()
	
	elseif ( event == "CLOSE_WORLD_MAP") then
		IlarosFarm.MapNotes.MapDraw()

	elseif( event == "ADDON_LOADED" ) then
		local addon = select(1, ...)
		if (addon and string.lower(addon) == "ilarosfarm") then
			IlarosFarm.Event.OnLoad()
		end
	
	elseif ( event == "PLAYER_LOGIN" ) then
		IlarosFarm.Util.StartClientItemCacheRefresh()
		IlarosFarm.Util.GetSkills()
		IlarosFarm.Util.UpdateTrackingState()
	
	elseif ( event == "PLAYER_LOGOUT" ) then
		IlarosFarm.Config.Save()
		IlarosFarm.DropRates.Save()
	
	elseif ( event == "LEARNED_SPELL_IN_TAB" ) then
		IlarosFarm.Util.GetSkills()
	
	elseif ( event == "SPELLS_CHANGED" ) then
		IlarosFarm.Util.GetSkills()
	
	elseif ( event == "SKILL_LINES_CHANGED" ) then
		IlarosFarm.Util.GetSkills()
	
	elseif ( event == "MINIMAP_UPDATE_TRACKING" ) then
		IlarosFarm.Util.UpdateTrackingState()
		IlarosFarm.MiniNotes.ForceUpdate()
	
	elseif ( event == "CHAT_MSG_ADDON" ) then
		local prefix, msg, how, who = select(1, ...)
		if ( prefix == "GathX" ) then
			IlarosFarm.Comm.Receive( msg, how, who )
		elseif ( prefix == "IlarosFarm" ) then
			IlarosFarm.Comm.General(msg, how, who)
		end
		
	elseif ( event == "ZONE_CHANGED_NEW_AREA" ) then
		IlarosFarm.MiniNotes.Show()
	
	elseif ( event == "UI_ERROR_MESSAGE" ) then
		local msg =  select(1, ...)
		local skill = IlarosFarm.Util.ParseFormattedMessage(ERR_USE_LOCKED_WITH_ITEM_S, msg)
		if not ( skill ) then
			skill = IlarosFarm.Util.ParseFormattedMessage(ERR_USE_LOCKED_WITH_SPELL_KNOWN_SI, msg)
		end

		-- Check if there was a skill mentioned, then check to see if we're moused over a valid object
		if ( skill ) then
			LibSwag.SetTooltip()
			local tooltip = LibSwag.GetLastTip()
			if not ( tooltip ) then return end
			local tip = tooltip.tip

			local objId = IlarosFarm.Nodes.Names[tip]
			if ( objId ) then
				-- We have a mouseover on a valid object that's just fired off
				-- a "Requires" message.
				local gType = IlarosFarm.Nodes.Objects[objId]
				IlarosFarm.Api.AddFarm(objId, gType, tip, "REQUIRE", 0, {}, false)
			end
		end
	
	elseif ( event ) then
		IlarosFarm.Util.Debug("IlarosFarm Unknown event: "..event)
	end
end

function IlarosFarm.Event.OnSwag(lootType, lootTable, coinAmount, extraData)
	IlarosFarm.Util.Debug("IlarosFarm.Event.OnSwag", lootType)
	if (lootType ~= "KILL") then
		local node = "Unknown"
        -- wenn "MINE", "HERB" oder "OPEN" (auch "SKIN")
		if (extraData and extraData.tip) then
            node = extraData.tip
        -- wenn "FISH"
        elseif (lootTable and lootTable[1].name) then
            node = lootTable[1].name
        end
		-- dann Code zum Namen ermitteln, sonst beenden
		local object = IlarosFarm.Nodes.Names[node]
		if (not object) then return end

		-- Typ ermitteln und schauen, ob er in der Typentabelle vorkommt, sonst beenden
		local objectType = IlarosFarm.Nodes.Objects[object]
		if (objectType ~= lootType) then return end
		
		-- increments only if both lootTable and coinAmount are non-nil
		IlarosFarm.Api.AddFarm(object, lootType, storagetip, nil, coinAmount, lootTable, (lootTable and coinAmount))
	end
end
