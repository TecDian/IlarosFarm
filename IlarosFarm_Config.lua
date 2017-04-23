----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für das Konfigurationsfenster
----------------------------------------------------------------------------

IlarosFarm.Settings = {}

local metatable = { __index = getfenv(0) }
setmetatable( IlarosFarm.Config, metatable )
setfenv(1, IlarosFarm.Config)

-- place any variables that the settings table should be
-- initialised with here
Default_Settings = {
}

local function getDefault(setting)
    if (setting == "inspect.enable")    then return false   end
    local a,b,c,d = strsplit(".", setting)
    if (a == "show") then
        if (c == "all" or d == "all") then return false end
        if (d == "onlyiftracked") then return false end
        return true
    end
    if (b == "enable") then return true end
    if (b == "tooltip" and c == "rate" and d == "num") then return 5 end
    if (b == "tooltip") then return true end
    if (setting == "mainmap.count")     then return 600     end
    if (setting == "mainmap.opacity")   then return 80      end
    if (setting == "mainmap.iconsize")  then return 12      end
    if (setting == "minimap.count")     then return 20      end
    if (setting == "minimap.opacity")   then return 80      end
    if (setting == "minimap.iconsize")  then return 12      end
    if (setting == "minimap.distance")  then return 800     end
    if (setting == "miniicon.angle")    then return 270     end
    if (setting == "miniicon.distance") then return 12      end
    if (setting == "fade.distance")     then return 500     end
    if (setting == "fade.percent")      then return 20      end
    if (setting == "track.circle")      then return true    end
    if (setting == "track.style")       then return "white" end
    if (setting == "track.current")     then return true    end
    if (setting == "track.distance")    then return 110     end
    if (setting == "track.opacity")     then return 80      end
    if (setting == "inspect.tint")      then return true    end
    if (setting == "inspect.distance")  then return 25      end
    if (setting == "inspect.percent")   then return 80      end
    if (setting == "inspect.time")      then return 120     end
    if (setting == "anon.tint")         then return true    end
    if (setting == "anon.opacity")      then return 60      end
    if (setting == "guild.receive")     then return true    end
    if (setting == "guild.print.send")  then return false   end
    if (setting == "guild.print.recv")  then return true    end
    if (setting == "raid.receive")      then return true    end
    if (setting == "raid.print.send")   then return false   end
    if (setting == "raid.print.recv")   then return true    end
    if (setting == "personal.print")    then return false   end
    if (setting == "about.loaded")      then return false   end
    if (setting == "track.colour.HERB") then return "0.250,0.750,0.250" end
    if (setting == "track.colour.MINE") then return "1.000,0.500,0.250" end
    if (setting == "track.colour.FISH") then return "0.100,0.100,1.000" end
    if (setting == "track.colour.OPEN") then return "1.000,0.000,0.750" end

end

-- Note: This function WILL NOT handle self referencing table
-- structures correctly (ie. it will never terminate)
local function deepCopy( source, dest )
    for k, v in pairs(source) do
        if ( type(v) == "table" ) then
            if not ( type(dest[k]) == "table" ) then
                dest[k] = {}
            end
            deepCopy(v, dest[k])
        else
            dest[k] = v
        end
    end
end

function ConvertOldSettings( conversions )
    local Settings = IlarosFarm.Settings
    for pat, repl in pairs(conversions) do
        for name, profileData in pairs(Settings) do
            if ( name:sub(1, 8) == "profile." ) then
                local newSettings = {}
                for setting, value in pairs(profileData) do
                    local new, count = setting:gsub(pat, repl)
                    if ( count >= 1 ) then
                        newSettings[new] = value
                        profileData[setting] = nil
                    end
                end
                for setting, value in pairs(newSettings) do
                    profileData[setting] = value
                end
            end
        end
    end
end

--Load settings from the SavedVariables tables
function Load()
    local Settings = IlarosFarm.Settings
    deepCopy(Default_Settings, Settings)

    if ( FarmConfig ) then
        deepCopy(FarmConfig, Settings)
    end

    -- Sharing Blacklist
    SharingBlacklist_Load()
end

--Save settings to the SavedVariables tables
-- Call this when the PLAYER_LOGOUT event fires or saved settings
-- will not be updated
function Save()
    local data = IlarosFarm.Settings

    local accountSettings = {}
    for key in pairs(data) do
        accountSettings[key] = data[key]
    end
    _G.FarmConfig = accountSettings

    SharingBlacklist_Save()
end

--*****************************************************************************
-- Settings Manipulation Functions
--*****************************************************************************

local function getUserSig()
    local userSig = string.format("users.%s.%s", GetRealmName(), UnitName("player"))
    return userSig
end

local function getUserProfileName()
    local SETTINGS = IlarosFarm.Settings
    local userSig = getUserSig()
    return SETTINGS[userSig] or "Default"
end

