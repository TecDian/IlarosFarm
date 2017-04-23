----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für Servicefunktionen
----------------------------------------------------------------------------

-- reference to the Astrolabe mapping library
local Astrolabe = DongleStub(IlarosFarm.AstrolabeVersion)

function IlarosFarm.Util.Round(x)
	return math.ceil(x - 0.5);
end

function IlarosFarm.Util.BreakLink(link)
	--DEFAULT_CHAT_FRAME:AddMessage("Breaking link: " .. (link or "None"))

	if (type(link) ~= 'string') then return end
--	local item, name = link:match("|H(.-)|h[[]([^]]+)[]]|h")
	local i,j, item, name = string.find(link, "|H(.-)|h[[](.-)[]]|h")
	--DEFAULT_CHAT_FRAME:AddMessage(" found item "..(item or "None")..": " .. (name or "None"))
	local itype, id, enchant, slot1,slot2,slot3,slot4, random, uniq = strsplit(":", item)
	
	--DEFAULT_CHAT_FRAME:AddMessage(" id: "..(id or "None"))
	if (random == nil) then
		random, uniq = slot1, slot2
		slot1, slot2, slot3, slot4 = 0, 0, 0, 0
	end
	return
		tonumber(id) or 0,
		tonumber(enchant) or 0,
		tonumber(random) or 0,
		tonumber(slot1) or 0,
		tonumber(slot2) or 0,
		tonumber(slot3) or 0,
		tonumber(slot4) or 0,
		tonumber(uniq) or 0,
		name, itype
end

--[[
function IlarosFarm.Util.GetMenuName(inputName, specificType)
	local name, info
	if (inputName) then
		local firstLetter = string.sub(inputName, 1, 2)
		local carReplace = {
			["à"] = "a", ["á"] = "a", ["â"] = "a", ["ä"] = "a", ["ã"] = "a",
			["è"] = "e", ["é"] = "e", ["ê"] = "e", ["ë"] = "e",
			["ì"] = "i", ["í"] = "i", ["î"] = "i", ["ï"] = "i",
			["ò"] = "o", ["ó"] = "o", ["ô"] = "o", ["ö"] = "o", ["õ"] = "o",
			["ù"] = "u", ["ú"] = "u", ["û"] = "u", ["ü"] = "u"
		}

		local found
		for code, repl in pairs(carReplace) do
			firstLetter, found = string.gsub(firstLetter, code, repl)
			if (found > 0) then
				break
			end
		end
		if (found > 0) then
			name = string.upper(firstLetter)..(string.sub(inputName, 3) or "")
		else
			name = string.upper(string.sub(inputName, 1, 1))..(string.sub(inputName, 2) or "")
		end

		if not ( specificType ) then
			specificType = IlarosFarm_GetDB_IconByFarmName(inputName)
		end
		specificType = specificType or inputName
		if (Farm_SkillLevel[specificType]) then
			name = name.." ["..Farm_SkillLevel[specificType].."]"
		end
	end
	return name, info
end
]]

function IlarosFarm.Util.DumpAll()
	local farmCont, farmZone, farmName, contData, zoneData, nameData, farmPos, farmItem

	for _, continent in IlarosFarm.Storage.GetAreaIndices() do --continents
		for _, zone in IlarosFarm.Storage.GetAreaIndices(continent) do
			for farmName, gtype in IlarosFarm.Storage.ZoneFarmNames(continent, zone) do
				for index, x, y, count in IlarosFarm.Storage.ZoneFarmNodes(continent, zone, farmName) do
					IlarosFarm.Util.Print(gtype.." "..farmName.." was found in zone "..continent..":"..zone.." at "..x..","..y.."  ("..count.." times)")
				end
			end
		end
	end
end

function IlarosFarm.Util.ChatPrint(str)
	if ( DEFAULT_CHAT_FRAME ) then
		DEFAULT_CHAT_FRAME:AddMessage(str, 1.0, 0.5, 0.25)
	end
end

function IlarosFarm.Util.Print(str, add)
	if ((IlarosFarm.Var.LastPrited) and (str == IlarosFarm.Var.LastPrited)) then
		return
	end
	IlarosFarm.Var.LastPrited = str
	if (add) then
		str = str..": "..add
	end
	if(ChatFrame2) then
		ChatFrame2:AddMessage(str, 1.0, 1.0, 0.0)
	end
end

function IlarosFarm.Util.Debug(str, ...)
	if not ( type(IlarosFarm.Util.DebugFrame) == "table" and IlarosFarm.Util.DebugFrame.AddMessage ) then
		return
	end
	str = str..": "..strjoin(", ", tostringall(...))
	IlarosFarm.Util.DebugFrame:AddMessage("DEBUG: "..str, 1.0, 1.0, 0.0)
