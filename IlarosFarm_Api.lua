----------------------------------------------------------------------------
-- IlarosFarm
-- Modul mit API für andere Addons
----------------------------------------------------------------------------

-- LibSwag.Init() wird aufgerufen, wenn alle anderen Initialisierungen abgeschlossen sind

-- LibSwag.RegisterHook( "name", <<LootFunction>>, <<CastFunction>> ) übermittelt die Funddaten
-- <<CastFunction>> wird bei jeder zauberbasierten Plünderaktion aufgerufen, also nicht beim Angeln und Töten
-- <<LootFunction>> wird am Ende aufgerufen, sobald sich das Plünderfenster öffnet
-- Die übergebenen Parameter sind für beide identisch:
-- <<Function>>(lootType, lootTable, coinAmount, extraData)
--      lootType: "KILL", "FISH", "SKIN", "MINE", "HERB", "OPEN"
--      lootTable: Array von Tabellen aus = { { link = "...", name = "...", count = ... }, ... }
--      (immer nil für <<CastFunction>>)
--      coinAmount: Geld in Kupfer in der Beute (immer nil für <<CastFunction>>)
--      extraData: Tabelle mit beuteabhängigem Format:
--            Für "SKIN", "MINE", "HERB", "OPEN": { tip = "...", time = "..." }
--            Für "KILL": { unit = "...", level = ... }
--            Für "FISH": { nil }

-- Sammelkenndaten
LibSwagData = {}
local log
local myLib = {}

-- Event handler functions
function myLib.OnEvent(event, ...)
	if (event == "LOOT_OPENED") then
		LibSwag.Loot()
	elseif ((event == "UNIT_SPELLCAST_SUCCEEDED") or
			(event == "UNIT_SPELLCAST_FAILED") or
			(event == "UNIT_SPELLCAST_INTERRUPTED") or
			(event == "UNIT_SPELLCAST_SENT")) then
		LibSwag.Spell(event, ...)
	elseif (event == "UPDATE_MOUSEOVER_UNIT") or (event == "CURSOR_UPDATE") then
		LibSwag.SetTooltip()
	end
end

-- Spell names and types
do
	local GetSpellInfo = function( ... ) return GetSpellInfo(...) or "" end -- prevent nil key errors (just being paranoid)
	myLib.lootSpells = {
		[GetSpellInfo(2366)] =   "HERB", -- Herb Gathering(Apprentice)
		[GetSpellInfo(2575)] =   "MINE", -- Mining(Apprentice)
		[GetSpellInfo(7620)] =   "FISH", -- Fishing(Apprentice)
		[GetSpellInfo(8613)] =   "SKIN", -- Skinning(Apprentice)
		[GetSpellInfo(1804)] =   "OPEN", -- Pick Lock()
		[GetSpellInfo(3365)] =   "OPEN", -- Opening()
		[GetSpellInfo(3366)] =   "OPEN", -- Opening()
		[GetSpellInfo(6247)] =   "OPEN", -- Opening()
		[GetSpellInfo(6249)] =   "OPEN", -- Opening()
		[GetSpellInfo(6477)] =   "OPEN", -- Opening()
		[GetSpellInfo(6478)] =   "OPEN", -- Opening()
		[GetSpellInfo(6509)] =   "OPEN", -- Opening()
		[GetSpellInfo(6658)] =   "OPEN", -- Opening()
		[GetSpellInfo(6802)] =   "OPEN", -- Opening()
		[GetSpellInfo(8917)] =   "OPEN", -- Opening()
		[GetSpellInfo(21248)] =  "OPEN", -- Opening()
		[GetSpellInfo(21288)] =  "OPEN", -- Opening()
		[GetSpellInfo(21651)] =  "OPEN", -- Opening()
		[GetSpellInfo(24390)] =  "OPEN", -- Opening()
		[GetSpellInfo(24391)] =  "OPEN", -- Opening()
		[GetSpellInfo(26868)] =  "OPEN", -- Opening()
		[GetSpellInfo(39220)] =  "OPEN", -- Opening()
		[GetSpellInfo(39264)] =  "OPEN", -- Opening()
		[GetSpellInfo(45137)] =  "OPEN", -- Opening()
		[GetSpellInfo(22810)] =  "OPEN", -- Opening - No Text()
	}
	myLib.lootSpells[""] = nil -- clear out any useless entries
end

-- Basic items (note, the list grows when we find new items)
myLib.items = {
	["MINE"] = {
	},
	["HERB"] = {
	},
	["FISH"] = {
	},
}

