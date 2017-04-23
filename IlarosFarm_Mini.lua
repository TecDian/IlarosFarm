----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für Notizen auf der Minikarte
----------------------------------------------------------------------------

-- reference to the Astrolabe mapping library
local Astrolabe = DongleStub(IlarosFarm.AstrolabeVersion)

local timeDiff = 0
local checkDiff = 0
local numNotesUsed = 0

local SHADED_TEXTURE = "Interface\\AddOns\\IlarosFarm\\images\\white"

local miniIcon = CreateFrame("Button", "IlarosFarm_MinimapOptionsButton", Minimap);
IlarosFarm.MiniIcon = miniIcon

miniIcon:SetToplevel(true)
miniIcon:SetMovable(true)
miniIcon:SetFrameStrata("LOW")
miniIcon:SetWidth(33)
miniIcon:SetHeight(33)
miniIcon:SetPoint("RIGHT", Minimap, "LEFT", 0,0)
miniIcon:Show()
miniIcon.icon = miniIcon:CreateTexture("", "BACKGROUND")
miniIcon.icon:SetTexture("Interface\\AddOns\\IlarosFarm\\images\\farmorb")
miniIcon.icon:SetTexCoord(0.075, 0.925, 0.075, 0.925)
miniIcon.icon:SetWidth(17)
miniIcon.icon:SetHeight(17)
miniIcon.icon:SetPoint("CENTER", miniIcon, "CENTER", 0,0)
miniIcon.mask = miniIcon:CreateTexture("", "OVERLAY")
miniIcon.mask:SetTexCoord(0.0, 0.6, 0.0, 0.6)
miniIcon.mask:SetTexture("Interface\\Minimap\\Minimap-TrackingBorder")
miniIcon.mask:SetAllPoints(true)

local function mouseDown()
    miniIcon.icon:SetTexCoord(0, 1, 0, 1)
end
local function mouseUp()
    miniIcon.icon:SetTexCoord(0.075, 0.925, 0.075, 0.925)
end

local moving = false
local function dragStart()
    moving = true
end
local function dragStop()
    miniIcon.icon:SetTexCoord(0.075, 0.925, 0.075, 0.925)
    moving = false
end

local function click(obj, button)
    if (button == "LeftButton") then
        if (IsModifierKeyDown()) then
            IlarosFarm.NodeSearch.Toggle()
        else
            local dtype = "minimap.enable"
            local cur = IlarosFarm.Config.GetSetting(dtype)
            IlarosFarm.Config.SetSetting(dtype, not cur)
        end
    elseif (button == "RightButton") then
        if (IsModifierKeyDown()) then
            IlarosFarm.Config.ToggleOptions()
        else
            IlarosFarm.Report.Toggle()
        end
    end
end

local function reposition(angle)
    if (not IlarosFarm.Config.GetSetting("miniicon.enable")) then
        miniIcon:Hide()
        return
    end
    miniIcon:Show()
    if (not angle) then angle = IlarosFarm.Config.GetSetting("miniicon.angle") or 0.5
    else IlarosFarm.Config.SetSetting("miniicon.angle", angle) end
    angle = angle
    local distance = IlarosFarm.Config.GetSetting("miniicon.distance")

    local width,height = Minimap:GetWidth()/2, Minimap:GetHeight()/2
    width = width+distance
    height = height+distance

    local iconX, iconY
    iconX = width * sin(angle)
    iconY = height * cos(angle)

    miniIcon:ClearAllPoints()
    miniIcon:SetPoint("CENTER", Minimap, "CENTER", iconX, iconY)
end
miniIcon.Reposition = reposition

local function update()
    if moving then
        local curX, curY = GetCursorPosition()
        local miniX, miniY = Minimap:GetCenter()
        miniX = miniX * Minimap:GetEffectiveScale()
        miniY = miniY * Minimap:GetEffectiveScale()

        local relX = miniX - curX
        local relY = miniY - curY
        local angle = math.deg(math.atan2(relX, relY)) + 180

        reposition(angle)
    end
end