local itc = 0
local function getUserProfile()
    local SETTINGS = IlarosFarm.Settings
    local profileName = getUserProfileName()
    if (not SETTINGS["profile."..profileName]) then
        if profileName ~= "Default" then
            profileName = "Default"
            SETTINGS[getUserSig()] = "Default"
        end
        if profileName == "Default" then
            SETTINGS["profile."..profileName] = {}
        end
    end
    return SETTINGS["profile."..profileName]
end

local function cleanse( source )
    for k in pairs(source) do
        source[k] = nil
    end
end

local updateTracker = {}
local function setUpdated()
    for k in pairs(updateTracker) do
        updateTracker[k] = nil
    end
end

function IlarosFarm.Command.IsUpdated(what)
    if not updateTracker[what] then
        updateTracker[what] = true
        return true
    end
    return false
end

local function setter(setting, value)
    local SETTINGS = IlarosFarm.Settings
    local a,b,c = strsplit(".", setting)
    if (a == "profile") then
        local gui = IlarosFarm.Config.Gui
        if (setting == "profile.save") then
            value = gui.elements["profile.name"]:GetText()

            -- Create the new profile
            SETTINGS["profile."..value] = {}

            -- Set the current profile to the new profile
            SETTINGS[getUserSig()] = value
            -- Get the new current profile
            local newProfile = getUserProfile()
            -- Clean it out and then resave all data
            cleanse(newProfile)
            gui:Resave()

            -- Add the new profile to the profiles list
            local profiles = SETTINGS["profiles"]
            if (not profiles) then
                profiles = { "Default" }
                SETTINGS["profiles"] = profiles
            end
            -- Check to see if it already exists
            local found = false
            for pos, name in ipairs(profiles) do
                if (name == value) then found = true end
            end
            -- If not, add it and then sort it
            if (not found) then
                table.insert(profiles, value)
                table.sort(profiles)
            end
            DEFAULT_CHAT_FRAME:AddMessage("Saved profile: "..value)
        elseif (setting == "profile.copy") then
            value = gui.elements["profile.name"]:GetText()

            local curprofile = getUserProfileName()
            -- Create the new profile
            SETTINGS["profile."..value] = SETTINGS["profile."..curprofile]

            -- Set the current profile to the new profile
            SETTINGS[getUserSig()] = value
            -- Get the new current profile
            local newProfile = getUserProfile()
            --[[-- Clean it out and then resave all data
            cleanse(newProfile)
            gui:Resave()
            --]]

            -- Add the new profile to the profiles list
            local profiles = SETTINGS["profiles"]
            if (not profiles) then
                profiles = { "Default" }
                SETTINGS["profiles"] = profiles
            end
            -- Check to see if it already exists
            local found = false
            for pos, name in ipairs(profiles) do
                if (name == value) then found = true end
            end
            -- If not, add it and then sort it
            if (not found) then
                table.insert(profiles, value)
                table.sort(profiles)
            end
            DEFAULT_CHAT_FRAME:AddMessage("Saved profile: "..value)
        elseif (setting == "profile.delete") then
            -- User clicked the Delete button, see what the select box's value is.
            value = gui.elements["profile"].value

            -- If there's a profile name supplied
            if (value) then
                -- Clean it's profile container of values
                cleanse(SETTINGS["profile."..value])
                -- Delete it's profile container
                SETTINGS["profile."..value] = nil
                -- Find it's entry in the profiles list
                local profiles = SETTINGS["profiles"]
                if (profiles) then
                    for pos, name in ipairs(profiles) do
                        -- If this is it, then extract it
                        if (name == value and name ~= "Default") then
                            table.remove(profiles, pos)
                        end
                    end
                end
                -- If the user was using this one, then move them to Default
                if (getUserProfileName() == value) then
                    SETTINGS[getUserSig()] = 'Default'
                end
                DEFAULT_CHAT_FRAME:AddMessage("Deleted profile: "..value)
            end
        elseif (setting == "profile") then
            -- User selected a different value in the select box, get it
            value = gui.elements["profile"].value

            -- Change the user's current profile to this new one
            SETTINGS[getUserSig()] = value
            DEFAULT_CHAT_FRAME:AddMessage("Changing profile: "..value)
        end

        -- Refresh all values to reflect current data
        gui:Refresh()

    else
        -- Set the value for this setting in the current profile
        local db = getUserProfile()
        db[setting] = value
        setUpdated()
        IlarosFarm.MiniNotes.Show()
        IlarosFarm.MapNotes.Update()
    end

    if (a == "miniicon") then
        IlarosFarm.MiniIcon.Reposition()
    end
    if (a == "minimap") then
        IlarosFarm.MiniIcon.Update()
    end
end
function SetSetting(...)
    local gui = IlarosFarm.Config.Gui
    setter(...)
    if (gui) then
        gui:Refresh()
    end
end