-- Tracks spell events to determine loot sequences
local isCasting = false
function myLib.Spell(event, caster, spell, rank, target)
	if (not LibSwag.tracker) then LibSwag.tracker = {} end

	if (event == "UNIT_SPELLCAST_SENT") then
		if ( myLib.lootSpells[spell] ) then
			LibSwag.SetTooltip()
			LibSwag.tracker.spell = spell or "Opening"
			LibSwag.tracker.start = GetTime()
			LibSwag.tracker.tooltip = target and {tip=target, time=GetTime()} or LibSwag.GetLastTip()
			isCasting = true
		end
	elseif (event == "UNIT_SPELLCAST_SUCCEEDED") then
		if (LibSwag.tracker.spell == spell) then
			LibSwag.tracker.ended = GetTime()
		end
		isCasting = false
	elseif ((event == "UNIT_SPELLCAST_INTERRUPTED") or (event == "UNIT_SPELLCAST_FAILED")) then
		if ( isCasting ) then
			local ltype = LibSwag.lootSpells[LibSwag.tracker.spell]
			if (not ltype and LibSwagData.spells) then
				ltype = LibSwagData.spells[LibSwag.tracker.spell]
			end
			if (ltype) then
				for i, callback in pairs(LibSwag.callbacks) do
					if (callback.castHook) then
						callback.castHook(ltype, nil, nil, LibSwag.tracker.tooltip)
					end
				end
			end
		end
		isCasting = false
		-- Spell failed, cancel the tracking
		LibSwag.tracker.spell = nil
		LibSwag.tracker.tooltip = nil
	end
end

-- Records the loot that just happened and calls the hooked callbacks
function myLib.RecordLoot(ltype, method)
	local loot = {}
	local coin = 0
	local count = GetNumLootItems()
	for i = 1, count do
		local lIcon, lName, lQuantity, lQuality = GetLootSlotInfo(i)
		local lLink = GetLootSlotLink(i)
		if (not lLink and LootSlotIsCoin(i)) then
			local i,j,val
			i,j, val = string.find(lName, COPPER_AMOUNT:gsub("%%d", "(%%d+)", 1))
			if (i) then coin = coin + val end
			i,j, val = string.find(lName, SILVER_AMOUNT:gsub("%%d", "(%%d+)", 1))
			if (i) then coin = coin + (val*100) end
			i,j, val = string.find(lName, GOLD_AMOUNT:gsub("%%d", "(%%d+)", 1))
			if (i) then coin = coin + (val*10000) end
		else
			table.insert(loot, { link = lLink, name = lName, count = lQuantity })
		end
	end

	for i, callback in pairs(LibSwag.callbacks) do
		if (callback.lootHook) then
			callback.lootHook(ltype, loot, coin, method)
		end
	end
end

-- Allows dependant addons to hook into the loot sequence
function myLib.RegisterHook(name, lootHook, castHook)
	table.insert(LibSwag.callbacks, { name = name, lootHook = lootHook, castHook = castHook })
end

-- Processes the lootbox for data
function myLib.Loot()
	local spell
	if (LibSwag.tracker and LibSwag.tracker.spell and
		LibSwag.tracker.ended and GetTime() - LibSwag.tracker.ended < 1) then
		local lastSpell = LibSwag.tracker.spell
		spell = LibSwag.lootSpells[lastSpell]
		if (not spell and LibSwagData.spells) then
			spell = LibSwagData.spells[lastSpell]
		end

		if (not spell) then
			local primary = GetLootSlotLink(1)
			if (primary) then
				primary = primary:match("item:(%d+)")
				if (primary) then
					if (not LibSwagData.ai) then LibSwagData.ai = {} end
					if (not LibSwagData.ai[lastSpell]) then LibSwagData.ai[lastSpell] = {} end
					for stype, count in pairs(LibSwagData.ai[lastSpell]) do
						if count > 1 then
							LibSwagData.ai[lastSpell][stype] = count - 1
						else
							LibSwagData.ai[lastSpell][stype] = nil
						end
					end
					if (not LibSwagData.items) then LibSwagData.items = {} end
					if (not LibSwagData.spells) then LibSwagData.spells = {} end
					if (LibSwagData.items[primary]) then
						local primeType = LibSwagData.items[primary]
						local count = LibSwagData.ai[lastSpell][primeType] or -1
						count = count + 2
						LibSwagData.ai[lastSpell][primeType] = count
						if (count >= 3) then
							LibSwagData.spells[lastSpell] = primeType
						end
					end
				end
			end
		end
	end
	if (IsFishingLoot()) then
		return myLib.RecordLoot("FISH")
	elseif (spell) then
		return myLib.RecordLoot(spell, LibSwag.tracker.tooltip)
	elseif (CheckInteractDistance("target", 3) and UnitIsDead("target")) then
		-- Most likely to be loot from kill
		return myLib.RecordLoot("KILL", { unit = UnitName("target"), level = UnitLevel("target") })
	end

