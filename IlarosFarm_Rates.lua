----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für Fallstatistik
----------------------------------------------------------------------------

function IlarosFarm.DropRates.Load()
	local data = FarmRates
	if ( type(data) ~= "table" ) then
		data = {}
    end
	IlarosFarm.DropRates.Data = data
end

function IlarosFarm.DropRates.Save()
	FarmRates = IlarosFarm.DropRates.Data
end

function IlarosFarm.DropRates.ProcessDrops( objectId, continent, zone, source, coins, loot )
	if not ( loot ) then return end
	local zoneToken = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
	local data = IlarosFarm.DropRates.Data
	
	if not (data[continent]) then data[continent] = { } end
	if not (data[continent][zoneToken]) then data[continent][zoneToken] = { } end
	if not (data[continent][zoneToken][objectId]) then data[continent][zoneToken][objectId] = { total = 0 } end
	data = data[continent][zoneToken][objectId]
	
	local foundItem = false
	for pos, loot in ipairs(loot) do
		local id = loot.id
		if (not id and loot.link) then
			id = IlarosFarm.Util.BreakLink(loot.link)
		end
		if ( id ) then
			local count = loot.count
			if ( count ) then
				data[id] = (data[id] or 0) + count
				foundItem = true
			end
		end
	end
	if ( foundItem ) then
		data.total = data.total + 1
	end
end

local tempData = {}
local function GetDropsTable( objectId, cont, zone )
	local data = IlarosFarm.DropRates.Data
	if ( cont and zone ) then
		zone = IlarosFarm.ZoneTokens.GetZoneToken(cont, zone)
		if ( data and data[cont] and data[cont][zone] and data[cont][zone][objectId] ) then
			return data[cont][zone][objectId]
		end
	else
		for k in pairs(tempData) do
			tempData[k] = nil
		end
		tempData.total = 0
		for _, zones in pairs(data) do
			if ( type(zones) == "table" ) then
				for _, nodes in pairs(zones) do
					for id, node in pairs(nodes) do
						if ( objectId == id ) then
							for item, count in pairs(node) do
								tempData[item] = (tempData[item] or 0) + count
							end
						end
					end
				end
			end
		end
		return tempData
	end
end

function IlarosFarm.DropRates.HasDropsInfo( objectId, cont, zone )
	local data = IlarosFarm.DropRates.GetDropsTotal(objectId, cont, zone)
	return data and (data.total > 0)
end

function IlarosFarm.DropRates.GetDropsTotal( objectId, cont, zone )
	local data = GetDropsTable(objectId, cont, zone)
	if ( data ) then
		return data.total
	end
end

function IlarosFarm.DropRates.GetPrimaryItem( objectId )
	local data = GetDropsTable(objectId)
	if ( data and (data.total > 0) ) then
		local prime = 0
		local pcount = 0
		for item, count in pairs(data) do
			if (item ~= "total" and pcount < count) then
				prime = item
				pcount = count
			end
		end
		return prime, pcount
	end
end


--[[
##########################################################################
 Iterators
##########################################################################
--]]
local EmptyIterator = function() end

local iteratorStateTables = {}
setmetatable(iteratorStateTables, { __mode = "k" }); --weak keys

--------------------------------------------------------------------------
-- iterator work table cache
--------------------------------------------------------------------------

local workTableCache = { {}, {}, {}, {}, }; -- initial size of 4 tables

local function getWorkTable()
	if ( table.getn(workTableCache) < 1 ) then
		table.insert(workTableCache, {})
	end
	local workTable = table.remove(workTableCache)
	iteratorStateTables[workTable] = false
	return workTable
end

local function releaseWorkTable( workTable )
	if ( iteratorStateTables[workTable] == false ) then
		iteratorStateTables[workTable] = nil
		for k, v in pairs(workTable) do
			workTable[k] = nil
		end
		table.insert(workTableCache, workTable)
	end
end


--
--------------------------------------------------------------------------
do --create a new block

	local function iterator( iteratorData, lastIndex )
		if not ( iteratorData and lastIndex ) then return end --not enough information
		
		lastIndex = lastIndex + 1
		local nodeIndex = lastIndex * 2
		if ( iteratorData[nodeIndex] ) then
			return lastIndex,
			       iteratorData[nodeIndex - 1],
			       iteratorData[nodeIndex]
		else
			releaseWorkTable(iteratorData)
			return --no data left
		end
	end
	
	local data
	local function dropRateCompare_DESC( i, j )
		if ( data[i] > data[j] ) then
			return true
		else
			return false
		end
	end
	local function dropRateCompare_ASC( i, j )
		if ( data[i] < data[j] ) then
			return true
		else
			return false
		end
	end
	
	local dropsCache = {}
	
	function IlarosFarm.DropRates.ObjectDrops( objectId, continent, zone, sort )
		data = GetDropsTable(objectId, continent, zone)
		if not ( data and (data.total > 0) ) then
			return EmptyIterator
		end
		
		local iteratorData = getWorkTable()
		if ( sort ) then
			for k in pairs(dropsCache) do
				dropsCache[k] = nil
			end
			for item, count in pairs(data) do
				if (item ~= "total") then
					table.insert(dropsCache, item)
				end
			end
			if ( sort == "ASC" ) then
				table.sort(dropsCache, dropRateCompare_ASC)
			elseif ( sort == "DESC" ) then
				table.sort(dropsCache, dropRateCompare_DESC)
			end
			for i, item in ipairs(dropsCache) do
				tinsert(iteratorData, item)
				tinsert(iteratorData, data[item])
			end
		
		else
			for item, count in pairs(data) do
				if (item ~= "total") then
					tinsert(iteratorData, item)
					tinsert(iteratorData, count)
				end
			end
		
		end
		
		return iterator, iteratorData, 0
	end

end -- end the block