end

--[[
function IlarosFarm.Util.TitleCase(str)
	if (GetLocale() == "frFR") then return str; end
	
	local function ucaseWord(first, rest)
		return string.upper(first)..string.lower(rest)
	end
	return string.gsub(str, "([a-zA-Z])([a-zA-Z']*)", ucaseWord)
end

function IlarosFarm.Util.MakeName(frameID)
	local tmpClosest = IlarosFarm.Var.Closest
	local tmpItemIDtable = { }
	local tmpCount = 1
	if ( IlarosFarm.Var.Loaded ) then
		local farmInfo = tmpClosest.items[frameID]

		tmpItemIDtable[tmpCount] = {}
		tmpItemIDtable[tmpCount].name  = IlarosFarm.Util.GetMenuName(farmInfo.name)
		tmpItemIDtable[tmpCount].count = farmInfo.item.count
		tmpItemIDtable[tmpCount].dist  = math.floor(farmInfo.dist*10000)/10

		tmpCount = tmpCount + 1

		for id in pairs(tmpClosest.items) do
			if (id ~= frameID and
					(abs(farmInfo.item.x - tmpClosest.items[id].item.x) <= IlarosFarm.Var.ClosestCheck or
				 IlarosFarm.Util.Round(farmInfo.item.x * 10) == IlarosFarm.Util.Round(tmpClosest.items[id].item.x * 10)) and
				(abs(farmInfo.item.y - tmpClosest.items[id].item.y) <= IlarosFarm.Var.ClosestCheck or
				 IlarosFarm.Util.Round(farmInfo.item.y * 10) == IlarosFarm.Util.Round(tmpClosest.items[id].item.y * 10))) then
				tmpItemIDtable[tmpCount] = {}
				tmpItemIDtable[tmpCount].name  = IlarosFarm.Util.GetMenuName(tmpClosest.items[id].name)
				tmpItemIDtable[tmpCount].count = tmpClosest.items[id].item.count
				tmpItemIDtable[tmpCount].dist  = math.floor(tmpClosest.items[id].dist*10000)/10

				tmpCount = tmpCount + 1
			end
		end
	else
		tmpItemIDtable[1].name = "Unknown"
		tmpItemIDtable[1].count = 0
		tmpItemIDtable[1].dist = 0
	end

	return tmpItemIDtable
end
]]

local _, _, _, tocVersion = GetBuildInfo();

if ( tocVersion >= 40000 ) then


function IlarosFarm.Util.GetSkills()
	local ProfessionTextures = IlarosFarm.Constants.ProfessionTextures;
	
	for _, profId in pairs({GetProfessions()}) do
		local name, texture, skillRank, maxRank = GetProfessionInfo(profId);
		if ( ProfessionTextures[texture] ) then
			IlarosFarm.Var.Skills[ProfessionTextures[texture]] = skillRank;
		end
	end
end


else


local checkingSkills = false

function IlarosFarm.Util.GetSkills()
	if ( checkingSkills ) then return end -- avoid infinate loops
	checkingSkills = true
	local FarmExpandedHeaders = {}
	local i, j
	
	if ( not IlarosFarm.Var.Skills ) then IlarosFarm.Var.Skills = {}; end
		
	-- search the skill tree for farming skills
	for i=0, GetNumSkillLines(), 1 do
		local skillName, header, isExpanded, skillRank = GetSkillLineInfo(i)
	
		-- expand the header if necessary
		if ( header and not isExpanded ) then
			FarmExpandedHeaders[i] = skillName
		end
	end
	
	ExpandSkillHeader(0)
	for i=1, GetNumSkillLines(), 1 do
		local skillName, header, _, skillRank = GetSkillLineInfo(i)
		-- check for the skill name
		if (skillName and not header) then
			if (skillName == FarmText_SKL["HERB"]) then
				IlarosFarm.Var.Skills.HERB = skillRank
			elseif (skillName == FarmText_SKL["MINE"]) then
				IlarosFarm.Var.Skills.MINE = skillRank
			elseif (skillName == FarmText_SKL["FISH"]) then
				IlarosFarm.Var.Skills.FISH = skillRank
			end
		end
		
		-- once we got all, no need to look the rest
		if ( IlarosFarm.Var.Skills.HERB and IlarosFarm.Var.Skills.MINE and IlarosFarm.Var.Skills.FISH ) then
			break
		end
	end
	
	-- close headers expanded during search process
	for i=0, GetNumSkillLines() do
		local skillName, header, isExpanded = GetSkillLineInfo(i)
		for j in pairs(FarmExpandedHeaders) do
			if ( header and skillName == FarmExpandedHeaders[j] ) then
				CollapseSkillHeader(i)
				FarmExpandedHeaders[j] = nil
			end
		end
	end
	checkingSkills = false