end

-- Registers the library to recieve an event (if it does not already do so)
function myLib.RegEvent(ev)
	if not LibSwagFrame["REG_"..ev] then
		LibSwagFrame:RegisterEvent(ev)
		LibSwagFrame["REG_"..ev] = true
	end
end

-- Adds a predefined item to your saved data
function myLib.AddItem(cat, enName, id)
	local name = GetItemInfo(id)
	if (not LibSwagData.items) then LibSwagData.items = {} end
	if (not LibSwagData.cats) then LibSwagData.cats = {} end
	if (not LibSwagData.cats[cat]) then LibSwagData.cats[cat] = {} end
	if (not LibSwagData.spells) then LibSwagData.spells = {} end
	if (not LibSwagData.ai) then LibSwagData.ai = {} end
	if (not name) then name = enName end
	LibSwagData.items[id] = { cat = cat, name = name }
	LibSwagData.cats[cat][name] = id
end

-- Call this function in the OnLoad function of your addon
function myLib.Init()
	for cat, data in pairs(LibSwag.items) do
		if (not LibSwagData[cat]) then LibSwagData[cat] = {} end
		for name, itemid in pairs(data) do
			LibSwag.AddItem(cat, name, itemid)
		end
	end
end

-- Function to store the last set tooltip text
function myLib.SetTooltip(line, newtext, r,g,b,a)
	if (not line) then
		local gtext
		local lines = GameTooltip:NumLines()
		for i=1, lines do
			gtext = (_G["GameTooltipTextLeft"..i]:GetText() or "")
			local rTip = _G["GameTooltipTextRight"..i]
			if (rTip:IsVisible()) then
				gtext = gtext.." / "..(rTip:GetText() or "")
			end
			--log("SetTooltip", N_INFO, "Set Tooltip Line", "Setting tooltip line", i, "=", gtext)
			LibSwag.SetTooltip(i, gtext)
		end
		return
	end
	if (line > 1) then return end
	local now = GetTime()

    -- Get the original text from the tooltip
	local text = GameTooltipTextLeft1:GetText()
	if (not text) then text = newtext end

	-- Check to see if we have just recorded this tip
	if (LibSwag.lastTipTime and text ~= LibSwag.lastTipText) then
		local delta = now - LibSwag.lastTipTime
		if (delta < 0.8) then
			--log("SetTooltip", N_INFO, "Discard Tooltip", "Discarding tooltip because we have one that's only ", delta, "seconds old")
			return
		end
	end

	-- We're not interested in unit tooltips or any interface tips
	local mouseover = UnitName("mouseover")
	if ((not mouseover or mouseover:find(UNKNOWN)) and GetMouseFocus() == WorldFrame) then
		LibSwag.lastTipText = text
		LibSwag.lastTipTime = GetTime()
		--log("SetTooltip", N_INFO, "Tooltup Text + Time", "Found usable tooltip text =", text, " and time =", LibSwag.lastTipTime)
	else
		--log("SetTooltip", N_INFO, "Not interested", "Current mouseover is not a doodad. UnitName =", UnitName("mouseover"), " and focus =", (GetMouseFocus() and GetMouseFocus():GetName() or "nil"))
	end
end
-- Getter for the above function
function myLib.GetLastTip()
	-- Loot boxes should pop up pretty quickly.. if the tooltip was last
	-- set more than 10 seconds ago, then discard it.
	local delta = 0
	if (LibSwag.lastTipTime) then delta = GetTime() - LibSwag.lastTipTime end
	if (not LibSwag.lastTipTime or delta > 10) then
		--log("GetLastTip", N_INFO, "Remove Last Tooltip", "Removing ancient tooltip data: text = ", LibSwag.lastTipText, "age =", delta)
		LibSwag.lastTipTime = nil
		LibSwag.lastTipText = nil
		return nil
	end
	--log("GetLastTip", N_INFO, "Get Last Tooltip", "Return last text =", LibSwag.lastTipText, "and time =", LibSwag.lastTipTime)
	return {
		tip = LibSwag.lastTipText,
		time = LibSwag.lastTipTime
	}
end

LibSwag = myLib