local function getter(setting)
    local SETTINGS = IlarosFarm.Settings
    if not setting then return end

    local a,b,c = strsplit(".", setting)
    if (a == 'profile') then
        if (b == 'profiles') then
            local pList = SETTINGS["profiles"]
            if (not pList) then
                pList = { "Default" }
            end
            return pList
        end
    end
    if (setting == 'profile') then
        return getUserProfileName()
    end
    local db = getUserProfile()
    if ( db[setting] ~= nil ) then
        return db[setting]
    else
        return getDefault(setting)
    end
end
function GetSetting(setting, default)
    local option = getter(setting)
    if ( option ~= nil ) then
        local a,b,c = strsplit(".", setting)
        if ( a == "track" and b == "colour" ) then
            local r, g, b = strsplit(",", tostring(option))
            return r, g, b
        end
        return option
    else
        return default
    end
end

function DisplayFilter_MainMap( nodeId )
    local nodeType = IlarosFarm.Nodes.Objects[nodeId]
    if not ( nodeType ) then
        return false
    end
    local skill = IlarosFarm.Var.Skills[nodeType]
    nodeType = nodeType:lower()
    local showType = "show.mainmap."..nodeType
    local showAll = showType..".all"
    local showObject = "show."..nodeType.."."..nodeId
    local isTracked = IlarosFarm.Util.IsNodeTracked
    local onlyIfTracked = getter("show.mainmap."..nodeType..".onlyiftracked")
    local onlyIfSkilled = getter("show.mainmap."..nodeType..".onlyifskilled")
    return (
        getter(showType) and
        (getter(showAll) or getter(showObject)) and
        ((not onlyIfTracked) or isTracked(nodeId)) and
        ((not onlyIfSkilled) or skill)
    )
end

function DisplayFilter_MiniMap( nodeId )
    local nodeType = IlarosFarm.Nodes.Objects[nodeId]
    if not ( nodeType ) then
        return false
    end
    local skill = IlarosFarm.Var.Skills[nodeType]
    nodeType = nodeType:lower()
    local showType = "show.minimap."..nodeType
    local showAll = showType..".all"
    local showObject = "show."..nodeType.."."..nodeId
    local isTracked = IlarosFarm.Util.IsNodeTracked
    local onlyIfTracked = getter("show.minimap."..nodeType..".onlyiftracked")
    local onlyIfSkilled = getter("show.minimap."..nodeType..".onlyifskilled")
    return (
        getter(showType) and
        (getter(showAll) or getter(showObject)) and
        ((not onlyIfTracked) or isTracked(nodeId)) and
        ((not onlyIfSkilled) or skill)
    )
end

function Show()
    MakeGuiConfig()
    Gui:Show()
end

function ShowOptions()
    Show()
end

function Hide()
    if ( Gui ) then
        Gui:Hide()
    end
end

function HideOptions()
    Hide()
end

function ToggleOptions()
    if ( Gui and Gui:IsShown() ) then
        HideOptions()
    else
        ShowOptions()
    end
end

