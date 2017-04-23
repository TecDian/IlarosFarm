----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für die Fund-Datenbank-Verwaltung
----------------------------------------------------------------------------

--------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------
-- Node Indexing
local POS_X = 1
local POS_Y = 2
local COUNT = 3
local HARVESTED = 4
local INSPECTED = 5
local SOURCE = 6

--------------------------------------------------------------------------
-- Data Table
--------------------------------------------------------------------------

local globalName = "FarmMarks"
local data

local corruptData = false

--------------------------------------------------------------------------
-- Global Library Table with a local pointer
--------------------------------------------------------------------------

local lib = IlarosFarm.Storage

-- reference to the Astrolabe mapping library
local Astrolabe = DongleStub(IlarosFarm.AstrolabeVersion)

local ZoneData = {}
local continents = {GetMapContinents()}
for index, name in ipairs(continents) do
    ZoneData[index] = {GetMapZones(index)}
    ZoneData[index].name = name
end

--[[
##########################################################################
 Regular Library Functions
##########################################################################
--]]

--************************************************************************
-- This returns the raw data table, BE CAREFUL WITH IT!!!!
--************************************************************************
--[[
function lib.GetRawDataTable()
    return data
end
--]]

local function processSourceList( newSource, ... )
    for i = 1, select("#", ...) do
        if ( newSource == select(i, ...) ) then
            return ...
        end
    end
    return ..., newSource
end

local validFarmTypes = {
    MINE = "MINE",
    HERB = "HERB",
    FISH = "FISH",
    OPEN = "OPEN",
}
function lib.AddNode(nodeName, farmType, continent, zone, farmX, farmY, source, incrementCount)
    if not (continent and zone and farmX and farmY) then return end
    local zoneToken = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    zone = IlarosFarm.ZoneTokens.GetZoneIndex(continent, zone)
    -- check for invalid location information

    -- ccox - we should handle negative X and Y
    -- Swamp of Sorrows has stranglekelp at a negative Y position (northeast corner, off in the water)
    if not ( (continent > 0) and zoneToken and (farmX > 0) and (farmY > 0) ) then return end

    local farmType = validFarmTypes[farmType]

    if not (data[continent]) then data[continent] = { }; end
    if not (data[continent][zoneToken]) then data[continent][zoneToken] = { }; end
    if not (data[continent][zoneToken][nodeName]) then data[continent][zoneToken][nodeName] = { gtype = farmType }; end
    local farmTable = data[continent][zoneToken][nodeName]

    if not ( farmType ) then
        farmType = IlarosFarm.Nodes.Objects[nodeName]
    end
    if not ( farmTable.gtype ) then
        farmTable.gtype = farmType
    end

    local matchDist = 10
    local isImport = false
    if source and source:sub(1,3) == "DB:" then
        -- DB sources have a tendancy to be more "fuzzy" than
        -- actual harvested nodes, so look farther for a match
        matchDist = 25
        isImport = true
    elseif source == "REQUIRE" then
        -- REQUIRE nodes can be harvested a little farther away
        -- than a directly harvested node, so search a little
        -- bit more for a match
        matchDist = 15
    end

    local index, node

    -- zuerst schauen, ob es einen passenden Fischschwarm in der Nähe gibt
    if (farmType == "FISH") and data[continent][zoneToken][IlarosFarm.Nodes.Pools[nodeName]] then
        local poolTable = data[continent][zoneToken][IlarosFarm.Nodes.Pools[nodeName]]
        for i, farmData in ipairs(poolTable) do
            local dist = Astrolabe:ComputeDistance(continent, zone, farmX, farmY, continent, zone, farmData[POS_X], farmData[POS_Y])
            if ( dist < 15 ) then
                node = farmData
                index = i
                break
            end
        end
    end

    if not node then
        for i, farmData in ipairs(farmTable) do
            local dist = Astrolabe:ComputeDistance(continent, zone, farmX, farmY, continent, zone, farmData[POS_X], farmData[POS_Y])
            if ( dist < matchDist ) then
                node = farmData
                index = i
                break
            end
        end
    end

    -- If we found a close, matching node, then proceed to update it.
    if node then

        -- But don't allow imports to affect real farmed nodes.
        if isImport then return end

        local count = node[COUNT]

        -- Do a proper average of the node position
        farmX = (farmX + (node[POS_X] * count)) / (count + 1)
        farmY = (farmY + (node[POS_Y] * count)) / (count + 1)

        -- Update the node's source field
        local nodeSource = node[SOURCE]
        if ( nodeSource ) then
            -- If we got this node from someone else
            if ( source ) then
                -- If the node is imported, but wasn't or vice versa, clear current source
                if ( (source == "IMPORTED" or nodeSource == "IMPORTED") and nodeSource ~= source ) then
                    node[SOURCE] = nil
                -- If the node is require-level, but wasn't or vice versa, clear current source
                elseif ( (source == "REQUIRE" or nodeSource == "REQUIRE") and nodeSource ~= source ) then
                    node[SOURCE] = nil
                -- Otherwise add the new source to the current source
                else
                    node[SOURCE] = string.join(",", processSourceList(source, string.split(",", nodeSource)))
                end
            -- Else, we have just personally verified the node as correct! Yay us!
            else
                node[SOURCE] = nil
            end
        end

    -- Else, we didn't find it in the current list, time to create a new node!
    else
        node = { [POS_X]=0, [POS_Y]=0, [COUNT]=0, [HARVESTED]=0, [INSPECTED]=0, [SOURCE]=source }
        table.insert(farmTable, node)
        index = table.getn(farmTable)
    end

    node[POS_X] = farmX
    node[POS_Y] = farmY
    if ( incrementCount ) then
        node[COUNT] = node[COUNT] + 1
    end

    local now = time()

    -- Update last harvested time (and inspected time as well)
    node[HARVESTED] = now
    if (not node[SOURCE]) then
        node[INSPECTED] = now
    end

    -- Notify the reporting subsystem that something has changed
    IlarosFarm.Report.NeedsUpdate()

    -- Return the indexed position
    return index