-- Create a version independant frame if it doesn't exist
if (not LibSwagFrame) then
	-- Setup a event handler stub (which won't change between versions)
	LibSwagFrame = CreateFrame("Frame", "LibSwagFrame")
	function LibSwagFrame.OnEvent(frame, event, ...) LibSwag.OnEvent(event, ...) end

	-- Hook into the SetText of GameTooltip to catch the original setting of the tooltip
	LibSwagFrame.ttLine = 0
	-- Hook GameTooltipTextLeft1:SetText()
	function LibSwagFrame.GameTooltipSetTextLeft1(this, ...)
		LibSwag.SetTooltip(1, ...)
		LibSwagFrame.OldGameTooltipSetTextLeft1(this, ...)
	end
	LibSwagFrame.OldGameTooltipSetTextLeft1 = GameTooltipTextLeft1.SetText
	GameTooltipTextLeft1.SetText = LibSwagFrame.GameTooltipSetTextLeft1
	-- Hook GameTooltip:SetText() and keep track of the current line
	function LibSwagFrame.GameTooltipSetText(this, ...)
		local line = LibSwagFrame.ttLine + 1
		LibSwagFrame.ttLine = line
		LibSwag.SetTooltip(line, ...)
		LibSwagFrame.OldGameTooltipSetText(this, ...)
	end
	LibSwagFrame.OldGameTooltipSetText = GameTooltip.SetText
	GameTooltip.SetText = LibSwagFrame.GameTooltipSetText
	-- Hook GameTooltip:ClearLines to reset the line number
	function LibSwagFrame.GameTooltipClearLines(this)
		LibSwagFrame.ttLine = 0
		LibSwagFrame.OldGameTooltipClearLines(this)
	end
	LibSwagFrame.OldGameTooltipClearLines = GameTooltip.ClearLines
	GameTooltip.ClearLines = LibSwagFrame.GameTooltipClearLines

	-- Display the frame and set the event callback function
	LibSwagFrame:Show()
	LibSwagFrame:SetScript("OnEvent",  LibSwagFrame.OnEvent)
end

-- Initialize the callback table if it doesn't exist
if (not LibSwag.callbacks) then
	LibSwag.callbacks = {}
end

-- Get the library to register for the relevant events
LibSwag.RegEvent("LOOT_OPENED")
LibSwag.RegEvent("UNIT_SPELLCAST_SENT")
LibSwag.RegEvent("UNIT_SPELLCAST_SUCCEEDED")
LibSwag.RegEvent("UNIT_SPELLCAST_INTERRUPTED")
LibSwag.RegEvent("UNIT_SPELLCAST_FAILED")
LibSwag.RegEvent("UPDATE_MOUSEOVER_UNIT")
LibSwag.RegEvent("CURSOR_UPDATE")

if (nLog) then
	log = function(ltype, level, title, ...) nLog.AddMessage("Swag", ltype, level, title, ...) end
else log = function() end end

-- reference to the Astrolabe mapping library
local Astrolabe = DongleStub(IlarosFarm.AstrolabeVersion)

-- This function can be used as an interface by other addons to record things
-- in IlarosFarm's database, though display is still based only on what is defined
-- in IlarosFarm items and icons tables.
-- Parameters:
--   objectId (number): the object id for this node (from IlarosFarm.Nodes)
--   farmType (string): farm type (Mine, Herb, Skin, Fish, Treasure)
--   tooltipText (string): the text in the tooltip (unused)
--   farmSource (string): the name of the sender (or nil if you collected it)
--   farmCoins (number): amount of copper found in the node
--   farmLoot (table): a table of loot: { { link, count }, ...}
--   wasFarmed (boolean): was this object actually opened by the player
function IlarosFarm.Api.AddFarm(objectId, farmType, tooltipText, farmSource, farmCoins, farmLoot, wasFarmed, farmC, farmZ, farmX, farmY)
	local success
	
	if not (farmC and farmZ and farmX and farmY) then
		farmC, farmZ, farmX, farmY = IlarosFarm.Util.GetPositionInCurrentZone()
		if not (farmC and farmZ and farmX and farmY) then
			return
		end
	end
	if ( farmC <= 0 or farmZ <= 0 ) then
		return
	end
	
	if (not farmSource) then
		IlarosFarm.DropRates.ProcessDrops(objectId, farmC, farmZ, farmSource, farmCoins, farmLoot)
	end
	
	if ( type(objectId) == "number" or IlarosFarm.Categories.CategoryNames[objectId] ) then 
		local index = IlarosFarm.Storage.AddNode(objectId, farmType, farmC, farmZ, farmX, farmY, farmSource, wasFarmed)
		if  index and index > 0 then
			success = true
		end

		-- If this is ours
		if ( (not farmSource) or (farmSource == "REQUIRE") ) then
			IlarosFarm.Comm.Send(objectId, farmC, farmZ, index, farmCoins, farmLoot)
		end
	end
	
	IlarosFarm.MiniNotes.ForceUpdate()
	IlarosFarm.MapNotes.MapDraw()

	return success
end