-- Konfigurationsfenster erzeugen
function MakeGuiConfig()
    if (Gui) then return end
    local id, last, cont
    local Configator = LibStub:GetLibrary("Configator")
    local gui = Configator:Create(setter, getter)
    Gui = gui

    -- Hauptkategorie Addon-Name
    gui:AddCat("IlarosFarm", nil, false, true)

    -- Kategorie "Verfolgung"
    id = gui:AddTab(FarmText_CNF1)
    gui:AddControl(id, "Header",   0,    FarmText_CNF1)
    -- erste Spalte, aktuelle Position sichern, um für zweite Spalte hierher zurückkehren zu können
    last = gui:GetLast(id)
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF1H1)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    local curpos = gui:GetLast(id)
    gui:AddControl(id, "Checkbox", 0, 1, "show.mainmap.mine", FarmText_CNF1SON)
    gui:SetLast(id, curpos)
    gui:AddControl(id, "Checkbox", 0.35, 1, "show.mainmap.mine.all", FarmText_CNF1A)
    gui:AddControl(id, "Checkbox", 0, 3, "show.mainmap.mine.onlyifskilled", FarmText_CNF1MO)
    gui:AddControl(id, "Checkbox", 0, 3, "show.mainmap.mine.onlyiftracked", FarmText_CNF1TO)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    curpos = gui:GetLast(id)
    gui:AddControl(id, "Checkbox", 0, 1, "show.mainmap.herb", FarmText_CNF1SHN)
    gui:SetLast(id, curpos)
    gui:AddControl(id, "Checkbox", 0.35, 1, "show.mainmap.herb.all", FarmText_CNF1A)
    gui:AddControl(id, "Checkbox", 0, 3, "show.mainmap.herb.onlyifskilled", FarmText_CNF1HO)
    gui:AddControl(id, "Checkbox", 0, 3, "show.mainmap.herb.onlyiftracked", FarmText_CNF1TO)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    curpos = gui:GetLast(id)
    gui:AddControl(id, "Checkbox", 0, 1, "show.mainmap.open", FarmText_CNF1STN)
    gui:SetLast(id, curpos)
    gui:AddControl(id, "Checkbox", 0.35, 1, "show.mainmap.open.all", FarmText_CNF1A)
    gui:AddControl(id, "Checkbox", 0, 3, "show.mainmap.open.onlyiftracked", FarmText_CNF1TO)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    curpos = gui:GetLast(id)
    gui:AddControl(id, "Checkbox", 0, 1, "show.mainmap.fish", FarmText_CNF1SFN)
    gui:SetLast(id, curpos)
    gui:AddControl(id, "Checkbox", 0.35, 1, "show.mainmap.fish.all", FarmText_CNF1A)
    gui:AddControl(id, "Checkbox", 0, 3, "show.mainmap.fish.onlyiftracked", FarmText_CNF1TO)
    -- zweite Spalte, an gesicherte Position zurückkehren
    gui:SetLast(id, last)
    gui:AddControl(id, "Subhead",  0.5,    FarmText_CNF1H2)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    curpos = gui:GetLast(id)
    gui:AddControl(id, "Checkbox", 0.5, 1, "show.minimap.mine", FarmText_CNF1SON)
    gui:SetLast(id, curpos)
    gui:AddControl(id, "Checkbox", 0.85, 1, "show.minimap.mine.all", FarmText_CNF1A)
    gui:AddControl(id, "Checkbox", 0.5, 3, "show.minimap.mine.onlyifskilled", FarmText_CNF1MO)
    gui:AddControl(id, "Checkbox", 0.5, 3, "show.minimap.mine.onlyiftracked", FarmText_CNF1TO)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    curpos = gui:GetLast(id)
    gui:AddControl(id, "Checkbox", 0.5, 1, "show.minimap.herb", FarmText_CNF1SHN)
    gui:SetLast(id, curpos)
    gui:AddControl(id, "Checkbox", 0.85, 1, "show.minimap.herb.all", FarmText_CNF1A)
    gui:AddControl(id, "Checkbox", 0.5, 3, "show.minimap.herb.onlyifskilled", FarmText_CNF1HO)
    gui:AddControl(id, "Checkbox", 0.5, 2, "show.minimap.herb.onlyiftracked", FarmText_CNF1TO)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    curpos = gui:GetLast(id)
    gui:AddControl(id, "Checkbox", 0.5, 1, "show.minimap.open", FarmText_CNF1STN)
    gui:SetLast(id, curpos)
    gui:AddControl(id, "Checkbox", 0.85, 1, "show.minimap.open.all", FarmText_CNF1A)
    gui:AddControl(id, "Checkbox", 0.5, 3, "show.minimap.open.onlyiftracked", FarmText_CNF1TO)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    curpos = gui:GetLast(id)
    gui:AddControl(id, "Checkbox", 0.5, 1, "show.minimap.fish", FarmText_CNF1SFN)
    gui:SetLast(id, curpos)
    gui:AddControl(id, "Checkbox", 0.85, 1, "show.minimap.fish.all", FarmText_CNF1A)
    gui:AddControl(id, "Checkbox", 0.5, 3, "show.minimap.fish.onlyiftracked", FarmText_CNF1TO)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")

    gui:AddControl(id, "Subhead",  0,    FarmText_CNF1H3)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Note",     0, 1, 590, 60, FarmText_CNF1NT)

    -- Kategorie "Fundstellen"
    id = gui:AddTab(FarmText_CNF2)
    gui:AddControl(id, "Header",   0,    FarmText_CNF2)
    -- erste Spalte, aktuelle Position sichern, um für zweite Spalte hierher zurückkehren zu können
    last = gui:GetLast(id)
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF2H1)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Checkbox", 0, 1, "mainmap.enable", FarmText_CNF2DW)
    gui:AddControl(id, "Slider",   0, 3, "mainmap.count", 10, 1000, 10, FarmText_CNF2S1)
    gui:AddControl(id, "Slider",   0, 3, "mainmap.opacity", 10, 100, 2, FarmText_CNF2S2)
    gui:AddControl(id, "Slider",   0, 3, "mainmap.iconsize", 4, 64, 1, FarmText_CNF2S3)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Checkbox", 0, 1, "mainmap.tooltip.enable", FarmText_CNF2DT)
    gui:AddControl(id, "Checkbox", 0, 3, "mainmap.tooltip.count", FarmText_CNF2O1)
    gui:AddControl(id, "Checkbox", 0, 3, "mainmap.tooltip.source", FarmText_CNF2O2)
    gui:AddControl(id, "Checkbox", 0, 3, "mainmap.tooltip.seen", FarmText_CNF2O3)
    gui:AddControl(id, "Checkbox", 0, 3, "mainmap.tooltip.rate", FarmText_CNF2O5)
    -- zweite Spalte, an gesicherte Position zurückkehren
    gui:SetLast(id, last)
    gui:AddControl(id, "Subhead",  0.5,    FarmText_CNF2H2)
    gui:AddControl(id, "Note",     0.5, 1, 0, 0, " ")
    gui:AddControl(id, "Checkbox", 0.5, 1, "minimap.enable", FarmText_CNF2DM)
    gui:AddControl(id, "Slider",   0.5, 3, "minimap.count", 1, 50, 1, FarmText_CNF2S1)
    gui:AddControl(id, "Slider",   0.5, 3, "minimap.opacity", 0, 100, 1, FarmText_CNF2S2)
    gui:AddControl(id, "Slider",   0.5, 3, "minimap.iconsize", 4, 64, 1, FarmText_CNF2S3)
    gui:AddControl(id, "Slider",   0.5, 3, "minimap.distance", 100, 5000, 50, FarmText_CNF2S4)
    gui:AddControl(id, "Note",     0.5, 1, 0, 0, " ")
    gui:AddControl(id, "Checkbox", 0.5, 1, "miniicon.enable", FarmText_CNF2DB)
    gui:AddControl(id, "Slider",   0.5, 3, "miniicon.angle", 0, 360, 1, FarmText_CNF2S5)
    gui:AddControl(id, "Slider",   0.5, 3, "miniicon.distance", -80, 80, 1, FarmText_CNF2S6)
    gui:AddControl(id, "Note",     0.5, 1, 0, 0, " ")
    gui:AddControl(id, "Checkbox", 0.5, 1, "minimap.tooltip.enable", FarmText_CNF2DT)
    gui:AddControl(id, "Checkbox", 0.5, 3, "minimap.tooltip.count", FarmText_CNF2O1)
    gui:AddControl(id, "Checkbox", 0.5, 3, "minimap.tooltip.source", FarmText_CNF2O2)
    gui:AddControl(id, "Checkbox", 0.5, 3, "minimap.tooltip.seen", FarmText_CNF2O3)
    gui:AddControl(id, "Checkbox", 0.5, 3, "minimap.tooltip.distance", FarmText_CNF2O4)
    gui:AddControl(id, "Checkbox", 0.5, 3, "minimap.tooltip.rate", FarmText_CNF2O5)

    -- Kategorie "Untersuchung"
    id = gui:AddTab(FarmText_CNF3)
    gui:AddControl(id, "Header",   0,    FarmText_CNF3)
    -- erste Spalte, aktuelle Position sichern, um für zweite Spalte hierher zurückkehren zu können
    last = gui:GetLast(id)
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF3H1)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Checkbox", 0, 1, "fade.enable", FarmText_CNF3FO)
    gui:AddControl(id, "Slider",   0, 3, "fade.distance", 10, 1000, 10, FarmText_CNF3S1)
    gui:AddControl(id, "Slider",   0, 3, "fade.percent", 0, 100, 1, FarmText_CNF3S2)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF3H2)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Checkbox", 0, 1, "track.enable", FarmText_CNF3ET)
    gui:AddControl(id, "Checkbox", 0, 3, "track.circle", FarmText_CNF3O1)
    for _, type in pairs(IlarosFarm.Constants.ProfessionTextures) do
        gui:AddControl(id, "ColorSelect", 0, 6, "track.colour."..type, FarmText_SKL[type]);
    end
    gui:AddControl(id, "Checkbox", 0, 3, "track.current", FarmText_CNF3O2)
    gui:AddControl(id, "Slider",   0, 3, "track.distance", 50, 150, 1, FarmText_CNF3S3)
    gui:AddControl(id, "Slider",   0, 3, "track.opacity", 0, 100, 1, FarmText_CNF3S4)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    -- zweite Spalte, an gesicherte Position zurückkehren
    gui:SetLast(id, last)
    gui:AddControl(id, "Subhead",  0.5,    FarmText_CNF3H3)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Checkbox", 0.5, 1, "anon.enable", FarmText_CNF3DA)
    gui:AddControl(id, "Checkbox", 0.5, 3, "anon.tint", FarmText_CNF3O3)
    gui:AddControl(id, "Slider",   0.5, 3, "anon.opacity", 0, 100, 1, FarmText_CNF3S4)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Subhead",  0.5,    FarmText_CNF3H4)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Checkbox", 0.5, 1, "inspect.enable", FarmText_CNF3MI)
    gui:AddControl(id, "Checkbox", 0.5, 3, "inspect.tint", FarmText_CNF3O4)
    gui:AddControl(id, "Slider",   0.5, 3, "inspect.distance", 1, 100, 1, FarmText_CNF3S5)
    gui:AddControl(id, "Slider",   0.5, 3, "inspect.percent", 0, 100, 1, FarmText_CNF3S6)
    gui:AddControl(id, "Slider",   0.5, 3, "inspect.time", 10, 900, 10, FarmText_CNF3S7)

    -- Kategorie "Austausch"
    id = gui:AddTab(FarmText_CNF4)
    gui:AddControl(id, "Header",   0,    FarmText_CNF4)
    -- erste Spalte, aktuelle Position sichern, um für zweite Spalte hierher zurückkehren zu können
    last = gui:GetLast(id)
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF4H1)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Checkbox", 0, 1, "guild.enable", FarmText_CNF4ES)
    gui:AddControl(id, "Checkbox", 0, 2, "guild.receive", FarmText_CNF4O1)
    gui:AddControl(id, "Checkbox", 0, 2, "guild.print.send", FarmText_CNF4O2)
    gui:AddControl(id, "Checkbox", 0, 2, "guild.print.recv", FarmText_CNF4O3)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF4H2)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Checkbox", 0, 1, "raid.enable", FarmText_CNF4ES)
    gui:AddControl(id, "Checkbox", 0, 2, "raid.receive", FarmText_CNF4O1)
    gui:AddControl(id, "Checkbox", 0, 2, "raid.print.send", FarmText_CNF4O2)
    gui:AddControl(id, "Checkbox", 0, 2, "raid.print.recv", FarmText_CNF4O3)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF4H3)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Checkbox", 0, 1, "personal.print", FarmText_CNF4PM)
    -- zweite Spalte, an gesicherte Position zurückkehren
    gui:SetLast(id, last)
    gui:AddControl(id, "Subhead", 0.55,    FarmText_CNF4H4)
    gui:AddControl(id, "Custom",  0.55, 0, FarmIgnoreFrame); FarmIgnoreFrame:SetParent(gui.tabs[id][3])

    -- Kategorie "Profile"
    id = gui:AddTab(FarmText_CNF5)
    gui:AddControl(id, "Header",   0,    FarmText_CNF5)
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF5H1)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Selectbox",0, 1, "profile.profiles", "profile", FarmText_CNF5EXP)
    gui:AddControl(id, "Button",   0, 1, "profile.delete", FarmText_BtnD)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF5H2)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Text",     0, 1, "profile.name", FarmText_CNF5NPN)
    gui:AddControl(id, "Button",   0, 1, "profile.save", FarmText_BtnNP)
    gui:AddControl(id, "Button",   0, 1, "profile.copy", FarmText_BtnCP)

    -- Hauptkategorie Filter
    gui:AddCat(FarmText_CNFB, nil, false, true)

    -- Fundarten in entsprechende Filter-Tabellen einsortieren
    local itemLists = {}
    local namesSeen = {}
    for name, objid in pairs(IlarosFarm.Nodes.Names) do
        name = IlarosFarm.Util.GetNodeName(objid)
        local gtype = IlarosFarm.Nodes.Objects[objid]:lower()
        if not ( namesSeen[gtype..name] ) then
            namesSeen[gtype..name] = true
            if (not itemLists[gtype]) then itemLists[gtype] = {} end
            local entry = { objid, name }
            local cat = IlarosFarm.Categories.ObjectCategories[objid]
            if (cat) then
                local skill = IlarosFarm.Constants.SkillLevel[cat]
                if (skill) then
                    table.insert(entry, skill)
                end
            end
            table.insert(itemLists[gtype], entry)
        end
    end

    function entrySort(a, b)
        if (b == nil) then return nil end

        local aName = a[2]
        local bName = b[2]
        local aLevel = a[3]
        local bLevel = b[3]

        if bLevel then
            if aLevel then
                if aLevel < bLevel then return true end
                if bLevel < aLevel then return false end
            else
                return true
            end
        elseif aLevel then
            return false
        end
        local comp = aName < bName
        return comp
    end

    -- Kategorie "Bergbau"
    id = gui:AddTab(FarmText_SKL["MINE"])
    gui:MakeScrollable(id)
    gui:AddControl(id, "Header",   0,    FarmText_CNF6)
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF6H)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    local options = {}
    local list = itemLists.mine
    table.sort(list, entrySort)
    for pos, mine in pairs(list) do
        table.insert(options, { "show.mine."..mine[1], mine[2] })
    end
    gui:ColumnCheckboxes(id, 1, options)

    -- Kategorie "Kräuterkunde"
    id = gui:AddTab(FarmText_SKL["HERB"])
    gui:MakeScrollable(id)
    gui:AddControl(id, "Header",   0,    FarmText_CNF7)
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF7H)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    local options = {}
    local list = itemLists.herb
    table.sort(list, entrySort)
    for pos, herb in pairs(list) do
       table.insert(options, { "show.herb."..herb[1], herb[2] })
    end
    gui:ColumnCheckboxes(id, 1, options)

    -- Kategorie "Angeln"
    id = gui:AddTab(FarmText_SKL["FISH"])
    gui:MakeScrollable(id)
    gui:AddControl(id, "Header",   0,    FarmText_CNF8)
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF8H)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    local options = {}
    local list = itemLists.fish
    table.sort(list, entrySort)
    for pos, fish in pairs(list) do
        table.insert(options, { "show.fish."..fish[1], fish[2] })
    end
    gui:ColumnCheckboxes(id, 1, options)

    -- Kategorie "Schatzsuche"
    id = gui:AddTab(FarmText_SKL["OPEN"])
    gui:MakeScrollable(id)
    gui:AddControl(id, "Header",   0,    FarmText_CNF9)
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF9H)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    local options = {}
    local list = itemLists.open
    table.sort(list, entrySort)
    for pos, open in pairs(list) do
        table.insert(options, { "show.open."..open[1], open[2] })
    end
    gui:ColumnCheckboxes(id, 1, options)

    -- Hauptkategorie Information
    gui:AddCat(FarmText_CNFC, nil, false, true)

    -- Kategorie Hilfe
    id = gui:AddTab(FarmText_CNF10)
    gui:AddControl(id, "Header",   0,    FarmText_CNF10)
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF10H1)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_COM)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_VER)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_OPT)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_FRW)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_DRW)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_MINI)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_WRLD)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_CMDH)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_CMDM)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_CMDF)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_CMDT)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_MXD)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_MXN)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF10H2)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_CLKL)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_CLKLA)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_CLKR)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_CLKRA)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Note",     0, 1, 600, 0, FarmText_KBD)

    -- Kategorie Version
    id = gui:AddTab(FarmText_CNF11)
    gui:AddControl(id, "Header",   0,    FarmText_CNF11)
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF11H1)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_CNFVM..IlarosFarm.Var.Version)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_CNFLM)
    gui:AddControl(id, "Note",     0, 1, 0, 0, FarmText_CNFGM)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF11H2)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Note",     0, 1, 600, 0, FarmText_CNFDM)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Subhead",  0,    FarmText_CNF11H3)
    gui:AddControl(id, "Note",     0, 1, 0, 0, " ")
    gui:AddControl(id, "Checkbox", 0, 0, "about.loaded", FarmText_CNFSW)
    gui:AddControl(id, "Note",     0, 1, 600, nil, "")

    -- Any callbacks?
    for name, callback in pairs(GuiHook) do
        callback(gui)
    end