end


end

--******************************************************
-- Current Tracking State Tracker System
--******************************************************

local currentTracks = {};

function IlarosFarm.Util.UpdateTrackingState()
	local TrackingTextures = IlarosFarm.Constants.TrackingTextures;
	for id = 1, GetNumTrackingTypes() do
		local name, texture, active, category  = GetTrackingInfo(id);
		if ( TrackingTextures[texture] ) then
			currentTracks[TrackingTextures[texture]] = active and true or false
		end
	end
end

function IlarosFarm.Util.IsNodeTracked( nodeId )
	local trackType = IlarosFarm.Nodes.Objects[nodeId]
	
	-- check for a tracking type override
	local category = IlarosFarm.Categories.ObjectCategories[nodeId]
	trackType = IlarosFarm.Constants.TrackingOverrides[category] or trackType
	
	return currentTracks[trackType]
end

--******************************************************
-- END Current Tracking State Tracker System
--******************************************************

local nodeNames = {}
for name, objid in pairs(IlarosFarm.Nodes.Names) do
	nodeNames[objid] = name
end
function IlarosFarm.Util.GetNodeName(objectID)
	return IlarosFarm.Categories.CategoryNames[objectID] or nodeNames[objectID] or ("Unknown: "..objectID)
end

function IlarosFarm.Util.BuildLoot(coins, ...)
	local loot = {}
	coins = tonumber(coins) or 0
	for i=1, select("#", ...) do
		local lootItem = select(i, ...)
		local itemID, count = strsplit("x", lootItem)
		itemID = tonumber(itemID)
		count = tonumber(count)
		if (itemID and count) then
			table.insert(loot, { id = itemID, count = count })
		end
	end
	return coins, loot
end

function IlarosFarm.Util.LootSplit(lootString)
	return IlarosFarm.Util.BuildLoot(strsplit(":", lootString))
end

local parseStrings = {}
local parseStringInfo = {}
local returnCache = {}

local function processMatches( format, ... )
	local parseInfo = parseStringInfo[format]
	for i = 1, select("#", ...) do
		if ( parseInfo[i] ) then
			returnCache[i] = select(parseInfo[i], ...)
		else
			returnCache[i] = ""
		end
	end
	return unpack(returnCache, 1, select("#", ...))
end

local function replaceAllBut( char )
	if ( char ~= "$" and char ~= "%" ) then
		return "%"..char
	end
end