miniIcon:RegisterForClicks("LeftButtonUp","RightButtonUp")
miniIcon:RegisterForDrag("LeftButton")
miniIcon:SetScript("OnMouseDown", mouseDown)
miniIcon:SetScript("OnMouseUp", mouseUp)
miniIcon:SetScript("OnDragStart", dragStart)
miniIcon:SetScript("OnDragStop", dragStop)
miniIcon:SetScript("OnClick", click)
miniIcon:SetScript("OnUpdate", update)
miniIcon:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_PARENT")
    GameTooltip:SetText("|cff00ff00IlarosFarm|r")
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(FarmText_CLKL)
    GameTooltip:AddLine(FarmText_CLKLA)
    GameTooltip:AddLine(FarmText_CLKR)
    GameTooltip:AddLine(FarmText_CLKRA)
	GameTooltip:Show()
end)
miniIcon:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

local sideIcon
--moved into a function so we can delay LDB creation until after saved variables have been loaded.
function miniIcon.CreateLDB()
    if LibStub then
        local LibDataBroker = LibStub:GetLibrary("LibDataBroker-1.1", true)
        if LibDataBroker then
            local Desaturated = not IlarosFarm.Config.GetSetting("minimap.enable") --we want the opposite boolean of the enabled state
            sideIcon = LibDataBroker:NewDataObject("IlarosFarm", {
                type = "launcher",
                icon = "Interface\\AddOns\\IlarosFarm\\images\\farmorb",
                OnClick = function(self, button)
                    click(self, button)
                end,
            })
        end
    end
end

function miniIcon.Update()
    local enabled = IlarosFarm.Config.GetSetting("minimap.enable")
    miniIcon.icon:SetDesaturated(not enabled)
    --this will allow IlarosFarm to desaturate its icon, only on slidebar.
    if sideIcon and sideIcon.button and sideIcon.button.icon then
        sideIcon.button.icon:SetDesaturated(not enabled)
    end
end

-- table to store current active Minimap Notes objects
IlarosFarm.MiniNotes.Notes = {}

function IlarosFarm.MiniNotes.Show()
    if ( IlarosFarm.Config.GetSetting("minimap.enable") ) then
        if ( FarmMiniNoteUpdateFrame:IsShown() ) then
            IlarosFarm.MiniNotes.ForceUpdate()
        else
            FarmMiniNoteUpdateFrame:Show()
        end
    end
end

function IlarosFarm.MiniNotes.ForceUpdate()
    if ( FarmMiniNoteUpdateFrame:IsShown() ) then
        IlarosFarm.MiniNotes.UpdateMinimapNotes(0, true)
    end
end

function IlarosFarm.MiniNotes.Hide()
    FarmMiniNoteUpdateFrame:Hide()
    numNotesUsed = 0
    for i, note in pairs(IlarosFarm.MiniNotes.Notes) do
        Astrolabe:RemoveIconFromMinimap(note)
    end
end

local function GetMinimapNote( index )
    local note = IlarosFarm.MiniNotes.Notes[index]
    if not ( note ) then
        note = CreateFrame("Button", "FarmNote"..index, Minimap, "FarmNoteTemplate")
        IlarosFarm.MiniNotes.Notes[index] = note
        note:SetID(index)
    end
    return note
end