end

GuiHook = {}

function AddCallback(name, callback)
    if (Gui) then
        callback(Gui)
        return
    end

    GuiHook[name] = callback
end

--**************************************
-- Blacklist Frame Functionality
--**************************************

local numIgnoreButtons = 18
SharingBlacklist = {}
SelectedIgnore = 1
LastIgnoredPlayer = nil

function SharingBlacklist_IsPlayerIgnored( name )
    if ( SharingBlacklist[name] ) then
        return true
    else
        return false
    end
end

function SharingBlacklist_Update()
    local numIgnores = #SharingBlacklist
    local nameText;
    local name;
    local ignoreButton;
    if ( numIgnores > 0 ) then
        if ( SelectedIgnore == 0 ) then
            SelectedIgnore = 1
        end
        FarmIgnore_StopIgnoreButton:Enable();
    else
        FarmIgnore_StopIgnoreButton:Disable();
    end

    local ignoreOffset = FauxScrollFrame_GetOffset(FarmIgnore_ScrollFrame);
    local ignoreIndex;
    for i=1, numIgnoreButtons, 1 do
        ignoreIndex = i + ignoreOffset;
        ignoreButton = _G["FarmIgnore_IgnoreButton"..i];
        ignoreButton:SetText(SharingBlacklist[ignoreIndex] or "");
        ignoreButton:SetID(ignoreIndex);
        -- Update the highlight
        if ( ignoreIndex == SelectedIgnore ) then
            ignoreButton:LockHighlight();
        else
            ignoreButton:UnlockHighlight();
        end

        if ( ignoreIndex > numIgnores ) then
            ignoreButton:Hide();
        else
            ignoreButton:Show();
        end
    end

    -- ScrollFrame stuff
    FauxScrollFrame_Update(FarmIgnore_ScrollFrame, numIgnores, numIgnoreButtons, 16);