function IlarosFarm.Util.ParseFormattedMessage(format, message)
	local parser = parseStrings[format]
	if not ( parser ) then
		parser = string.gsub(format, "([%p])", replaceAllBut)
		local parseInfo = {}
		local curPos = 0
		local count = 0
		local function analyzeMatch( index, check, type )
			if ( #index > 1 ) then return end
			index = tonumber(index)
			if ( index ) then
				curPos = index
				if ( check ~= "$" ) then
					return
				end
			else
				curPos = curPos + 1
			end
			local replacement
			if ( type == "s" ) then
				replacement = "(.-)"
			elseif ( type == "d" ) then
				replacement = "(-?%d+)"
			else
				return
			end
			count = count + 1
			parseInfo[curPos] = count
			return replacement
		end
		parser = string.gsub(parser, "%%(%d?)(%$?)([sd])", analyzeMatch)
		parseStringInfo[format] = parseInfo
		parser = string.gsub(parser, "%$", "%%$")
		parser = "^"..parser.."$"
		parseStrings[format] = parser
	end
	return processMatches(format, string.match(message, parser))
end

function IlarosFarm.Util.GetNodeTexture( nodeID )
	local selectedTexture
	local trimTexture = false
	
	if (IlarosFarm.Icons[nodeID]) then
		selectedTexture = "Interface\\AddOns\\IlarosFarm\\images\\"..IlarosFarm.Icons[nodeID]
	end
	
	if not ( selectedTexture ) then
		selectedTexture = GetItemIcon(IlarosFarm.Nodes.PrimaryItems[nodeID])
		trimTexture = selectedTexture and true or false
	end
	
	if not ( selectedTexture ) then
		local prime, pcount = IlarosFarm.DropRates.GetPrimaryItem(nodeID)
		if ( prime ) then
			local primaryName, _, _, _, _, _, _, _, _, nodeTexture = GetItemInfo(prime)
			selectedTexture = nodeTexture
			trimTexture = true
		end
	end
	
	-- Check to see if we found the item
	if (not selectedTexture) then
		selectedTexture = "Interface\\AddOns\\IlarosFarm\\images\\red"
		trimTexture = false
	end
	
	return selectedTexture, trimTexture
end

IlarosFarm.Util.ZoneNames = {GetMapContinents()}
for index, cname in pairs(IlarosFarm.Util.ZoneNames) do
	local zones = {GetMapZones(index)}
	IlarosFarm.Util.ZoneNames[index] = zones
	for index, name in ipairs(zones) do
		zones[name] = index
	end
	zones[0] = cname
end

function IlarosFarm.Util.GetPositionInCurrentZone()
	local realZoneText = GetRealZoneText()
	local continent, zone
	local c, z, px, py
	for cont, zones in pairs(IlarosFarm.Util.ZoneNames) do
		zone = zones[realZoneText]
		if ( zone ) then
			continent = cont
			break
		end
	end
	-- if there is no zone map named for the realZoneText then search by
	-- changing the current map zoom
	if not ( zone ) then
		return Astrolabe:GetCurrentPlayerPosition()
	else
		c, z, px, py = Astrolabe:GetCurrentPlayerPosition()
	end
	if not ( c and z ) then
		return
	end
	-- translate coordiantes to current zone map
	px, py = Astrolabe:TranslateWorldMapPosition(c, z, px, py, continent, zone)
	return continent, zone, px, py
end


function IlarosFarm.Util.SecondsToTime(seconds, noSeconds)
	local time = ""
	local count = 0
	seconds = floor(seconds)
	if ( seconds >= 604800 ) then
		local tempTime = floor(seconds / 604800)
		time = time..tempTime.." "..((tempTime==1) and FarmText_TStrW1 or FarmText_TStrW2).." "
		seconds = (seconds % 604800)
		count = count + 1
	end
	if ( seconds >= 86400  ) then
		local tempTime = floor(seconds / 86400)
		time = time..tempTime.." "..((tempTime==1) and FarmText_TStrD1 or FarmText_TStrD2).." "
		seconds = (seconds % 86400)
		count = count + 1
	end
	if ( count < 2 and seconds >= 3600  ) then
		local tempTime = floor(seconds / 3600)
		time = time..tempTime.." "..((tempTime==1) and FarmText_TStrH1 or FarmText_TStrH2).." "
		seconds = (seconds % 3600)
		count = count + 1
	end
	if ( count < 2 and seconds >= 60  ) then
		local tempTime = floor(seconds / 60)
		time = time..tempTime.." "..((tempTime==1) and FarmText_TStrM1 or FarmText_TStrM2).." "
		seconds = (seconds % 60)
		count = count + 1
	end
	if ( count < 2 and seconds > 0 and not noSeconds ) then
        time = time..seconds.." "..((seconds==1) and FarmText_TStrS1 or FarmText_TStrS2).." "
	end
	return time
end


--******************************************************
-- Client Item Cache Refresh System
--******************************************************

local refreshFrame = CreateFrame("Frame")
local tooltip = CreateFrame("GameTooltip")
refreshFrame:Hide()
local itemIdList = {}
local lastItem = nil
local timer = 0


function IlarosFarm.Util.StartClientItemCacheRefresh()
	for cont, contData in ipairs(IlarosFarm.DropRates.Data) do
		for zone, zoneData in pairs(contData) do
			for nodeId, nodeData in pairs(zoneData) do
				for itemId in pairs(nodeData) do
					if ( type(itemId) == "number" ) then
						itemIdList[itemId] = true
					end
				end
			end
		end
	end
	
	lastItem = nil
	timer = 0
	refreshFrame:Show()
end

refreshFrame:SetScript("OnUpdate",
	function( self, elapsed )
		timer = timer + elapsed
		if ( timer > 5 ) then
			timer = 0
			local itemId = next(itemIdList, lastItem)
			if not ( itemId ) then
				self:Hide()
				return
			end
			
			while ( itemId and GetItemInfo(itemId) ) do
				itemId = next(itemIdList, itemId)
			end
			if not ( itemId ) then
				self:Hide()
				return
			end
			tooltip:SetOwner(refreshFrame, "ANCHOR_NONE")
			tooltip:SetHyperlink("item:"..itemId..":0:0:0:0:0:0:0")
			lastItem = itemId
		end
	end
)