end

--************************************************************************
-- Node Removal
--************************************************************************

function lib.ClearDatabase()
    data = {}
    -- Notify the reporting subsystem that something has changed
    IlarosFarm.Report.NeedsUpdate()
end

local function removeNode( farmData, index, playerName )
    local remove = true
    if ( playerName ) then
        local nodeData = farmData[index]
        if ( nodeData[SOURCE] ) then
            local newSource = (nodeData[SOURCE]..","):gsub(playerName..",", ""):sub(1, -2)
            if ( newSource ~= "" ) then
                -- don't remove the node if source string is not empty after removing the specified name
                remove = false
                nodeData[SOURCE] = newSource
            end

        else  -- don't remove the node if a name was specified, but the node is "confirmed"
            remove = false

        end
    end
    if ( remove ) then
        table.remove(farmData, index)
    end

    -- Notify the reporting subsystem that something has changed
    IlarosFarm.Report.NeedsUpdate()

    return remove
end

-- returns true if the node was removed
function lib.RemoveNode( continent, zone, farmId, index, playerName )
    zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    if ( lib.IsFarmInZone(continent, zone, farmId) ) then
        local farmData = data[continent][zone][farmId]
        if ( farmData[index] ) then
            local result = removeNode(farmData, index, playerName)
            if not ( farmData[1] ) then
                -- if the farm table is now empty, remove it from the DB table
                lib.RemoveFarm(continent, zone, farmId)
            end
            return result
        end
    end
end

-- Returns:
-- -2 if the type did not exist
-- -1 if no nodes were removed
--  0 if the type was removed from the zone
--  1 if some, but not all, of the nodes of the type were removed
function lib.RemoveFarm( continent, zone, farmId, playerName )
    zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    if ( lib.IsFarmInZone(continent, zone, farmId) ) then
        local numRemoved = 0
        if ( playerName ) then
            local farmData = data[continent][zone][farmId]
            local numNodes = #farmData
            for i = numNodes, 1, -1 do
                removeNode(farmData, i, playerName)
            end
            if ( farmData[1] ) then
                if ( numNodes > #farmData ) then
                    return 1, (numNodes - #farmData)
                else
                    return -1, 0
                end
            else
                lib.RemoveFarm(continent, zone, farmId)
                return 0, numNodes
            end

        else
            -- if no name was specified, remove the farm table and check for empty ancestors
            local numFarms = #(data[continent][zone][farmId])
            data[continent][zone][farmId] = nil
            if not ( pairs(data[continent][zone]) ) then
                data[continent][zone] = nil
            end
            if not ( pairs(data[continent]) ) then
                data[continent] = nil
            end
            return 0, numFarms

        end
    end
    return -2, 0
end

--************************************************************************
-- Node Information
--************************************************************************

function lib.HasDataOnZone( continent, zone )
    zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    if ( lib.HasDataOnContinent(continent) and data[continent][zone] ) then
        return true
    else
        return false
    end
end

function lib.HasDataOnContinent( continent )
    if ( data[continent] ) then
        return true
    else
        return false
    end
end

function lib.IsFarmInZone( continent, zone, farmName )
    zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    if ( lib.HasDataOnZone(continent, zone) and data[continent][zone][farmName] ) then
        return true
    else
        return false
    end
end

-- Returns 2 values
-- 1) the number of nodes in a zone
-- 2) the total of the count values for all nodes in the zone
--------------------------------------------------------------------------
function lib.GetNodeCounts( continent, zone )
    zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    local countTotal = 0
    local nodeCount = 0

    if ( data[continent] and data[continent][zone] ) then
        for farm, nodes in pairs(data[continent][zone]) do
            for key, node in pairs(nodes) do
                if ( key ~= "gtype" and key ~= "icon" ) then
                    countTotal = countTotal + node[COUNT]
                    nodeCount = nodeCount + 1
                end
            end
        end
    end
    return nodeCount, countTotal