function IlarosFarm.MiniNotes.UpdateMinimapNotes(timeDelta, force)
    local setting = IlarosFarm.Config.GetSetting

    if ( Astrolabe.WorldMapVisible and (not Astrolabe:GetCurrentPlayerPosition()) ) then
        return
    end

    if not ( setting("minimap.enable") ) then
        IlarosFarm.MiniNotes.Hide()
        return
    end

    local updateIcons = false
    local updateNodes = false

    if ( force or IlarosFarm.Command.IsUpdated("minimap.update") ) then
        updateIcons = true
        updateNodes = true
    else
        checkDiff = checkDiff + timeDelta
        timeDiff = timeDiff + timeDelta
        if (checkDiff > IlarosFarm.Var.NoteCheckInterval) then
            updateNodes = true
            checkDiff = 0
            updateIcons = true
            timeDiff = 0

        elseif (timeDiff > IlarosFarm.Var.NoteUpdateInterval) then
            updateIcons = true
            timeDiff = 0

        end
    end

    if ( updateNodes ) then
        local c, z, px, py = IlarosFarm.Util.GetPositionInCurrentZone()
        if ( not (c and z and px and py) ) or ( c <= 0 ) or ( z <= 0 ) then
            IlarosFarm.MiniNotes.Hide()
            return
        end

        local maxDist = setting("minimap.distance", 800)
        local displayNumber = setting("minimap.count", 20)

        local getDist = maxDist
        local getNumber = displayNumber

        numNotesUsed = 0
        for i, nodeC,nodeZ, nodeID, nodePos, nodeDist, nodeX,nodeY, nodeCount, gtype, nodeHarvested, nodeInspected, nodeSource
        in IlarosFarm.Storage.ClosestNodesInfo(c, z, px, py, getNumber, getDist, IlarosFarm.Config.DisplayFilter_MiniMap) do
            if ( numNotesUsed < displayNumber ) then
                local nodeDist = Astrolabe:ComputeDistance(c,z,px,py, nodeC,nodeZ,nodeX,nodeY)
                if (nodeDist <= maxDist) then
                    numNotesUsed = numNotesUsed + 1

                    -- need to position and label the corresponding button
                    local farmNote = GetMinimapNote(numNotesUsed)
                    farmNote.id = nodeID
                    farmNote.continent = nodeC
                    farmNote.zone = nodeZ
                    farmNote.index = nodePos
                    farmNote.source = nodeSource
                    farmNote.dist = nodeDist

                    local result = Astrolabe:PlaceIconOnMinimap(farmNote, nodeC, nodeZ, nodeX, nodeY)
                    -- a non-zero results some failure when adding the icon to the Minimap
                    if ( result ~= 0 ) then
                        numNotesUsed = numNotesUsed - 1
                    end
                end
            end
        end

        local notes = IlarosFarm.MiniNotes.Notes
        for i = (numNotesUsed + 1), #(IlarosFarm.MiniNotes.Notes) do
            Astrolabe:RemoveIconFromMinimap(notes[i]);
        end
    end

    if ( updateIcons or updateNodes ) then
        local now = time()

        local normSize = setting("minimap.iconsize")
        local normOpac = setting("minimap.opacity") / 100
        local fadeEnab = setting("fade.enable")
        local fadeDist = setting("fade.distance")
        local fadePerc = setting("fade.percent") / 100
        local tracEnab = setting("track.enable")
        local tracCirc = setting("track.circle")
        local tracStyl = setting("track.style")
        local tracCurr = setting("track.current")
        local tracDist = setting("track.distance")
        local tracOpac = setting("track.opacity") / 100
        local inspEnab = setting("inspect.enable")
        local inspTint = setting("inspect.tint")
        local inspDist = setting("inspect.distance")
        local inspPerc = setting("inspect.percent") / 100
        local inspTime = setting("inspect.time")
        local anonEnab = setting("anon.enable")
        local anonTint = setting("anon.tint")
        local anonOpac = setting("anon.opacity") / 100
        local tooltip = setting("minimap.tooltip.enable")

        for i = 1, numNotesUsed do
            local farmNote = GetMinimapNote(i)
            local nodeID = farmNote.id
            local nodeC = farmNote.continent
            local nodeZ= farmNote.zone
            local nodePos = farmNote.index
            local nodeSource = farmNote.source

            local iconColor = "normal"
            local opacity = normOpac
            local nodeDist = Astrolabe:GetDistanceToIcon(farmNote)

            if ( nodeDist ) then
                local selectedTexture, trimTexture = IlarosFarm.Util.GetNodeTexture(nodeID)

                -- If this icon has not been verified
                if ( anonEnab and nodeSource and (nodeSource ~= 'REQUIRE') and (nodeSource ~= "IMPORTED") ) then
                    opacity = anonOpac
                    if anonTint then
                        iconColor = "red"
                    end
                end

                -- If node is within tracking distance
                if ( tracEnab and (nodeDist <= tracDist) ) then
                    if ( (not tracCurr) or IlarosFarm.Util.IsNodeTracked(nodeID) ) then
                        if (tracCirc) then
                            selectedTexture = SHADED_TEXTURE
                            trimTexture = false
                        end
                        opacity = tracOpac
                    end
                end

                -- If we need to fade the icon (because of great distance)
                if ( fadeEnab ) then
                    if nodeDist >= fadeDist then
                        opacity = opacity * (1 - fadePerc)
                    elseif ( nodeDist > tracDist ) then
                        local range = math.max(fadeDist - tracDist, 0)
                        local posit = math.min(nodeDist - tracDist, range)
                        if (range > 0) then
                            opacity = opacity * (1 - ( fadePerc * (posit / range) ))
                        end
                    end
                end

                -- If inspecting is enabled
                if (inspEnab) then
                    -- If we are within inspect distance of this item, mark it as inspected
                    if (nodeDist < inspDist) then
                        IlarosFarm.Storage.SetNodeInspected(nodeC, nodeZ, nodeID, nodePos)
                        if (inspTint) then
                            iconColor = "green"
                        end
                        opacity = normOpac

                    -- If we've recently seen this node, set its transparency
                    else
                        local nodeInspected = IlarosFarm.Storage.GetNodeInspected(nodeC, nodeZ, nodeID, nodePos)
                        if (nodeInspected) then
                            local delta = math.max(now - nodeInspected, 0)
                            if (inspTime > 0) and (delta < inspTime) then
                                opacity = opacity * (1 - ( inspPerc * (1 - (delta / inspTime)) ))
                            end
                        end
                    end
                end

                -- Set the texture
                farmNote:SetNormalTexture(selectedTexture)
                farmNote:SetWidth(normSize)
                farmNote:SetHeight(normSize)

                if (tooltip and not farmNote:IsMouseEnabled()) then
                    farmNote:EnableMouse(true)
                elseif (not tooltip and farmNote:IsMouseEnabled()) then
                    farmNote:EnableMouse(false)
                end

                local farmNoteTexture = farmNote:GetNormalTexture()

                -- Check to see if we need to trim the border off
                if (trimTexture) then
                    farmNoteTexture:SetTexCoord(0.08,0.92,0.08,0.92)
                else
                    farmNoteTexture:SetTexCoord(0,1,0,1)
                end

                -- If this node is unverified, then make it reddish
                if ( iconColor == "red" ) then
                    farmNoteTexture:SetVertexColor(0.9,0.4,0.4)
                elseif ( iconColor == "green" ) then
                    farmNoteTexture:SetVertexColor(0.4,0.9,0.4)
                else
                    local r, g, b = 1, 1, 1;
                    if ( selectedTexture == SHADED_TEXTURE ) then
                        local nodeType = tostring(IlarosFarm.Nodes.Objects[nodeID]) -- in case nil is returned, call tostring
                        if ( setting("track.colour."..nodeType) ) then
                            r, g, b = setting("track.colour."..nodeType)
                        end
                    end
                    farmNoteTexture:SetVertexColor(r, g, b);
                end
                farmNoteTexture:SetAlpha(opacity)
            end
        end
    end
