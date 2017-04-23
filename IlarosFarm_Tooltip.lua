----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für Tooltips
----------------------------------------------------------------------------

setmetatable(IlarosFarm.Tooltip, {__index = getfenv(0)})
setfenv(1, IlarosFarm.Tooltip)

function AddDropRates( tooltip, nodeId, cont, zone, maxDropsToShow )
    if not ( maxDropsToShow ) then maxDropsToShow = 5 end

    -- Fischschwärme durch die zugehörigen Fische ersetzen
    for fish, pool in pairs(IlarosFarm.Nodes.Pools) do
        if pool == nodeId then nodeId = fish end
    end
    local total = IlarosFarm.DropRates.GetDropsTotal(nodeId)

    cont = nil
    zone = nil

    if ( total and (total > 0) ) then
        tooltip:AddLine(FarmText_TT5)
        local numLeft = 0
        for i, item, count in IlarosFarm.DropRates.ObjectDrops(nodeId, cont, zone, "DESC") do
            local itemName, itemLink, itemRarity, _, _, _, _, _, _, invTexture = GetItemInfo(item)
            if ( itemName and (i <= maxDropsToShow) ) then
                tooltip:AddDoubleLine(itemLink, string.format("x%0.2f", count/total))
                tooltip:AddTexture(invTexture)
            else
                numLeft = numLeft + 1
            end
        end
        if ( numLeft > 0 ) then
            tooltip:AddLine(string.format(FarmText_TT1, numLeft))
        end
    end
end


-- Spieltooltips für Erz- und Kräuterstellen abfangen, um das benötigte Fertigkeitsniveau hinzufügen zu können
function IlarosFarm.GameTooltip_OnShow ()

        if GameTooltip:NumLines() ~= 2 then return end

        local line = {}
        for n = 1, 2 do
          local left = _G["GameTooltipTextLeft"..n]
          local right = _G["GameTooltipTextRight"..n]
          if not left or not left:IsShown() then return end
          if right and right:IsShown() then return end
          table.insert(line, left)
        end

        local requires = line[2]:GetText()
        local profession = requires:match("^Requires%s(%a+)$")
        if not profession
        or profession ~= "Mining" and profession ~= "Herbalism" then return end

        local nodeName = line[1]:GetText()
        local nodeID = IlarosFarm.Nodes.Names[nodeName]
        if not nodeID then return end

        local category = IlarosFarm.Categories.ObjectCategories[nodeID]
        if not category then return end

        local skill = IlarosFarm.Constants.SkillLevel[category]
        if not skill then return end

        local width = line[2]:GetStringWidth()
        line[2]:SetText(requires.." "..skill)
        width = line[2]:GetStringWidth() - width
        if width > 0 then GameTooltip:SetWidth(GameTooltip:GetWidth() + width) end

end

GameTooltip:HookScript("OnShow", IlarosFarm.GameTooltip_OnShow)