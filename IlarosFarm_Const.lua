----------------------------------------------------------------------------
-- IlarosFarm
-- Modul mit einigen Konstanten -> anderweitig integrieren
----------------------------------------------------------------------------

local metatable = { __index = getfenv(0) }
setmetatable( IlarosFarm.Constants, metatable )
setfenv(1, IlarosFarm.Constants)

IlarosFarm.Var.Skills.OPEN = true

-- benötigtes Fertigkeitsniveau
SkillLevel = {
	-- Bergbau WoW
	["ORE_COPPER"]      = 1,
	["ORE_TIN"]         = 65,
	["ORE_INCENDICITE"] = 65,
	["ORE_SILVER"]      = 75,
	["ORE_BLOODSTONE"]  = 75,
	["ORE_IRON"]        = 125,
	["ORE_INDURIUM"]    = 150,
	["ORE_GOLD"]        = 155,
	["ORE_MITHRIL"]     = 175,
	["ORE_DARKIRON"]    = 230,
	["ORE_TRUESILVER"]  = 205,
	["ORE_THORIUM"]     = 235,
	["ORE_RTHORIUM"]    = 255,
	["ORE_OBSIDIAN"]    = 305,
	-- Bergbau TBC
	["ORE_FELIRON"]     = 275,
	["ORE_ADAMANTITE"]  = 325,
	["ORE_ETERNIUM"]    = 350,
	["ORE_KHORIUM"]     = 375,
	["ORE_RADAMANTITE"] = 350,
	["ORE_NETHERCITE"]  = 275,
    -- Bergbau WotLK
	["ORE_COBALT"]      = 350,
	["ORE_RCOBALT"]     = 375,
	["ORE_SARONITE"]    = 400,
	["ORE_RSARONITE"]   = 425,
	["ORE_TITANIUM"]    = 450,
	-- Kräuter WoW
	["HERB_PEACEBLOOM"]         = 1,
	["HERB_SILVERLEAF"]         = 1,
	["HERB_EARTHROOT"]          = 15,
	["HERB_MAGEROYAL"]          = 50,
	["HERB_BRIARTHORN"]         = 70,
	["HERB_SWIFTTHISTLE"]       = 50,
	["HERB_STRANGLEKELP"]       = 85,
	["HERB_BRUISEWEED"]         = 100,
	["HERB_WILDSTEELBLOOM"]     = 115,
	["HERB_GRAVEMOSS"]          = 120,
	["HERB_KINGSBLOOD"]         = 125,
	["HERB_LIFEROOT"]           = 150,
	["HERB_FADELEAF"]           = 160,
	["HERB_GOLDTHORN"]          = 170,
	["HERB_KHADGARSWHISKER"]    = 185,
	["HERB_WINTERSBITE"]        = 195,
	["HERB_FIREBLOOM"]          = 205,
	["HERB_PURPLELOTUS"]        = 210,
	["HERB_WILDVINE"]           = 210,
	["HERB_ARTHASTEAR"]         = 220,
	["HERB_SUNGRASS"]           = 230,
	["HERB_BLINDWEED"]          = 235,
	["HERB_GHOSTMUSHROOM"]      = 245,
	["HERB_GROMSBLOOD"]         = 250,
	["HERB_GOLDENSANSAM"]       = 260,
	["HERB_DREAMFOIL"]          = 270,
	["HERB_MOUNTAINSILVERSAGE"] = 280,
	["HERB_PLAGUEBLOOM"]        = 285,
	["HERB_ICECAP"]             = 290,
	["HERB_BLACKLOTUS"]         = 300,
	-- Kräuter TBC
	["HERB_FELWEED"]            = 300,
	["HERB_DREAMINGGLORY"]      = 315,
	["HERB_TEROCONE"]           = 325,
	["HERB_RAGVEIL"]            = 325,
	["HERB_NETHERBLOOM"]        = 350,
	["HERB_FLAMECAP"]           = 335,
	["HERB_BLOODTHISTLE"]       = 1,
	["HERB_ANCIENTLICHEN"]      = 340,
	["HERB_NIGHTMAREVINE"]      = 365,
	["HERB_MANATHISTLE"]        = 375,
	["HERB_NETHERDUST"]         = 350,
	-- Kräuter WotLK
	["HERB_GOLDCLOVER"]         = 350,
	["HERB_TIGERLILY"]          = 375,
	["HERB_TALANDRASROSE"]      = 385,
	["HERB_LICHBLOOM"]          = 425,
	["HERB_ICETHORN"]           = 435,
	["HERB_FROZENHERB"]         = 415,
	["HERB_FROSTLOTUS"]         = 450,
	["HERB_ADDERSTONGUE"]       = 400,
	["HERB_FIRETHORN"]          = 360,
}

-- lists item categories which are tracked by a tracking skill
-- that is different from their farm type
TrackingOverrides = {
	["TREASURE_BLOODPETAL"] = "HERB",
}

TrackingTextures = {
	["Interface\\Icons\\Spell_Nature_Earthquake"]   = "MINE",
	["Interface\\Icons\\INV_Misc_Flower_02"]        = "HERB",
	["Interface\\Icons\\Racial_Dwarf_FindTreasure"] = "OPEN",
	["Interface\\Icons\\INV_Misc_Fish_02"]          = "FISH",
}

ProfessionTextures = {
	["Interface\\Icons\\INV_Pick_02"]               = "MINE",
	["Interface\\Icons\\INV_Box_01"]                = "OPEN",
	["Interface\\Icons\\Trade_Herbalism"]           = "HERB",
	["Interface\\Icons\\Trade_Fishing"]             = "FISH",
}