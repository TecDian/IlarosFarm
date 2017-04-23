----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für Benachrichtigungen
----------------------------------------------------------------------------

local metatable = { __index = getfenv(0) }
setmetatable( IlarosFarm.Notifications, metatable )
setfenv(1, IlarosFarm.Notifications)

Tooltip = nil -- will be set by the OnLoad function
Messages = {}

local function DisplayNotification()
	if ( IsLoggedIn() and Messages[1] ) then
		Tooltip:ClearLines()
		if not ( Tooltip:IsShown() ) then
			Tooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
		end
		local C = HIGHLIGHT_FONT_COLOR
		Tooltip:SetText(FarmText_SYS3, C.r, C.g, C.b)
		for _, text in ipairs(Messages) do
			Tooltip:AddLine("———————————————————————————————————————————————————") -- I'd perfer if this produced a solid line :/
			Tooltip:AddLine(text, nil, nil, nil, true)
		end
		Tooltip:Show()
	end
end

function AddInfo( text )
	table.insert(Messages, text)
	DisplayNotification()
end


function OnLoad( tooltip )
	Tooltip = tooltip
	tooltip:RegisterEvent("PLAYER_LOGIN")
end

function OnShow( tooltip )
	tooltip.timeVisible = 0
end

function OnHide( tooltip )
	Messages = {}
end

function OnUpdate( tooltip, elapsed )
	timeVisible = tooltip.timeVisible
	timeVisible = timeVisible + elapsed
	if ( MouseIsOver(tooltip) ) then
		tooltip.timeVisible = 0
		tooltip:Show()
	else
		if ( timeVisible > 30 ) then
			tooltip:FadeOut(10)
			tooltip.timeVisible = -1000
		else
			tooltip.timeVisible = timeVisible
		end
	end
end

function OnEvent(self, event, ...)
	if ( event == "PLAYER_LOGIN" ) then
		DisplayNotification()
	end
end