end



-- Returns the number of nodes of the given type name in the specified zone
--------------------------------------------------------------------------
function lib.GetFarmCountsForZone( continent, zone, farmName )
    zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    if ( data[continent] and data[continent][zone] and data[continent][zone][farmName] ) then
        return table.getn(data[continent][zone][farmName])
    else
        return 0
    end
end


-- Returns the count of nodes for each farm type in the zone specified
-- the return order is
--------------------------------------------------------------------------
local nodeCountsByType = { OPEN=0, HERB=0, MINE=0, FISH=0, unknown=0, }

function lib.GetNodeCountsByFarmType( continent, zone )
    zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    for k, v in pairs(nodeCountsByType) do
        nodeCountsByType[k] = 0
    end

    if ( lib.HasDataOnZone(continent, zone) ) then
        for farm, nodes in pairs(data[continent][zone]) do
            local gtype = nodes.gtype
            if ( nodeCountsByType[gtype] ) then
                nodeCountsByType[gtype] = nodeCountsByType[gtype] + table.getn(nodes)
            else
                nodeCountsByType.unknown = nodeCountsByType.unknown + table.getn(nodes)
            end
        end
    end
    return nodeCountsByType.OPEN,
           nodeCountsByType.HERB,
           nodeCountsByType.MINE,
           nodeCountsByType.FISH,
           nodeCountsByType.unknown
end


-- Returns information on a specific node
--
-- Return Values:
-- x - the node's x coordinate value
-- y - the node's y coordinate value
-- count - the node's count value
-- gtype - farm type of this node
-- lastHarvested - time at which the node was last harvested
-- lastInspected - time at which the node was last inspected
-- source - the source of this node
--------------------------------------------------------------------------
function lib.GetNodeInfo( continent, zone, farmName, index )
    zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    if ( lib.IsFarmInZone(continent, zone, farmName) ) then
        local info = data[continent][zone][farmName][index]
        if ( info ) then
            return info[POS_X],
                   info[POS_Y],
                   info[COUNT],
                   data[continent][zone][farmName].gtype,
                   info[HARVESTED] or 0,
                   info[INSPECTED] or 0,
                   info[SOURCE]
        end
    end
end

function lib.SetNodeInspected( continent, zone, nodeid, index )
    zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    if ( lib.IsFarmInZone(continent, zone, nodeid) ) then
        local node = data[continent][zone][nodeid][index]
        if ( node ) then
            node[INSPECTED] = time()
        end
    end
end

function lib.GetNodeInspected( continent, zone, nodeid, index )
    zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    if ( lib.IsFarmInZone(continent, zone, nodeid) ) then
        local node = data[continent][zone][nodeid][index]
        if ( node ) then
            return node[INSPECTED]
        end
    end
end

function lib.SetNodeBuggedState( continent, zone, farmName, index, bugged )
    zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    if ( lib.IsFarmInZone(continent, zone, farmName) ) then
        local node = data[continent][zone][farmName][index]
        if ( node ) then
            if ( bugged == nil ) then
                if ( node.bugged ) then
                    bugged = nil
                else
                    bugged = true
                end
            end
            node.bugged = true
            return bugged
        end
    end
end


function lib.IsNodeBugged( continent, zone, farmName, index )
    zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    if ( lib.IsFarmInZone(continent, zone, farmName) ) then
        local node = data[continent][zone][farmName][index]
        if ( node ) then
            if ( node.bugged ) then
                return true
            else
                return false
            end
        end
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

