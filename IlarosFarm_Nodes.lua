----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für Häufigkeitsfenster
----------------------------------------------------------------------------

IlarosFarm.NodeSearch = {}
local public = IlarosFarm.NodeSearch
local private = {}

function public.Show()
	private.frame:Show()
end

function public.Hide()
	private.frame:Hide()
end

function public.Toggle()
	if (private.frame:IsShown()) then
		public.Hide()
	else
		public.Show()
	end
end

private.frame = CreateFrame("Frame", nil, UIParent)
local frame = private.frame

frame:SetBackdrop({
        bgFile = "Interface/Tooltips/ChatBubble-Background",
        edgeFile = "Interface/Tooltips/ChatBubble-BackDrop",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 32, right = 32, top = 32, bottom = 32 }
})
frame:SetBackdropColor(0,0,0, 1)

frame:SetPoint("CENTER", UIParent, "CENTER")
frame:SetWidth(450)
frame:SetHeight(450)

frame:SetMovable(true)
frame:EnableMouse(true)
frame:Hide()

frame.Drag = CreateFrame("Button", nil, frame)
frame.Drag:SetPoint("TOPLEFT", frame, "TOPLEFT", 10,-5)
frame.Drag:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10,-5)
frame.Drag:SetHeight(6)
frame.Drag:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")

frame.Drag:SetScript("OnMouseDown", function() frame:StartMoving() end)
frame.Drag:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)

frame.DragBottom = CreateFrame("Button",nil, frame)
frame.DragBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10,5)
frame.DragBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10,5)
frame.DragBottom:SetHeight(6)
frame.DragBottom:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")

frame.DragBottom:SetScript("OnMouseDown", function() frame:StartMoving() end)
frame.DragBottom:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)

--Hide frame
frame.Done = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
frame.Done:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
frame.Done:SetScript("OnClick", function() public.Hide() end)
frame.Done:SetText(DONE)

--Display Farming Report
frame.FarmingReport = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
frame.FarmingReport:SetWidth(150)
frame.FarmingReport:SetPoint("BOTTOM", frame, "BOTTOM", -142, 10)
frame.FarmingReport:SetScript("OnClick", function() frame:Hide() IlarosFarm.Report.Show() end)
frame.FarmingReport:SetText(FarmText_DLG6)

--Display Configuration
frame.Config = CreateFrame("Button", "", frame, "OptionsButtonTemplate")
frame.Config:SetPoint("BOTTOM", frame, "BOTTOM", -20, 10)
frame.Config:SetScript("OnClick", function() frame:Hide() IlarosFarm.Config.ShowOptions() end)
frame.Config:SetText(FarmText_BtnK)

--Add Title to the Top
frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frame.title:SetPoint("CENTER", frame, "TOP", 0, -20)
frame.title:SetText(FarmText_DLG5)

local SelectBox = LibStub:GetLibrary("SelectBox")
local ScrollSheet = LibStub:GetLibrary("ScrollSheet")

--Search box
frame.searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
frame.searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -60)
frame.searchBox:SetAutoFocus(false)
frame.searchBox:SetHeight(15)
frame.searchBox:SetWidth(150)
frame.searchBox:SetScript("OnEnterPressed", function() private.startSearch(_, _, frame.searchBox:GetText() ) end)

--Search Button
frame.searchButton = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
frame.searchButton:SetPoint("TOPLEFT", frame.searchBox, "BOTTOMLEFT", -6, -1)
frame.searchButton:SetText(FarmText_BtnS)
frame.searchButton:SetScript("OnClick", function() private.startSearch(_, _, frame.searchBox:GetText() ) end)

--Select Box, used to choose which Continent Stats come from
frame.SelectBoxSetting = {FarmText_sALL, FarmText_sALL}
function private.ChangeControls(obj, arg1,arg2,...)
	frame.SelectBoxSetting = {arg1, arg2}
end

-- Use a callback to generate the list of continents, so that the call
-- to GetMapContinents is deferred until it is defined. Also establish
-- the maximum continent index here
local continents
local maxCont
local function vals()
	if not continents then
		continents = {GetMapContinents()}
		maxCont = table.maxn(continents)
	end
	local items = {
		{FarmText_sALL, FarmText_cALL},
	}
	for n, text in ipairs(continents) do
		table.insert(items, {n, text})
	end
	return items
end

