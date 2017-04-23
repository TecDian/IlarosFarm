----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für Notizen auf der Weltkarte
----------------------------------------------------------------------------

-- reference to the Astrolabe mapping library
local Astrolabe = DongleStub(IlarosFarm.AstrolabeVersion)

function IlarosFarm.MapNotes.Enable()
	IlarosFarm.Config.SetSetting("mainmap.enable", true)
	IlarosFarm.MapNotes.Update()
end

function IlarosFarm.MapNotes.Disable()
	IlarosFarm.Config.SetSetting("mainmap.enable", false)
	IlarosFarm.MapNotes.Update()
end

function IlarosFarm.MapNotes.ToggleDisplay()
	if ( IlarosFarm.Config.GetSetting("mainmap.enable") ) then
		IlarosFarm.MapNotes.Disable()
	else
		IlarosFarm.MapNotes.Enable()
	end
end

function IlarosFarm.MapNotes.Update()
	if ( IlarosFarm.Config.GetSetting("mainmap.enable") ) then
		IlarosFarm_WorldMapDisplay:SetText(FarmText_MMH)
		IlarosFarmMapOverlayParent:Show()
	else
		IlarosFarm_WorldMapDisplay:SetText(FarmText_MMS)
		IlarosFarmMapOverlayParent:Hide()
	end
end

function IlarosFarm.MapNotes.GetNoteObject( noteNumber )
	local button = _G["FarmMain"..noteNumber]
	if not ( button ) then
		local overlayFrameNumber = math.ceil(noteNumber / 100)
		local overlayFrame = IlarosFarmMapOverlayParent[overlayFrameNumber]
		if not ( overlayFrame ) then
			overlayFrame = CreateFrame("Frame", "IlarosFarmMapOverlayFrame"..overlayFrameNumber, IlarosFarmMapOverlayParent, "IlarosFarmMapOverlayTemplate")
			IlarosFarmMapOverlayParent[overlayFrameNumber] = overlayFrame
		end
		button = CreateFrame("Button" ,"FarmMain"..noteNumber, overlayFrame, "FarmMainTemplate")
		button:SetID(noteNumber)
		overlayFrame[(noteNumber-1) % 100 + 1] = button
		IlarosFarm.Util.Debug("create id "..noteNumber.." frame ".. overlayFrameNumber)
	end
	return button
end

function IlarosFarm.MapNotes.MapDraw()
	local IlarosFarmMapOverlayParent = IlarosFarmMapOverlayParent
	if not ( IlarosFarmMapOverlayParent:IsVisible() ) then
		return
	end
	local setting = IlarosFarm.Config.GetSetting
	local maxNotes = setting("mainmap.count", 600)
	local noteCount = 0

	-- prevent the function from running twice at the same time.
	if (IlarosFarm.Var.UpdateWorldMap == 0 ) then return; end
	IlarosFarm.Var.UpdateWorldMap = 0
	
	local showType, showObject
	local mapContinent = GetCurrentMapContinent()
	local mapZone = GetCurrentMapZone()
	if ( IlarosFarm.Storage.HasDataOnZone(mapContinent, mapZone) ) then
		for nodeId, farmType, num in IlarosFarm.Storage.ZoneFarmNames(mapContinent, mapZone) do
			if ( IlarosFarm.Config.DisplayFilter_MainMap(nodeId) ) then
				for index, xPos, yPos, count in IlarosFarm.Storage.ZoneFarmNodes(mapContinent, mapZone, nodeId) do
					if ( noteCount < maxNotes ) then
						noteCount = noteCount + 1
						local mainNote = IlarosFarm.MapNotes.GetNoteObject(noteCount)
						
						mainNote:SetAlpha(setting("mainmap.opacity", 80) / 100)
						
						local texture = IlarosFarm.Util.GetNodeTexture(nodeId)
						_G[mainNote:GetName().."Texture"]:SetTexture(texture)
						
						local iconsize = setting("mainmap.iconsize", 16)
						mainNote:SetWidth(iconsize)
						mainNote:SetHeight(iconsize)
						
						mainNote.continent = mapContinent
						mainNote.zone = mapZone
						mainNote.id = nodeId
						mainNote.index = index

						local tooltip = setting("mainmap.tooltip.enable")
						if (tooltip and not mainNote:IsMouseEnabled()) then
							mainNote:EnableMouse(true)
						elseif (not tooltip and mainNote:IsMouseEnabled()) then
							mainNote:EnableMouse(false)
						end
						
						Astrolabe:PlaceIconOnWorldMap(WorldMapButton, mainNote, mapContinent, mapZone, xPos, yPos)
					else -- reached note limit
						break
					end
				end
			end
		end
	end
	
	local numUsedOverlays = math.ceil(noteCount / 100)
	local partialOverlay = IlarosFarmMapOverlayParent[numUsedOverlays]
	for i = (noteCount - ((numUsedOverlays - 1) * 100) + 1), 100 do
		local note = partialOverlay[i]
		if not ( note ) then
			break
		end
		note:Hide()
	end
	for i, overlay in ipairs(IlarosFarmMapOverlayParent) do
		if ( i <= numUsedOverlays ) then
			overlay:Show()
		else
			overlay:Hide()
		end
	end
	
	IlarosFarm.Var.UpdateWorldMap = -1
end

function IlarosFarm.MapNotes.MapOverlayFrame_OnHide( frame )
	for _, childFrame in ipairs(frame) do
		childFrame:Hide()
	end
end

function IlarosFarm.MapNotes.MapNoteOnEnter(frame)
	local setting = IlarosFarm.Config.GetSetting
	local tooltip = IlarosFarm_WorldMapTooltip

	local enabled = setting("mainmap.tooltip.enable")
	if (not enabled) then 
		return
	end
	
	local showcount = setting("mainmap.tooltip.count")
	local showsource = setting("mainmap.tooltip.source")
	local showseen = setting("mainmap.tooltip.seen")
	local showrate = setting("mainmap.tooltip.rate")

	tooltip:SetOwner(frame, "ANCHOR_BOTTOMLEFT")
	
	local id = frame.id
	local name = IlarosFarm.Util.GetNodeName(id)
	local _, _, 
		count, 
		gType, 
		harvested, 
		inspected, 
		who = IlarosFarm.Storage.GetNodeInfo(frame.continent, frame.zone, id, frame.index)
	local last = inspected or harvested

	tooltip:ClearLines()
	tooltip:AddLine(name)
	if (count > 0 and showcount) then
		tooltip:AddLine(string.format(FarmText_TT2, count))
	end
	if (who and showsource) then
		if (who == "REQUIRE") then
			tooltip:AddLine(FarmText_TT8)
		elseif (who == "IMPORTED") then
			tooltip:AddLine(FarmText_TT7)
		else
			tooltip:AddLine(string.format(FarmText_TT6, who:gsub(",", ", ")))
		end
	end
	if (last and last > 0 and showseen) then
		tooltip:AddLine(string.format(FarmText_TT4, IlarosFarm.Util.SecondsToTime(time()-last)))
	end
	
	if ( showrate ) then
		local num = IlarosFarm.Config.GetSetting("mainmap.tooltip.rate.num")
		IlarosFarm.Tooltip.AddDropRates(tooltip, id, frame.continent, frame.zone, num)
	end
	tooltip:Show()
end