local function getWorkTablePair()
    if ( table.getn(workTableCache) < 2 ) then
        table.insert(workTableCache, {})
        table.insert(workTableCache, {})
    end
    local index = table.remove(workTableCache)
    local state = table.remove(workTableCache)
    iteratorStateTables[index] = state
    return index, state
end

local function releaseWorkTablePair( index )
    local data = iteratorStateTables[index]
    if ( data ) then
        iteratorStateTables[index] = nil
        for k, v in pairs(index) do
            index[k] = nil
        end
        for k, v in pairs(data) do
            data[k] = nil
        end
        table.insert(workTableCache, index)
        table.insert(workTableCache, data)
    end
end

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



-- Iterates over the contienent or the zones of a continent and returns
-- the indices for which IlarosFarm has data
--------------------------------------------------------------------------
do --create a new block

    local function iterator( iteratorData, lastIndex )
        if not ( iteratorData and lastIndex ) then return end --not enough information

        lastIndex = lastIndex + 1
        if ( iteratorData[lastIndex] ) then
            return lastIndex, iteratorData[lastIndex]
        else
            releaseWorkTable(iteratorData)
            return; --no data left
        end
    end


    function lib.GetAreaIndices( continent )
        local dataTable

        if ( continent and lib.HasDataOnContinent(continent) ) then
            dataTable = data[continent]
        else
            dataTable = data
        end
        if not ( dataTable ) then return EmptyIterator; end -- no data

        local iteratorData = getWorkTable()
        if ( continent ) then
            local GetZoneIndex = IlarosFarm.ZoneTokens.GetZoneIndex
            for i in pairs(dataTable) do
                if ( lib.HasDataOnZone(continent,i) ) then
                    tinsert(iteratorData, GetZoneIndex(continent, i))
                end
            end
        else
            for i in pairs(dataTable) do
                if (type(i) == "number") and (lib.HasDataOnContinent(i)) then
                    tinsert(iteratorData, i)
                end
            end
        end
        table.sort(iteratorData)
        return iterator, iteratorData, 0
    end

end -- end the block

-- Iterates over the node types in a zone returning data on each type
-- The interator returns the following data on each node
-- farmName - loot name
-- gType - farm type
-- num - number of nodes of that type
--------------------------------------------------------------------------
do --create a new block

    local function iterator( stateIndex, lastFarmName )
        local state = iteratorStateTables[stateIndex]
        if not ( state ) then return end; --no data left

        local farmName, farmNodesTable = next(state.table, lastFarmName)
        if not ( farmName ) then
            releaseWorkTablePair(stateIndex)
            return; --no data left
        end
        local gtype = farmNodesTable.gtype
        return farmName, gtype, table.getn(farmNodesTable)
    end


    function lib.ZoneFarmNames( continent, zone )
        zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
        if ( lib.HasDataOnZone(continent, zone) ) then
            local stateIndex, state = getWorkTablePair()
            state.table = data[continent][zone]

            return iterator, stateIndex, nil
        end
        --safety
        return EmptyIterator
    end

end -- end the block

-- Iterates over the nodes of a specific type in a zone
-- The interator returns the following data on each node
--
-- index - for direct access to this node's information
-- x - the node's x coordinate value
-- y - the node's y coordinate value
-- count - the node's count value
-- harvested - the last time the node was harvested
-- inspected - the last time the node was inspected
-- the node's source
--------------------------------------------------------------------------
do --create a new block

    local function iterator( stateIndex, lastNodeIndex )
        local state = iteratorStateTables[stateIndex]
        if not ( state ) then return end; --no data left

        local nodeIndex, info = state.iterator(state.stateInfo, lastNodeIndex)
        if not ( info ) then
            releaseWorkTablePair(stateIndex)
            return; --no data left
        end
        return nodeIndex, info[POS_X], info[POS_Y], info[COUNT], info[HARVESTED], info[INSPECTED], info[SOURCE]
    end


    function lib.ZoneFarmNodes( continent, zone, farmName )
        zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
        if ( lib.IsFarmInZone(continent, zone, farmName) ) then
            local stateIndex, state = getWorkTablePair()
            state.iterator, state.stateInfo = ipairs(data[continent][zone][farmName])

            return iterator, stateIndex, 0
        end
        --safety
        return EmptyIterator
    end

end -- end the block

