----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für Datenbank-Konvertierung
----------------------------------------------------------------------------

local metatable = { __index = getfenv(0) }
setmetatable( IlarosFarm.Convert, metatable )
setfenv(1, IlarosFarm.Convert)

local type = type
local ipairs = ipairs
local pairs = pairs
local _G = _G


local nodeLevel, mappingData, typeConverstionData
local traversalData = {}
local MergeNode

local nodeData = {}
local function extractNodeInformation()
	for index, mapping in ipairs(mappingData) do
		if ( mapping.type == "key" ) then
			nodeData[index] = traversalData[mapping.level].key
		elseif ( mapping.type == "value" ) then
			nodeData[index] = traversalData[mapping.level].data[mapping.key]
		else
			--ERROR
			return
		end
	end
	for index, data in ipairs(nodeData) do
		local typeInfo = typeConverstionData[index]
		local dataType = type(data)
		if ( typeInfo ) then
			if ( type(typeInfo) == "string" ) then
				if ( dataType ~= typeInfo ) then
					data = nil; --Invalid Type, set to nil
				end
			elseif ( type(typeInfo) == "table" ) then
				local conversionInfo = typeInfo[dataType]
				if ( (dataType == "string") and not (typeInfo.caseSensitive) ) then
					data = string.lower(data)
				end
				if ( conversionInfo ) then
					if ( type(conversionInfo) == "table" ) then
						data = conversionInfo[data]
					elseif ( type(conversionInfo) == "function" ) then
						data = conversionInfo(data, nodeData)
					elseif ( type(conversionInfo) == "string" ) then
						data = _G[conversionInfo](data, nodeData)
					end
				else
					data = nil; --Invalid Type, set to nil
				end
			else
				--BAD MERGE DEFINITION!
			end
		else
			data = nil; --no type or conversion information
		end
		nodeData[index] = data
	end
	local result, err = pcall(MergeNode, unpack(nodeData, 1, 10))
	if not ( result ) then
		IlarosFarm.Util.Debug("MergeNode error", err, "Data: ("..strjoin(", ", tostringall(unpack(nodeData, 1, 10)))..")")
	end
end

local function iterateOnLevel( level )
	if ( level < 1 or level > nodeLevel ) then return level end --Invalid Level!
	
	if ( level == nodeLevel ) then
		extractNodeInformation()
	else
		for key, data in pairs(traversalData[level].data) do
			if ( type(data) == "table" ) then
				local newLevel = level + 1
				traversalData[newLevel].key = key
				traversalData[newLevel].data = data
				iterateOnLevel(newLevel)
			end
		end
	end
end


function ImportDatabase( dataToImport, nodeMergeFunction )
	local converInfo = ConversionInformation[3]
	if ( converInfo ) then
		nodeLevel = converInfo.nodeLevel
		mappingData = converInfo.mappingData
		typeConverstionData = converInfo.typeConverstionData
		MergeNode = nodeMergeFunction
		for i = 1, nodeLevel do
			if not ( traversalData[i] ) then
				traversalData[i] = {}
			end
		end
		for key, data in pairs(dataToImport) do
			if ( type(data) == "table" ) then
				traversalData[1].data = data
				traversalData[1].key = key
				iterateOnLevel(1)
			end
		end
	end
end

local zoneSizeShiftFunctions = {
	["3.0-Shift"] = {
		convertXAxis = (
			function ( data, nodeData )
				local continent = nodeData[3]
				if ( continent == 2 ) then
					local zoneToken = IlarosFarm.ZoneTokens.GetZoneToken(continent, nodeData[4])
					if ( zoneToken == "EASTERN_PLAGUELANDS" ) then
						data = (data - 0.026372737507017) * 0.96020671188279
					elseif ( zoneToken == "STORMWIND" ) then
						data = (data - -0.25437145166642) * 0.77368159521222
					end
				end
				return data
			end
		),
		convertYAxis = (
			function( data, nodeData )
				local continent = nodeData[3]
				if ( continent == 2 ) then
					local zoneToken = IlarosFarm.ZoneTokens.GetZoneToken(continent, nodeData[4])
					if ( zoneToken == "EASTERN_PLAGUELANDS" ) then
						data = (data - 0.03712658084068) * 0.96046508864265
					elseif ( zoneToken == "STORMWIND" ) then
						data = (data - -0.31574041623418) * 0.77383347432012
					end
				end
				return data
			end
		),
	}
}

ConversionInformation = {
	--MergeNode argument mapping table for DB version 3 to MergeNode function arguments
	[3] = {
		nodeLevel = 4,
		mappingData = {
			[1] = { type="key", level=3, }, --farmName
			[2] = { type="value", level=3, key="gtype" }, --farmType
			[3] = { type="key", level=1, }, --continent
			[4] = { type="key", level=2, }, --zone
			[5] = { type="value", level=4, key=1, }, --x
			[6] = { type="value", level=4, key=2, }, --y
			[7] = { type="value", level=4, key=3, }, --count
			[8] = { type="value", level=4, key=4, }, --harvested
			[9] = { type="value", level=4, key=5, }, --inspected
			[10] = { type="value", level=4, key=6, }, --source
		},
		typeConverstionData = {
			[1] = {
				string = (
					function( data )
						for k, v in pairs(IlarosFarm.Nodes.Names) do
							if ( strlower(k) == strlower(data) ) then
								return v
							end
						end
						--stick with the name if we don't have an id for it yet
						return data
					end
				),
				number = (
					function( data )
						return data
					end
				),
			},
			[2] = "string",
			[3] = "number",
			[4] = "string",
			[5] = "number",
			[6] = "number",
			[7] = "number",
			[8] = "number",
			[9] = "number",
			[10] = "string",
		},
	},
}


function debug( msg )
	ChatFrame5:AddMessage(msg)
end

-- reference to the Astrolabe mapping library
local Astrolabe = DongleStub(IlarosFarm.AstrolabeVersion)

--[[
For non-english locales in which map name translations, the zone tables must be 
renumbered for the new zone order, resulting from the new translations, before 
the Burning Crusade zones can be inserted into the old database table.  

The following table and conversion function checks if such a shift in ordering is 
required and then re-orders the database as needed.  
]]

WoW_2_Client_Translations = {
	["deDE"] = {
		{ 9,1,2,3,4,6,7,10,8,12,13,14,15,16,17,18,19,20,5,11,21 }, 
		{ 1,2,3,4,5,7,8,6,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25 }, 
	},
}

function ConvertDBForNewTranslations( database ) 
	if not ( WoW_2_Client_Translations[GetLocale()] ) then 
		return 
	end 
	 
	for continent, shiftData in pairs(WoW_2_Client_Translations[GetLocale()]) do 
		local cData = database[continent] 
		if ( cData ) then 
			local newContinentData = {} 
			for oldIndex, newIndex in pairs(shiftData) do 
				newContinentData[newIndex] = cData[oldIndex] 
			end 
			database[continent] = newContinentData 
		end 
	end 
end 
