----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für Kommunikation mit anderen Spielern
----------------------------------------------------------------------------

local lib = IlarosFarm.Comm

local sendOfferer
local acceptFrom = {}

local lastHarvest = {}
function IlarosFarm.Comm.Send( objectId, farmC, farmZ, farmIndex, farmCoins, farmLoot )
	if ( type(objectId) == "number" ) then
		farmZ = IlarosFarm.ZoneTokens.GetZoneToken(farmC, farmZ)
		local farmX, farmY = IlarosFarm.Storage.GetNodeInfo(farmC, farmZ, objectId, farmIndex)
		
		-- if both are nil, then we tried to get a non-existant node, just return
		if (not farmX and not farmY) then return end
		
		-- construct loot text string
		local lootText = farmCoins or 0
		if ( farmLoot ) then
			for pos, loot in ipairs(farmLoot) do
				local id = loot.id
				if ( (not id) and loot.link ) then
					id = IlarosFarm.Util.BreakLink(loot.link)
				end
				if ( id ) then
					local count = loot.count
					if ( count ) then
						lootText = lootText .. ":" .. id .. "x" .. count
					end
				end
			end
		end
		
		-- Check if this node has been just broadcast by us
		if not (lastHarvest and lastHarvest.c == farmC and lastHarvest.z == farmZ and lastHarvest.o == objectId and lastHarvest.i == farmIndex) then
			-- Ok, so lets broadcast this node
			local guildAlert, raidAlert, raidType
			local sendMessage = strjoin(";", objectId, farmC, farmZ, farmX, farmY, lootText)
			if IlarosFarm.Config.GetSetting("guild.enable") then
				if ( IsInGuild() ) then
					SendAddonMessage("GathX", sendMessage, "GUILD")
					if (IlarosFarm.Config.GetSetting("guild.print.send")) then guildAlert = true end
				end
			end
			if (IlarosFarm.Config.GetSetting("raid.enable")) then
				if GetNumRaidMembers() > 0 then
					raidType = FarmText_RAID
				elseif GetNumPartyMembers() > 0 then
					raidType = FarmText_PRTY
				end
				SendAddonMessage("GathX", sendMessage, "RAID")
				if (raidType and IlarosFarm.Config.GetSetting("raid.print.send")) then raidAlert = true end
			end
			
			if IlarosFarm.Config.GetSetting("personal.print") then
				local objName = IlarosFarm.Util.GetNodeName(objectId);
				IlarosFarm.Util.ChatPrint(string.format(FarmText_ADD, objName))
			end
			if (guildAlert or raidAlert) then
				local objName = IlarosFarm.Util.GetNodeName(objectId);
				local whom
				if guildAlert and raidAlert then
					whom = FarmText_GLD..FarmText_AND..raidType
				elseif guildAlert then
					whom = FarmText_GLD
				else
					whom = raidType
				end
				IlarosFarm.Util.ChatPrint(string.format(FarmText_SND, objName, whom))
			end
		end
		lastHarvest.c = farmC
		lastHarvest.z = farmZ
		lastHarvest.o = objectId
		lastHarvest.i = farmIndex
	end
end

local lastMessage = ""
local playerName = UnitName("player")
function IlarosFarm.Comm.Receive( message, how, who )
	local setting = IlarosFarm.Config.GetSetting
	local msgtype = "raid"
	local msgname = FarmText_RAID

	-- check if the player is on our sharing blacklist
	local blacklisted = IlarosFarm.Config.SharingBlacklist_IsPlayerIgnored(who)
	if ( blacklisted ) then
		return
	end

	if ( message ~= lastMessage and who ~= playerName ) then
		if (how:lower() == "party") then
            msgname = FarmText_PRTY
        end
		if (how:lower() == "guild") then
            msgtype = "guild"
            msgname = FarmText_GLD
        end
		if (how:lower() == "whisper") then
			msgtype = "whisper"
            msgname = FarmText_WSP
			if not acceptFrom[who:lower()] then return end
		elseif not (setting(msgtype..".enable") and setting(msgtype..".receive")) then return end

		lastMessage = message
		local objectID, farmC, zoneToken, farmX, farmY, loot = strsplit(";", message)
		objectID = tonumber(objectID)
		farmC = tonumber(farmC)
		farmX = tonumber(farmX)
		farmY = tonumber(farmY)
		if ( objectID and farmC and zoneToken and farmX and farmY ) then
			local farmType = IlarosFarm.Nodes.Objects[objectID]
			local farmZ = IlarosFarm.ZoneTokens.GetZoneIndex(farmC, zoneToken)
			local localizedZoneName = select(farmZ, GetMapZones(farmC))
			
			if ( farmType and farmZ ) then
				local coins, loots = IlarosFarm.Util.LootSplit(loot)
				IlarosFarm.Api.AddFarm(objectID, farmType, "", who, coins, loots, false, farmC, farmZ, farmX, farmY)
				local objName = IlarosFarm.Util.GetNodeName(objectID);
				if msgtype == "whisper" then
					IlarosFarm.Report.SendFeedback(who, "RECV", objectID)
				elseif setting(msgtype..".print.recv") then
					IlarosFarm.Util.ChatPrint(string.format(FarmText_RCV, objName, localizedZoneName, who, msgname))
				end
			end
		end
	end
