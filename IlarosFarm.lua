----------------------------------------------------------------------------
-- IlarosFarm
-- Hauptmodul
----------------------------------------------------------------------------

-- Addon-Deklaration
IlarosFarm = {
    Api = {},
    Categories = {},
    Comm = {},
    Command = {},
    Convert = {},
    Config = {},
    Constants = {},
    DropRates = {},
    Event = {},
    Interface = {},
    Locale = {},
    MapNotes = {},
    MiniNotes = {},
    Nodes = {},
    Notifications = {},
    SpecialCases = {},
    Storage = {},
    Tooltip = {},
    Util = {},
    Var = {},
    ZoneTokens = {},
}

-- lokalisierte Namen der gesuchten Gameobjects
IlarosFarm.Nodes.Names = Nodes.Names

-- Anbindung an Astrolabe
IlarosFarm.AstrolabeVersion = "Astrolabe-0.4"

-- globale Variablen
IlarosFarm.Var.Version = GetAddOnMetadata("IlarosFarm", "Version") 
IlarosFarm.Var.NoteUpdateInterval = 0.1
IlarosFarm.Var.NoteCheckInterval = 5.0
IlarosFarm.Var.MaxNumNotes = 25
IlarosFarm.Var.Loaded = false
IlarosFarm.Var.ClosestCheck = 0.4
IlarosFarm.Var.RecordFlag = 0
IlarosFarm.Var.CurrentNode = ""
IlarosFarm.Var.CurrentAction = ""

IlarosFarm.Var.InCity = false
IlarosFarm.Var.MapOpen = false
IlarosFarm.Var.UpdateWorldMap = -1

IlarosFarm.Var.Skills = { }
IlarosFarm.Var.ZoneData = { }
IlarosFarm.Var.MainMapItem = { }

IlarosFarm.Var.Closest = {playerC=0,playerZ=0,playerX=0,playerY=0,px=0,py=0,items={},count=0}

IlarosFarm.Var.LastZone = {}

IlarosFarm.Var.BorderWidth = 15

IlarosFarm.Var.StorePosX = 1
IlarosFarm.Var.StorePosY = 2
IlarosFarm.Var.StoreCount = 3
IlarosFarm.Var.StoreHarvested = 4
IlarosFarm.Var.StoreInspected = 5
IlarosFarm.Var.StoreSource = 6
