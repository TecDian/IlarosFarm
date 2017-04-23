----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für Chat-Kommandos
----------------------------------------------------------------------------

SLASH_ILAROSFARM1 = "/farm"
SLASH_ILAROSFARM2 = "/ilarosfarm"
SlashCmdList["ILAROSFARM"] = function( msg )
    IlarosFarm.Command.Process(msg)
end

local function PrintUsageLine( cmd, curSetting, description )
    if ( curSetting ) then
        IlarosFarm.Util.ChatPrint(format("|cffffff78/Farm %s|r |cff78ffff[%s]|r |cffffffff- %s|r", cmd, curSetting, description))
    else
        IlarosFarm.Util.ChatPrint(format("|cffffff78/Farm %s|r |cffffffff- %s|r", cmd, description))
    end
end
IlarosFarm.Command.PrintUsageLine = PrintUsageLine

local function parseOnOff( str )
    if ( str == FarmText_ON or str == "on" or str == "true" or str == "1" or str == "enable" ) then
        return true
    elseif ( str == FarmText_OFF or str == "off" or str == "false" or str == "0" or str == "disable" ) then
        return false
    else
        return nil
    end
end
IlarosFarm.Command.parseOnOff = parseOnOff

local function parseFarmType( str )
    if ( str == "s" ) then
        return "open"
    elseif ( str == "p" ) then
        return "herb"
    elseif ( str == "e" ) then
        return "mine"
    elseif ( str == "f" ) then
        return "fish"
    end
end

function IlarosFarm.Command.Process( command )
    local Config = IlarosFarm.Config
    command = command:trim():gsub("%s+", " ")
    if ( command == "k" ) then
        Config.MakeGuiConfig()
        Config.Gui:Show()
    else
        local cmd, p1, p2, p3, p4 = string.split(" ", command:lower())
        local GetSetting = Config.GetSetting
        local Print = IlarosFarm.Util.ChatPrint

        if ( (cmd == "m") or (cmd == "minimap") ) then
            local enabled = parseOnOff(p1)
            if ( enabled == true ) then
                Config.SetSetting("minimap.enable", true)
                Print(FarmText_SMini)

            elseif ( enabled == false ) then
                Config.SetSetting("minimap.enable", false)
                Print(FarmText_HMini)

            else
                if ( Config.GetSetting("minimap.enable") ) then
                    IlarosFarm.Command.Process( "minimap off" )
                else
                    IlarosFarm.Command.Process( "minimap on" )
                end
            end

        elseif ( (cmd == "w") or (cmd == "worldmap") ) then
            local enabled = parseOnOff(p1)
            if ( enabled == true ) then
                Config.SetSetting("mainmap.enable", true)
                Print(FarmText_SWorld)

            elseif ( enabled == false ) then
                Config.SetSetting("mainmap.enable", false)
                Print(FarmText_HWorld)

            else
                if ( Config.GetSetting("mainmap.enable") ) then
                    IlarosFarm.Command.Process( "worldmap off" )
                else
                    IlarosFarm.Command.Process( "worldmap on" )
                end
            end

        elseif ( (cmd == "dis") or (cmd == "distance") ) then
            local newDist = tonumber(p1)
            if ( newDist and 100 <= newDist and newDist <= 5000 ) then
                newDist = newDist - newDist % 50
                Config.SetSetting("minimap.distance", newDist)
                Print(string.format(FarmText_NDist,newDist))
            end

        elseif ( (cmd == "num") or (cmd == "number") ) then
            local newCount = tonumber(p1)
            if ( newCount and 1 <= newCount and newCount <= 50 ) then
                newCount = floor(newCount)
                Config.SetSetting("minimap.count", newCount)
                Print(string.format(FarmText_NNumb,newCount))
            end

        elseif ( (cmd == "f") or (cmd == "p") or (cmd == "e") or (cmd == "s") ) then
            local farmType = parseFarmType(cmd)
            if ( farmType ) then
                local enabled = parseOnOff(p1)
                if ( enabled == true ) then
                    local cmd = FarmText_SKL[farmType:upper()]
                    Config.SetSetting("show.minimap."..farmType, true)
                    Print(string.format(FarmText_STrad, cmd))

                elseif ( enabled == false ) then
                    local cmd = FarmText_SKL[farmType:upper()]
                    Config.SetSetting("show.minimap."..farmType, false)
                    Print(string.format(FarmText_HTrad, cmd))

                else
                    if ( Config.GetSetting("show.minimap."..farmType) ) then
                        IlarosFarm.Command.Process( cmd.." off" )
                    else
                        IlarosFarm.Command.Process( cmd.." on" )
                    end
                end
            end

        elseif ( (cmd == "num") or (cmd == "number") ) then
            local newCount = tonumber(p1)
            if ( newCount and 1 <= newCount and newCount <= 50 ) then
                newCount = floor(newCount)
                Config.SetSetting("minimap.count", newCount)
                Print(string.format(FarmText_NNumb,newCount))
            end

        elseif ( (cmd == "v") or (cmd == "ver") or (cmd == "version") ) then
            Print(FarmText_FName)
            Print(string.format(FarmText_FVer,IlarosFarm.Var.Version))

        elseif ( cmd == "l" ) then
            IlarosFarm.Report.Toggle()

        elseif ( cmd == "h" ) then
            IlarosFarm.NodeSearch.Toggle()

        else
            local useMinimap = GetSetting("minimap.enable") and FarmText_ON or FarmText_OFF
            local useMainmap = GetSetting("mainmap.enable") and FarmText_ON or FarmText_OFF
            local showHerbs = GetSetting("show.minimap.herb") and FarmText_ON or FarmText_OFF
            local showOre = GetSetting("show.minimap.mine") and FarmText_ON or FarmText_OFF
            local showFish = GetSetting("show.minimap.fish") and FarmText_ON or FarmText_OFF
            local showTresure = GetSetting("show.minimap.open") and FarmText_ON or FarmText_OFF

            Print(FarmText_SLASH)
            Print(FarmText_COMs)
            PrintUsageLine("v", nil, FarmText_VERs)
            PrintUsageLine("k", nil, FarmText_OPTs)
            PrintUsageLine("l", nil, FarmText_FRWs)
            PrintUsageLine("h", nil, FarmText_DRWs)
            PrintUsageLine("m", useMinimap, FarmText_MINIs)
            PrintUsageLine("w", useMainmap, FarmText_WRLDs)
            PrintUsageLine("v", nil, FarmText_VERs)
            PrintUsageLine("v", nil, FarmText_VERs)
            PrintUsageLine("v", nil, FarmText_VERs)
            PrintUsageLine("p", showHerbs, FarmText_CMDHs)
            PrintUsageLine("e", showOre, FarmText_CMDMs)
            PrintUsageLine("f", showFish, FarmText_CMDFs)
            PrintUsageLine("s", showTresure, FarmText_CMDTs)
            PrintUsageLine("dis <max>", GetSetting("minimap.distance"), FarmText_MXDs)
            PrintUsageLine("num <max>", GetSetting("minimap.count"), FarmText_MXNs)
        end
    end
end