end

function Blacklist_IgnoreButton_OnClick( button )
    SelectedIgnore = button:GetID()
    SharingBlacklist_Update()
end

function Blacklist_UnignoreButton_OnClick( button )
    local name = SharingBlacklist[SelectedIgnore]
    SharingBlacklist_Remove(name)
end

function SharingBlacklist_Load()
    if ( FarmIgnore ) then
        SharingBlacklist = FarmIgnore
    end
    for i, name in ipairs(SharingBlacklist) do
        SharingBlacklist[name] = i
    end
    SharingBlacklist_Update()
end

function SharingBlacklist_Save()
    for key in pairs(SharingBlacklist) do
        if not ( type(key) == "number" ) then
            SharingBlacklist[key] = nil
        end
    end
    _G.FarmIgnore = SharingBlacklist
end

function SharingBlacklist_Add( name )
    -- name validity checks
    if ( (not name) or name == "" ) then return end
    if ( #name < 2 ) then return end
    name = name:sub(1,1):upper()..name:sub(2)
    local currentSelection = SharingBlacklist[SelectedIgnore]

    if not ( SharingBlacklist[name] ) then
        table.insert(SharingBlacklist, name)
        LastIgnoredPlayer = name
        StaticPopup_Show("ILAROSFARM_REMOVE_BLACKLISTED_NODES")
    end
    table.sort(SharingBlacklist)
    for i, name in ipairs(SharingBlacklist) do
        SharingBlacklist[name] = i
    end
    SelectedIgnore = SharingBlacklist[currentSelection] or 1
    SharingBlacklist_Update()
end

function SharingBlacklist_Remove( name )
    if ( SharingBlacklist[name] ) then
        SharingBlacklist[name] = nil
        for i, ignoreName in ipairs(SharingBlacklist) do
            if ( ignoreName == name ) then
                table.remove(SharingBlacklist, i)
            end
        end
        SelectedIgnore = 1
    end
    table.sort(SharingBlacklist)
    for i, name in ipairs(SharingBlacklist) do
        SharingBlacklist[name] = i
    end
    SharingBlacklist_Update()
end

function SharingBlacklist_RemoveBlacklistedNodes()
    if ( LastIgnoredPlayer ) then
        local numRemoved = 0
        for i, continent in IlarosFarm.Storage.GetAreaIndices() do
            for i, zone in IlarosFarm.Storage.GetAreaIndices(continent) do
                for farmId in IlarosFarm.Storage.ZoneFarmNames(continent, zone) do
                    local result, count = IlarosFarm.Storage.RemoveFarm(continent, zone, farmId, LastIgnoredPlayer)
                    numRemoved = numRemoved + count
                end
            end
        end
        if ( numRemoved > 0 ) then
            PlaySound("igQuestLogAbandonQuest");
            IlarosFarm.MiniNotes.ForceUpdate()
            StaticPopup_Show("ILAROSFARM_REMOVED_NODE_COUNT", numRemoved)
        end
    end
    LastIgnoredPlayer = nil
end

function SharingBlacklist_CountBlacklistedNodes()
    local count = 0
    if ( LastIgnoredPlayer ) then
        local storage = IlarosFarm.Storage
        for i, continent in storage.GetAreaIndices() do
            for i, zone in storage.GetAreaIndices(continent) do
                for farmId in storage.ZoneFarmNames(continent, zone) do
                    for _, _, _, _, _, _, source in storage.ZoneFarmNodes( continent, zone, farmId ) do
                        if ( source == LastIgnoredPlayer ) then
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    return count
end

StaticPopupDialogs["ILAROSFARM_ADD_SHARING_IGNORE"] = {
    text = FarmText_DLG1,
    button1 = FarmText_BtnA,
    button2 = FarmText_BtnC,
    hasEditBox = 1,
    maxLetters = 12,
    OnAccept = function( self )
        local name = self.editBox:GetText();
        SharingBlacklist_Add(name);
    end,
    OnShow = function( self )
        _G[self:GetName().."EditBox"]:SetFocus();
    end,
    OnHide = function( self )
        if ( ChatFrameEditBox:IsShown() ) then
            ChatFrameEditBox:SetFocus();
        end
        _G[self:GetName().."EditBox"]:SetText("");
    end,
    EditBoxOnEnterPressed = function( self )
        local name = _G[self:GetParent():GetName().."EditBox"]:GetText();
        self:GetParent():Hide();
        SharingBlacklist_Add(name);
    end,
    EditBoxOnEscapePressed = function( self )
        self:GetParent():Hide();
    end,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
};

StaticPopupDialogs["ILAROSFARM_REMOVE_BLACKLISTED_NODES"] = {
    text = FarmText_DLG2,
    button1 = FarmText_BtnY,
    button2 = FarmText_BtnN,
    OnAccept = function( self )
        StaticPopup_Show("ILAROSFARM_CONFIRM_REMOVE_BLACKLISTED_NODES", SharingBlacklist_CountBlacklistedNodes())
    end,
    timeout = 0,
    whileDead = 1,
    exclusive = 1,
    hideOnEscape = 1
};

StaticPopupDialogs["ILAROSFARM_CONFIRM_REMOVE_BLACKLISTED_NODES"] = {
    text = FarmText_DLG3,
    button1 = FarmText_BtnY,
    button2 = FarmText_BtnN,
    OnAccept = function( self )
        SharingBlacklist_RemoveBlacklistedNodes()
    end,
    timeout = 0,
    whileDead = 1,
    exclusive = 1,
    hideOnEscape = 1
};

StaticPopupDialogs["ILAROSFARM_REMOVED_NODE_COUNT"] = {
    text = FarmText_DLG4,
    button1 = FarmText_BtnO,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
};