end

-- Pass on any node clicks
function IlarosFarm.MiniNotes.MiniNoteOnClick()
    Minimap_OnClick(Minimap)
end

function IlarosFarm.MiniNotes.MiniNoteOnEnter(frame)
    local setting = IlarosFarm.Config.GetSetting
    local tooltip = GameTooltip

    local enabled = setting("minimap.tooltip.enable")
    if (not enabled) then
        return
    end

    local showcount = setting("minimap.tooltip.count")
    local showsource = setting("minimap.tooltip.source")
    local showseen = setting("minimap.tooltip.seen")
    local showdist = setting("minimap.tooltip.distance")
    local showrate = setting("minimap.tooltip.rate")

    tooltip:SetOwner(frame, "ANCHOR_BOTTOMLEFT")

    local id = frame.id
    local name = IlarosFarm.Util.GetNodeName(id)
    local dist = Astrolabe:GetDistanceToIcon(frame)
    local _, _, count, gType, harvested, inspected, who = IlarosFarm.Storage.GetNodeInfo(frame.continent, frame.zone, id, frame.index)
    local last = inspected or harvested

    tooltip:ClearLines()
    tooltip:AddLine(name)
    if (count > 0 and showcount) then
        tooltip:AddLine(string.format(FarmText_TT2, count))
    end
    if (who and showsource) then
        if (who == "REQUIRE") then
            tooltip:AddLine(FarmText_TT8)
        elseif (who == "IMPORTED") then
            tooltip:AddLine(FarmText_TT7)
        else
            tooltip:AddLine(string.format(FarmText_TT6, who:gsub(",", ", ")))
        end
    end
    if (last and last > 0 and showseen) then
        tooltip:AddLine(string.format(FarmText_TT4, IlarosFarm.Util.SecondsToTime(time()-last)))
    end
    if (showdist) then
        tooltip:AddLine(string.format(FarmText_TT3,dist))
    end

    if ( showrate ) then
        local num = IlarosFarm.Config.GetSetting("minimap.tooltip.rate.num")
        IlarosFarm.Tooltip.AddDropRates(tooltip, id, frame.continent, frame.zone, num)
    end
    tooltip:Show()
end