-- Closest Nodes
-- Returns an iterator
-- Iterator returns: id, continent, zone, nodeId, nodeIndex, distance
--------------------------------------------------------------------------
do --create a new block

    local function iterator( iteratorData, lastIndex )
        if not ( iteratorData and lastIndex ) then return end --not enough information

        lastIndex = lastIndex + 1
        local nodeIndex = lastIndex * 3
        if ( iteratorData[nodeIndex] ) then
            return lastIndex,
                   iteratorData.continent,
                   iteratorData.zone,
                   iteratorData[nodeIndex - 2],
                   iteratorData[nodeIndex - 1],
                   iteratorData[nodeIndex]
        else
            releaseWorkTable(iteratorData)
            return; --no data left
        end
    end


    -- working tables
    local nodeNames = {}
    local nodeIndex = {}
    local distances = {}

    function lib.ClosestNodes( continent, zone, xPos, yPos, num, maxDist, filter )
        local zoneToken = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
        -- return if the position is invalid or we have no data on the specified zone
        if not ( lib.HasDataOnZone(continent, zone) and xPos > 0 and yPos > 0 ) then
            return EmptyIterator
        end

        local iteratorData = getWorkTable()
        iteratorData.continent = continent
        iteratorData.zone = zone

        if ( type(filter) == "function" ) then
            --do nothing

        elseif ( type(filter) == "table" ) then
            local filterTable = filter
            filter = (
                function( nodeId, farmType )
                    if not ( filterTable[farmType] ) then
                        return false

                    elseif ( filterTable[farmType] == true ) then
                        return true

                    else
                        return filterTable[farmType][nodeId]

                    end
                end
            )

        elseif ( filter == nil or filter ) then
            filter = true

        else
            return EmptyIterator

        end

        for i in ipairs(nodeNames) do
            nodeNames[i] = nil
            nodeIndex[i] = nil
            distances[i] = nil
        end

        local zoneData = data[continent][zoneToken]
        xPos = xPos
        yPos = yPos
        for farmName, nodesList in pairs(zoneData) do
            if ( (filter == true) or filter(farmName, nodesList.gtype) ) then
                for index, nodeData in ipairs(nodesList) do
                    if not ( lib.IsNodeBugged(continent, zone, farmName, index) ) then
                        local nodeX, nodeY = nodeData[POS_X], nodeData[POS_Y]
                        if ( (nodeX ~= 0) and (nodeY ~= 0) ) then
                            local dist = Astrolabe:ComputeDistance(continent, zone, xPos, yPos, continent, zone, nodeX, nodeY)

                            if ( (maxDist == 0) or (dist < maxDist) ) then
                                local insertPoint = 1

                                for i, nodeName in ipairs(nodeNames) do
                                    if not ( distances[i+1] ) then
                                        insertPoint = i + 1
                                        break

                                    elseif ( distances[i] > dist ) then
                                        insertPoint = i
                                        break

                                    end
                                end
                                if ( insertPoint <= num) then
                                    tinsert(nodeNames, insertPoint, farmName)
                                    tinsert(nodeIndex, insertPoint, index)
                                    tinsert(distances, insertPoint, dist)
                                    local limit = num + 1
                                    nodeNames[limit] = nil
                                    nodeIndex[limit] = nil
                                    distances[limit] = nil
                                end
                            end
                        end
                    end
                end
            end
        end

        for i, nodeName in ipairs(nodeNames) do
            local dist = math.floor(distances[i]*100)/100
            tinsert(iteratorData, nodeName)
            tinsert(iteratorData, nodeIndex[i])
            tinsert(iteratorData, dist)
        end

        return iterator, iteratorData, 0
    end

end -- end the block

-- Closest Nodes Info
-- Returns an iterator
-- Iterator returns: id, continent, zone, nodeId, nodeIndex, distance, +GetNodeInfo()
--------------------------------------------------------------------------
do --create a new block

    local function iterator( iteratorData, lastIndex )
        if not ( iteratorData and lastIndex ) then return end --not enough information

        lastIndex = lastIndex + 1
        local nodeIndex = lastIndex * 3
        if ( iteratorData[nodeIndex] ) then
            local continent, zone, nodeName, index, dist = iteratorData.continent, iteratorData.zone, iteratorData[nodeIndex - 2], iteratorData[nodeIndex - 1], iteratorData[nodeIndex]

            return lastIndex, continent, zone, nodeName, index, dist, lib.GetNodeInfo(continent, zone, nodeName, index)
        else
            releaseWorkTable(iteratorData)
            return; --no data left
        end
    end


    function lib.ClosestNodesInfo( continent, zone, xPos, yPos, num, maxDist, filter )
        local f, iteratorData, var = lib.ClosestNodes(continent, zone, xPos, yPos, num, maxDist, filter)

        if ( f == EmptyIterator ) then
            return f
        else
            return iterator, iteratorData, var
        end
    end