frame.selectbox = CreateFrame("Frame", "IlarosFarmNodeSearchBox", frame)
frame.selectbox.box = SelectBox:Create("IlarosFarmNodeSearchBox", frame.selectbox, 120, private.ChangeControls, vals, "default")
frame.selectbox.box:SetPoint("TOPLEFT", frame, "TOPLEFT", 180,-56)
frame.selectbox.box.element = "selectBox"
frame.selectbox.box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.selectbox.box:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0,-90)
frame.selectbox.box:SetText(FarmText_cALL)

--Create Scrollframe
frame.resultlist = CreateFrame("Frame", nil, frame)
frame.resultlist:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
})

frame.resultlist:SetBackdropColor(1, 0, 0, 0.5)
frame.resultlist:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 350)
frame.resultlist:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -5, 0)
frame.resultlist:SetPoint("BOTTOM", frame, "BOTTOM",0, 38)

--local print = BeanCounter.Print
function private.onEnter(...)
--print(...)
end
function private.onLeave(...)
--print(...)
end
function private.onMouseover(...)
--print(...)
end
function private.onClick(...)
--print(...)
end
function private.onResize(...)
--print(...)
end
function private.onSelect(...)
--print(...)
end

frame.resultlist.sheet = ScrollSheet:Create(frame.resultlist, {
		{ FarmText_LST2, "TEXT",  123},
		{ FarmText_LST1, "TEXT",  137},
		{ FarmText_LST5, "NUMBER",  67},
		{ FarmText_LST6, "NUMBER",  67},


	},private.onEnter, private.onLeave, private.onClick, private.onResize, private.onSelect)

--[[GLOBAL Zone Name == IlarosFarm.ZoneTokens.GetZoneToken(continent, zone)
--NODE Name to ID table    IlarosFarm.Nodes.Names
--Actual Localized Zone Names  IlarosFarm.Util.ZoneNames[continent][zone]

--Get node type IlarosFarm.Nodes.Objects[  id ]

-- Returns the count of nodes for each farm type in the zone specified
public.GetNodeCountsByFarmType( continent, zone )

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
public.GetNodeInfo( continent, zone, farmName, index )

]]
local Data = {}
function private.getZonesWithNodes(start, finish, farmName)
	--Scan zones and add zones matching the nodes to the table
	for continent = start, finish do
		for _, zone in IlarosFarm.Storage.GetAreaIndices(continent) do
			if IlarosFarm.Storage.IsFarmInZone( continent, zone, farmName ) then
				local nodes = IlarosFarm.Storage.GetFarmCountsForZone( continent, zone, farmName )
				local totalAll = IlarosFarm.Storage.GetNodeCounts( continent, zone )
				local treasures, herbs, ores, fish = IlarosFarm.Storage.GetNodeCountsByFarmType( continent, zone )
				local type = IlarosFarm.Nodes.Objects[farmName]
				table.insert(Data, {["continent"] = continent, ["zone"] = zone, ["farmName"] = farmName, ["nodes"] = nodes, ["totalAll"] = totalAll, ["FISH"] = fish, ["HERB"] = herbs, ["MINE"] = ores, ["OPEN"] = treasures, ["type"] = type})
			end
		end
	end
end

function private.startSearch(start, finish, name)
	--allow user to filter continents searched
	if frame.SelectBoxSetting[2] == FarmText_sALL then
		if not maxCont then vals() end --Since we do not define maxCont unless select box has been changed
		start, finish = 1, maxCont
	else
		start, finish = frame.SelectBoxSetting[2], frame.SelectBoxSetting[2]
	end
	--find matching node ID's for entered string, send all to be searched
	for text, farmName in pairs(IlarosFarm.Nodes.Names) do
		if text:lower():match(name:lower()) then
			private.getZonesWithNodes(start, finish, farmName)
		end
	end
	--What type of data did the user want returned
	private.nodesByPercent()
end
function private.nodesByPercent()
	--take results of search and prep for sending to scrollframe
	local data = {}
	for i,v in pairs( Data ) do
		local nodes = v.nodes
		local total = v[v.type] -- We store the type as HERB, MINE, FISH, OPEN and can then use it here to refrence Data.HERB Data.OPEN etc..
		local pct =  floor(nodes*100/total + 0.5)

		table.insert(data, {IlarosFarm.Util.ZoneNames[v.continent][v.zone], IlarosFarm.Util.GetNodeName(v.farmName), nodes, pct,} )
	end
	Data = {} --clear data for next round of searches
	frame.resultlist.sheet:SetData(data, style)
end