end

StaticPopupDialogs["ILAROSFARM_COMM_REQUESTSEND"] = {
	text = FarmText_DLG9,
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	OnAccept = function()
			StaticPopupDialogs["ILAROSFARM_COMM_REQUESTSEND"].accepted = 1
			IlarosFarm.Comm.SendFeedback("ACCEPT")
	end,
	OnCancel = function()
			StaticPopupDialogs["ILAROSFARM_COMM_REQUESTSEND"].accepted = -2
			IlarosFarm.Comm.SendFeedback("REJECT")
	end,
	OnShow = function()
		StaticPopupDialogs["ILAROSFARM_COMM_REQUESTSEND"].accepted = nil
	end,
	OnHide = function()
		if StaticPopupDialogs["ILAROSFARM_COMM_REQUESTSEND"].accepted == nil then
			IlarosFarm.Comm.SendFeedback("TIMEOUT")
			StaticPopupDialogs["ILAROSFARM_COMM_REQUESTSEND"].accepted = -1
		end
	end,
	timeout = 15,
	whileDead = 1,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1
};

function IlarosFarm.Comm.SendFeedback(reply)
	SendAddonMessage("IlarosFarm", "SENDNODES:"..reply, "WHISPER", sendOfferer)
	IlarosFarm.Report.SendFeedback(sendOfferer, a)
	if (reply == "ACCEPT") then
		acceptFrom[sendOfferer:lower()] = true
		IlarosFarm.Report.SendFeedback(sendOfferer, "ACCEPTED")
	end
	if (reply ~= "PROMPT") then
		sendOfferer = nil
	end
end

function IlarosFarm.Comm.General( msg, how, who )
	if ( UnitName("player") == who ) then
		return
	end
	local cmd, a,b,c,d = strsplit(":", msg)
	if ( msg == "VER" ) then
		SendAddonMessage("IlarosFarm", "VER:"..IlarosFarm.Var.Version, how)
	elseif ( cmd == "SENDNODES" ) then
		-- check if the player is on our sharing blacklist
		local blacklisted = IlarosFarm.Config.SharingBlacklist_IsPlayerIgnored(who)
		if ( blacklisted ) then
			local tmp = sendOfferer
			sendOfferer = who
			IlarosFarm.Comm.SendFeedback("REJECT")
			sendOfferer = tmp
			return
		end
		if (IlarosFarm.Report.IsOpen()) then
			if (a == "OFFER") then
				local count = tonumber(b) or 0
				if (count > 0) then
					if (sendOfferer) then
						SendAddonMessage("IlarosFarm", "SENDNODES:BUSY", "WHISPER", who)
					else
						sendOfferer = who
						SendAddonMessage("IlarosFarm", "SENDNODES:PROMPT", "WHISPER", who)
						StaticPopup_Show("ILAROSFARM_COMM_REQUESTSEND", who, count)
					end
				end
			elseif (a == "DONE") then
				if (acceptFrom[who:lower()]) then
					acceptFrom[who:lower()] = nil
					IlarosFarm.Report.SendFeedback(who, a)
					SendAddonMessage("IlarosFarm", "SENDNODES:COMPLETE", "WHISPER", who)
				end
			elseif (a == "PAUSE") then
				if (acceptFrom[who:lower()]) then
					SendAddonMessage("IlarosFarm", "SENDNODES:CONTINUE", "WHISPER", who)
				end
			elseif (a == "CONTINUE") then
				IlarosFarm.Report.SendFeedback(who, a)
			elseif (a == "ABORTED") then
				IlarosFarm.Report.SendFeedback(who, a)
			elseif (a == "COMPLETE") then
				IlarosFarm.Report.SendFeedback(who, a)
			end
		elseif (a == "OFFER") then
			SendAddonMessage("IlarosFarm", "SENDNODES:CLOSED", "WHISPER", who)
		end
		if (a == "PROMPT" or a == "ACCEPT" or a == "REJECT" or a == "BUSY" or a == "TIMEOUT") then
			IlarosFarm.Report.SendFeedback(who, a)
		end
	end
end