end -- end the block


--------------------------------------------------------------------------
-- Event Frame to import/export the data table from/to the global
-- namespace when appropriate
--------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame.UnregisterEvent = function() end

eventFrame:SetScript("OnEvent", function( frame, event, arg1 )
    if ( event == "ADDON_LOADED" and strlower(arg1) == "ilarosfarm" ) then
        local savedData = _G[globalName]
        if ( savedData ) then
            getfenv(0)[globalName] = nil
                    data = savedData

                    local needImport = false
                    local dataToImport = {}

                    -- check for map File names that were used as a zone token and merge them if we now have a token
                    local checkToken = IlarosFarm.ZoneTokens.GetTokenFromFileName
                    for continent, contData in pairs(data) do
                        if ( type(contData) == "table" ) then
                            for zoneToken, zoneData in pairs(contData) do
                                local token = checkToken(continent, zoneToken)
                                if ( token ) then
                                    needImport = true
                                    if not (dataToImport[continent]) then dataToImport[continent] = { }; end
                                    if not (dataToImport[continent][token]) then dataToImport[continent][token] = { }; end
                                    dataToImport[continent][token] = data[continent][zoneToken]
                                    data[continent][zoneToken] = nil
                                end
                            end
                        end
                    end

                    if ( needImport ) then
                        lib.ImportDatabase(dataToImport)
                    end

                    -- check for and remove any deprecated node ids
                    local validObjects = IlarosFarm.Nodes.Objects
                    for continent, contData in pairs(data) do
                        if ( type(contData)=="table" and type(continent)=="number" ) then
                            for zoneToken, zoneData in pairs(contData) do
                                for nodeId in pairs(zoneData) do
                                    if not ( validObjects[nodeId] ) then
                                        zoneData[nodeId] = nil
                                    end
                                end
                            end
                        end
                    end

        else
            lib.ClearDatabase();
        end

    elseif ( event == "PLAYER_LOGOUT" ) then
        -- don't write out the internal table if the user chose to keep a corrupt database
        if not ( corruptData ) then
            getfenv(0)[globalName] = data
        end

    end
end)
eventFrame.SetScript = function() end

local workingTable = {}
local function processImportedSourceField( ... )
    for k in pairs(workingTable) do
        workingTable[k] = nil
    end
    local hasName, imported, require
    for i = 1, select("#", ...) do
        local name = select(i, ...)
        if ( name == "REQUIRE" ) then
            require = true
        elseif ( name == "IMPORTED" ) then
            imported = true
        else
            hasName = true
            workingTable[name] = true
        end
    end
    if ( (hasName and imported) or (hasName and require) or (require and imported) ) then
        return nil
    else
        local nameList = ""
        for name in pairs(workingTable) do
            nameList = nameList..","..name
        end
        return nameList:sub(2)
    end
end

local function MergeNode(farm, farmType, continent, zone, farmX, farmY, count, harvested, inspected, source)
    if not ( farm and farmType and continent and zone and farmX and farmY ) then
        return -- not enough data
    end
    local index = lib.AddNode(farm, farmType, continent, zone, farmX, farmY, (source or "IMPORTED"), false)
    if not ( index ) then return end -- node was not added for some reason, abort
    local zone = IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
    local node = data[continent][zone][farm][index]
    if ( count ) then
        node[COUNT] = node[COUNT] + count
    end
    if ( harvested ) then
        node[HARVESTED] = harvested
    else
        node[HARVESTED] = 0
    end
    if ( inspected ) then
        node[INSPECTED] = inspected
    else
        node[INSPECTED] = 0
    end
    if ( node[SOURCE] and node[SOURCE] ~= "IMPORTED" and node[SOURCE] ~= "REQUIRE" ) then
        node[SOURCE] = processImportedSourceField(string.split(",", node[SOURCE]))
    end
end

function lib.ImportDatabase( database )
    if not ( data ) then
        lib.ClearDatabase();
    end
    IlarosFarm.Convert.ImportDatabase(database, MergeNode)
end
