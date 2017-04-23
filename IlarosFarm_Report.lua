----------------------------------------------------------------------------
-- IlarosFarm
-- Modul für Suchberichtfenster
----------------------------------------------------------------------------

local THROTTLE_COUNT = 25
local THROTTLE_RATE = 1

IlarosFarm.Report = {}
local private = {}
local public = IlarosFarm.Report

-- reference to the Astrolabe mapping library
local Astrolabe = DongleStub(IlarosFarm.AstrolabeVersion)

local REPORT_LINES = 30

private.frame = CreateFrame("Frame", "IlarosFarmReportFrame", UIParent)
local frame = private.frame
public.Frame = frame

function public.Show()
    IlarosFarm.Config.HideOptions()
    frame:Show()
    local oTop, oLeft = frame:GetTop(), frame:GetLeft()
    frame:SetClampedToScreen(true)
    local nTop, nLeft = frame:GetTop(), frame:GetLeft()
    if (oTop ~= nTop or oLeft ~= nLeft) then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", "UIParent", "BOTTOMLEFT", nLeft, nTop)
    end
    frame:SetClampedToScreen(false)
end

function public.Hide()
    frame:Hide()
end

function public.Toggle()
    if (frame:IsShown()) then
        public.Hide()
    else
        public.Show()
    end
end

function public.IsOpen()
    if (frame:IsVisible()) then return true end
    return false
end

private.needsUpdate = false
function public.NeedsUpdate(delay)
    if not delay then delay = 0.1 end
    private.needsUpdate = delay
end


frame:Hide()
local top = IlarosFarm.Config.GetSetting("report.top")
local left = IlarosFarm.Config.GetSetting("report.left")
if (top and left) then
    frame:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", top,left)
else
    frame:SetPoint("CENTER", "UIParent", "CENTER")
end
frame:SetWidth(900)
frame:SetHeight(600)
frame:SetFrameStrata("DIALOG")
frame:SetToplevel(true)
frame:SetMovable(true)
frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
frame:SetBackdropColor(0,0,0, 0.95)
frame:SetScript("OnShow", function() public.NeedsUpdate() end)
-- Fenster soll mit Esc verlassen werden können
table.insert(UISpecialFrames, "IlarosFarmReportFrame")

frame.Updater = CreateFrame("Button", "", UIParent)
frame.Updater:SetScript("OnUpdate", function(self, delay) private.UpdateHandler(delay) end)

frame.Drag = CreateFrame("Button", "", frame)
frame.Drag:SetPoint("TOPLEFT", frame, "TOPLEFT", 10,-5)
frame.Drag:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10,-5)
frame.Drag:SetHeight(22)
frame.Drag:SetNormalTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
frame.Drag:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
frame.Drag:SetScript("OnMouseDown", function() frame:StartMoving() end)
frame.Drag:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() IlarosFarm.Config.SetSetting("report.left", frame:GetLeft()) IlarosFarm.Config.SetSetting("report.top", frame:GetTop()) end)
frame.Drag:SetText(FarmText_DLG6)
frame.Drag:SetNormalFontObject("GameFontHighlightHuge")

frame.Done = CreateFrame("Button", "", frame, "OptionsButtonTemplate")
frame.Done:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
frame.Done:SetScript("OnClick", function() public.Hide() end)
frame.Done:SetText(DONE)

frame.Config = CreateFrame("Button", "", frame, "OptionsButtonTemplate")
frame.Config:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
frame.Config:SetScript("OnClick", function() public.Hide() IlarosFarm.Config.Show() end)
frame.Config:SetText(FarmText_BtnK)

-- Häufigkeitsbericht öffnen
frame.NodeSearch = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
frame.NodeSearch:SetPoint("BOTTOM", frame, "BOTTOM", -100, 10)
frame.NodeSearch:SetScript("OnClick", function() frame:Hide() IlarosFarm.NodeSearch.Show() end)
frame.NodeSearch:SetText(FarmText_BtnS)

frame.SearchBox = CreateFrame("EditBox", "", frame)
frame.SearchBox:SetPoint("TOP", frame.Drag, "BOTTOM", 0, -5)
frame.SearchBox:SetPoint("LEFT", frame, "LEFT", 10, 0)
frame.SearchBox:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
frame.SearchBox:SetAutoFocus(false)
frame.SearchBox:SetMultiLine(false)
frame.SearchBox:SetHeight(26)
frame.SearchBox:SetTextInsets(6,6,6,6)
frame.SearchBox:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
frame.SearchBox:SetBackdropColor(0,0,0, 0.95)
frame.SearchBox:SetFontObject("GameFontHighlight")
frame.SearchBox:SetScript("OnTextChanged", function() public.NeedsUpdate(0.5) end)
frame.SearchBox:SetScript("OnEscapePressed", public.Hide)
frame.SearchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

function private.AddText(obj, name, x, ftype)
    if (not ftype) then ftype = "GameFontHighlight" end
    if (obj.lastName) then
        local lastobj = obj[obj.lastName]
        lastobj:SetWidth(x-lastobj.left)
    end
    obj[name] = obj:CreateFontString("", "OVERLAY", ftype)
    obj[name]:SetPoint("TOPLEFT", obj, "TOPLEFT", x,0)
    obj[name]:SetJustifyH("LEFT")
    obj[name]:Show()
    obj[name].left = x
    if (ftype ~= "GameFontHighlight") then obj[name]:SetText(name)
    else obj[name]:SetText("") end
    obj.lastName = name
end

local blank = frame:CreateTexture("")
blank:SetTexture(0,0,0,0)

function private.AddTexts(obj, ftype, icon)
    if (icon) then
        private.AddText(obj, "Type", 15, ftype)
        obj.Type.Icon = obj:CreateTexture("", "OVERLAY")
        obj.Type.Icon:SetPoint("TOPLEFT", obj, "TOPLEFT")
        obj.Type.Icon:SetWidth(13)
        obj.Type.Icon:SetHeight(13)
        obj.Type.Icon:SetTexture(blank)

        obj.Highlight = CreateFrame("CheckButton", "", obj)
        obj.Highlight:SetFrameLevel(obj:GetFrameLevel() - 1)
        obj.Highlight:SetPoint("TOPLEFT", 0, -1)
        obj.Highlight:SetPoint("BOTTOMRIGHT")
        obj.Highlight:SetCheckedTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
        obj.Highlight:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
        obj.Highlight:SetNormalTexture(blank)
        obj.Highlight:SetScript("OnClick", function (me)
            local pos = me.parent.pos
            if (pos) then
                local c,z,n,i,x,y = unpack(private.results.data[pos])
                local sig = strjoin(":", c,z,n,i)
                if (private.results.mark[sig]) then
                    private.results.mark[sig] = nil
                else
                    private.results.mark[sig] = strjoin(":", x,y)
                end
                private.UpdateResults()
            end
        end)
        obj.Highlight:Hide()
        obj.Highlight.parent = obj
        private.AddText(obj, "Region", 260, ftype)
        private.AddText(obj, "X", 440, ftype)
        private.AddText(obj, "Y", 480, ftype)
        private.AddText(obj, "Dist", 520, ftype)
        private.AddText(obj, "Source", 580, ftype)
    else
        private.AddText(obj, FarmText_LST1, 0, ftype)
        private.AddText(obj, FarmText_LST2, 260, ftype)
        private.AddText(obj, "X", 440, ftype)
        private.AddText(obj, "Y", 480, ftype)
        private.AddText(obj, FarmText_LST3, 520, ftype)
        private.AddText(obj, FarmText_LST4, 580, ftype)
    end
    obj:Show()
end

frame.Results = CreateFrame("Frame", "", frame)
frame.Results:SetPoint("TOPLEFT", frame.SearchBox, "BOTTOMLEFT", 0, -25)
frame.Results:SetPoint("BOTTOM", frame.Done, "TOP", 0, 5)
frame.Results:SetWidth(740)
frame.Results:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
})
frame.Results:SetBackdropColor(0,0,0, 0.65)


frame.Results.Scroll = CreateFrame("ScrollFrame", "IlarosFarmResultsScroll", frame.Results, "FauxScrollFrameTemplate")
frame.Results.Scroll:SetPoint("TOPLEFT", frame.Results, "TOPLEFT", 0, -5)
frame.Results.Scroll:SetPoint("BOTTOMRIGHT", frame.Results, "BOTTOMRIGHT", -27, 5)
do
    local function ScrollUpdate()
        private.UpdateResults()
    end
    frame.Results.Scroll:SetScript("OnVerticalScroll", function ( self, offset )
        FauxScrollFrame_OnVerticalScroll(self, offset, 16, ScrollUpdate)
    end)
    frame.Results.Scroll:SetScript("OnShow", ScrollUpdate)
end

frame.Results.Header = CreateFrame("Frame", "", frame)
frame.Results.Header:SetPoint("TOPLEFT", frame.Results, "TOPLEFT", 10, -5)
frame.Results.Header:SetPoint("RIGHT", frame.Results, "RIGHT")
frame.Results.Header:SetHeight(18)
private.AddTexts(frame.Results.Header, "GameFontNormalLarge")

for i=1, REPORT_LINES do
    local result = CreateFrame("Frame", "", frame)
    frame.Results[i] = result
    if (i>1) then
        result:SetPoint("TOPLEFT", frame.Results[i-1], "BOTTOMLEFT")
    else
        result:SetPoint("TOPLEFT", frame.Results.Header, "BOTTOMLEFT")
    end
    result:SetPoint("RIGHT", frame.Results.Scroll, "RIGHT", -24)
    result:SetHeight(15)
    result:Show()
    private.AddTexts(result, nil, true)
end

frame.Actions = CreateFrame("Frame", "", frame)
frame.Actions:SetPoint("TOPLEFT", frame.Results, "TOPRIGHT", 5, 0)
frame.Actions:SetPoint("BOTTOM", frame.Results, "BOTTOM")
frame.Actions:SetPoint("RIGHT", frame, "RIGHT", -10, 0)

frame.Actions.SelectAll = CreateFrame("Button", "", frame.Actions, "OptionsButtonTemplate")
frame.Actions.SelectAll:SetPoint("TOPLEFT", frame.Actions, "TOPLEFT")
frame.Actions.SelectAll:SetPoint("RIGHT", frame.Actions, "RIGHT")
frame.Actions.SelectAll:SetText(FarmText_BtnMS)
frame.Actions.SelectAll:SetScript("OnClick", function (me)
    for pos = 1, private.results.size do
        local c,z,n,i,x,y = unpack(private.results.data[pos])
        local sig = strjoin(":", c,z,n,i)
        private.results.mark[sig] = strjoin(":", x,y)
    end
    private.UpdateResults()
end)

frame.Actions.SelectNone = CreateFrame("Button", "", frame.Actions, "OptionsButtonTemplate")
frame.Actions.SelectNone:SetPoint("TOPLEFT", frame.Actions.SelectAll, "BOTTOMLEFT")
frame.Actions.SelectNone:SetPoint("RIGHT", frame.Actions, "RIGHT")
frame.Actions.SelectNone:SetText(FarmText_BtnUS)
frame.Actions.SelectNone:SetScript("OnClick", function (me)
    for pos = 1, private.results.size do
        local c,z,n,i,x,y = unpack(private.results.data[pos])
        local sig = strjoin(":", c,z,n,i)
        private.results.mark[sig] = nil
    end
    private.UpdateResults()
end)

frame.Actions.SelectClear = CreateFrame("Button", "", frame.Actions, "OptionsButtonTemplate")
frame.Actions.SelectClear:SetPoint("TOPLEFT", frame.Actions.SelectNone, "BOTTOMLEFT", 0, -10)
frame.Actions.SelectClear:SetPoint("RIGHT", frame.Actions, "RIGHT")
frame.Actions.SelectClear:SetText(FarmText_BtnUA)
frame.Actions.SelectClear:SetScript("OnClick", function (me)
    for sig, data in pairs(private.results.mark) do
        private.results.mark[sig] = nil
    end
    private.UpdateResults()
end)


frame.Actions.SelectCount = frame.Actions:CreateFontString("", "OVERLAY", "GameFontHighlight")
frame.Actions.SelectCount:SetPoint("TOPLEFT", frame.Actions.SelectClear, "BOTTOMLEFT", 0, 0)
frame.Actions.SelectCount:SetPoint("RIGHT", frame.Actions, "RIGHT")
frame.Actions.SelectCount:SetHeight(16)
frame.Actions.SelectCount:SetText(FarmText_CMN)

frame.Actions.SendEdit = CreateFrame("EditBox", "", frame)
frame.Actions.SendEdit:SetPoint("TOPLEFT", frame.Actions.SelectCount, "BOTTOMLEFT", 0, -10)
frame.Actions.SendEdit:SetPoint("RIGHT", frame.Actions, "RIGHT")
frame.Actions.SendEdit.Uninitialized = true
frame.Actions.SendEdit:SetText(FarmText_STP)
frame.Actions.SendEdit:SetTextColor(0.5, 0.5, 0.5)
frame.Actions.SendEdit:SetAutoFocus(false)
frame.Actions.SendEdit:SetMultiLine(false)
frame.Actions.SendEdit:SetHeight(26)
frame.Actions.SendEdit:SetTextInsets(6,6,6,6)
frame.Actions.SendEdit:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
frame.Actions.SendEdit:SetBackdropColor(0,0,0, 0.95)
frame.Actions.SendEdit:SetFontObject("GameFontHighlight")
frame.Actions.SendEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
frame.Actions.SendEdit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
frame.Actions.SendEdit:SetScript("OnEditFocusGained", function(self)
    if (self.Uninitialized) then
        self:SetTextColor(1,1,1)
        self:SetText("")
        self.Uninitialized = false
    end
end)

StaticPopupDialogs["ILAROSFARM_REPORT_TRANSMIT"] = {
    text = FarmText_DLG7,
    button1 = TEXT(YES),
    button2 = TEXT(NO),
    OnAccept = function()
        local dialog = StaticPopupDialogs["ILAROSFARM_REPORT_TRANSMIT"]
        IlarosFarm.Report.ConfirmNodeTransmit(dialog.who, dialog.howmany)
    end,
    timeout = 0,
    whileDead = 1,
    exclusive = 1,
    showAlert = 1,
    hideOnEscape = 1
};

function public.ConfirmNodeTransmit(who, howmany)
    howmany = tonumber(howmany) or 0
    if (who and howmany > 0) then
        SendAddonMessage("IlarosFarm", ("SENDNODES:OFFER:%d"):format(howmany), "WHISPER", who)
        private.sendingTo = who:lower()
    end
end

frame.Actions.SendSelected = CreateFrame("Button", "", frame.Actions, "OptionsButtonTemplate")
frame.Actions.SendSelected:SetPoint("TOPLEFT", frame.Actions.SendEdit, "BOTTOMLEFT", 0, 3)
frame.Actions.SendSelected:SetPoint("RIGHT", frame.Actions, "RIGHT")
frame.Actions.SendSelected:SetText(FarmText_BtnSM)
frame.Actions.SendSelected:SetScript("OnClick", function (me)
    local who = frame.Actions.SendEdit:GetText()
    if (who and who ~= "" and not frame.Actions.SendEdit.Uninitialized) then
        StaticPopupDialogs["ILAROSFARM_REPORT_TRANSMIT"].howmany = me.count
        StaticPopupDialogs["ILAROSFARM_REPORT_TRANSMIT"].who = who
        StaticPopup_Show("ILAROSFARM_REPORT_TRANSMIT", me.count, who)
    end
end)
frame.Actions.SendSelected:Disable()

local tip = {}
local function setStatus(status, noTip)
    frame.Actions.SendStatus:SetText(status)
    if (noTip == true) then return end
    while #tip > 25 do table.remove(tip, 1) end
    table.insert(tip, status)
    frame.Actions.MarkTip:SetText(strjoin("\n", unpack(tip)))
end
frame.Actions.SendStatus = frame.Actions:CreateFontString("", "OVERLAY", "GameFontHighlight")
frame.Actions.SendStatus:SetPoint("TOPLEFT", frame.Actions.SendSelected, "BOTTOMLEFT", 0, 2)
frame.Actions.SendStatus:SetPoint("RIGHT", frame.Actions, "RIGHT")
frame.Actions.SendStatus:SetHeight(16)
frame.Actions.SendStatus:SetTextColor(0.3, 0.5, 1.0)
frame.Actions.SendStatus:SetText("")

StaticPopupDialogs["ILAROSFARM_REPORT_DELETE"] = {
    text = FarmText_DLG8,
    button1 = TEXT(YES),
    button2 = TEXT(NO),
    OnAccept = function()
        IlarosFarm.Report.ConfirmNodeDeletes();
    end,
    timeout = 0,
    whileDead = 1,
    exclusive = 1,
    showAlert = 1,
    hideOnEscape = 1
};

function public.ConfirmNodeDeletes()
    local deleteList = {}
    for sig, data in pairs(private.results.mark) do
        local c,z,n,i = strsplit(":", sig)
        local x,y = strsplit(":", data)
        c=tonumber(c) z=tonumber(z) n=tonumber(n) i=tonumber(i) x=tonumber(x) y=tonumber(y)
        local px, py = IlarosFarm.Storage.GetNodeInfo(c,z,n,i)
        if (px and py and math.abs(x-px)<0.001 and math.abs(y-py)<0.001) then
            -- This node is in the correct location
            table.insert(deleteList, { c,z,n,i })
        end
    end

    table.sort(deleteList, function(a,b)
        if a[1] ~= b[1] then return a[1] < b[1] end
        if a[2] ~= b[2] then return a[2] < b[2] end
        if a[3] ~= b[3] then return a[3] < b[3] end
        return a[4] > b[4]
    end)

    for i = 1, #deleteList do
        IlarosFarm.Storage.RemoveNode(unpack(deleteList[i]))
    end
end

frame.Actions.DeleteSelected = CreateFrame("Button", "", frame.Actions, "OptionsButtonTemplate")
frame.Actions.DeleteSelected:SetPoint("TOPLEFT", frame.Actions.SendSelected, "BOTTOMLEFT", 0, -14)
frame.Actions.DeleteSelected:SetPoint("RIGHT", frame.Actions, "RIGHT")
frame.Actions.DeleteSelected:SetText(FarmText_BtnDM)
frame.Actions.DeleteSelected:SetScript("OnClick", function (me)
    StaticPopup_Show("ILAROSFARM_REPORT_DELETE", ("%d"):format(me.count))
end)
frame.Actions.DeleteSelected:Disable()

StaticPopupDialogs["ILAROSFARM_REPORT_POOL"] = {
    text = FarmText_DLG10,
    button1 = TEXT(YES),
    button2 = TEXT(NO),
    OnAccept = function()
        IlarosFarm.Report.ConfirmNodePools();
    end,
    timeout = 0,
    whileDead = 1,
    exclusive = 1,
    showAlert = 1,
    hideOnEscape = 1
};

function public.ConfirmNodePools()
    local deleteList = {}
    local poolList = {}
    for sig, data in pairs(private.results.mark) do
        local c,z,n,i = strsplit(":", sig)
        n=tonumber(n)
        if IlarosFarm.Nodes.Pools[n] then
            local x,y = strsplit(":", data)
            c=tonumber(c) z=tonumber(z) i=tonumber(i) x=tonumber(x) y=tonumber(y)
            local px, py = IlarosFarm.Storage.GetNodeInfo(c,z,n,i)
            if (px and py and math.abs(x-px)<0.001 and math.abs(y-py)<0.001) then
                -- This node is in the correct location
                table.insert(poolList, { IlarosFarm.Nodes.Pools[n],"FISH",c,z,x,y,nil,false })
                table.insert(deleteList, { c,z,n,i })
            end
        end
    end

    table.sort(deleteList, function(a,b)
        if a[1] ~= b[1] then return a[1] < b[1] end
        if a[2] ~= b[2] then return a[2] < b[2] end
        if a[3] ~= b[3] then return a[3] < b[3] end
        return a[4] > b[4]
    end)

    for i = 1, #deleteList do
        IlarosFarm.Storage.AddNode(unpack(poolList[i]))
        IlarosFarm.Storage.RemoveNode(unpack(deleteList[i]))
    end
end

frame.Actions.PoolSelected = CreateFrame("Button", "", frame.Actions, "OptionsButtonTemplate")
frame.Actions.PoolSelected:SetPoint("TOPLEFT", frame.Actions.DeleteSelected, "BOTTOMLEFT", 0, -14)
frame.Actions.PoolSelected:SetPoint("RIGHT", frame.Actions, "RIGHT")
frame.Actions.PoolSelected:SetText(FarmText_BtnFS)
frame.Actions.PoolSelected:SetScript("OnClick", function (me)
    StaticPopup_Show("ILAROSFARM_REPORT_POOL", ("%d"):format(me.count))
end)
frame.Actions.PoolSelected:Disable()

frame.Actions.MarkTip = frame.Actions:CreateFontString("", "OVERLAY", "GameFontNormalSmall")
frame.Actions.MarkTip:SetPoint("TOPLEFT", frame.Actions.PoolSelected, "BOTTOMLEFT", 0, -40)
frame.Actions.MarkTip:SetPoint("RIGHT", frame.Actions)
frame.Actions.MarkTip:SetPoint("BOTTOM", frame.Actions)
frame.Actions.MarkTip:SetJustifyV("TOP")
frame.Actions.MarkTip:SetJustifyH("LEFT")
frame.Actions.MarkTip:SetText(FarmText_MRKN);

private.LastButton = nil
private.SearchButtons = {}
function public.AddButton(buttonName, filter)
    if (private.SearchButtons[buttonName]) then
        private.SearchButtons[buttonName].filter = filter
    end
    local button = CreateFrame("CheckButton", "IlarosFarm_ReportFilterCheckbox_"..buttonName, frame, "OptionsCheckButtonTemplate")
    if (private.LastButton) then
        button:SetPoint("LEFT", _G[private.LastButton:GetName().."Text"], "RIGHT", 5, 0)
    else
        button:SetPoint("TOPLEFT", frame.SearchBox, "BOTTOMLEFT", 0,  0)
    end
    local text = _G[button:GetName().."Text"]
    text:SetText(buttonName)
    button:SetScript("PostClick", private.SearchButtonClickHandler)
    button:SetHitRectInsets(0, -text:GetWidth(), 0, 0)

    button.filter = filter
    button:SetChecked(1)
    button.active = true

    private.SearchButtons[buttonName] = button
    private.LastButton = button
end

local function empty() return false end

private.results = {
    size = 0,
    data = {},
    mark = {}
}

function private.UpdateResults()
    local offset, pos, result
    offset = 0
    if private.results.size < REPORT_LINES then
        frame.Results.Scroll:Hide()
    else
        frame.Results.Scroll:Show()
        FauxScrollFrame_Update(frame.Results.Scroll, private.results.size, REPORT_LINES, 16)
        offset = FauxScrollFrame_GetOffset(frame.Results.Scroll)
    end
    for line = 1, REPORT_LINES do
        local result = frame.Results[line]
        pos = offset + line
        if (pos > private.results.size) then
            result.Type:SetText("")
            result.Region:SetText("")
            result.X:SetText("")
            result.Y:SetText("")
            result.Dist:SetText("")
            result.Source:SetText("")
            result.Type.Icon:SetTexture(blank)
            result.Highlight:SetChecked(false)
            result.Highlight:Hide()
        else
            local c,z,n,i,x,y,_,_,_,s,g = unpack(private.results.data[pos])
            local d = Astrolabe:ComputeDistance(c,z,x,y, Astrolabe:GetCurrentPlayerPosition())
            local t = IlarosFarm.Util.GetNodeTexture(n)
            result.Type:SetText(IlarosFarm.Util.GetNodeName(n))
            result.Region:SetText(IlarosFarm.Util.ZoneNames[c][z])
            result.X:SetText(string.format("%0.01f", x*100))
            result.Y:SetText(string.format("%0.01f", y*100))
            result.Dist:SetText(d and string.format("%d", d) or "∞")
            result.Source:SetText(s)
            result.Type.Icon:SetTexture(t)
            if (private.results.mark[strjoin(":", c,z,n,i)]) then
                result.Highlight:SetChecked(true)
            else
                result.Highlight:SetChecked(false)
            end
            result.Highlight:Show()
            result.pos = pos
        end
    end

    local markcount = 0
    for k,v in pairs(private.results.mark) do
        local c,z,n,i = strsplit(":", k)
        local x,y = strsplit(":", v)
        c=tonumber(c) z=tonumber(z) n=tonumber(n) i=tonumber(i) x=tonumber(x) y=tonumber(y)
        local px, py = IlarosFarm.Storage.GetNodeInfo(c, z, n, i)
        if (px and py and math.abs(x-px)<0.001 and math.abs(y-py)<0.001) then
            markcount = markcount + 1
        else
            private.results.mark[k] = nil
        end
    end

    if (markcount > 0) then
        frame.Actions.SendSelected:Enable()
        frame.Actions.DeleteSelected:Enable()
        frame.Actions.PoolSelected:Enable()
    else
        frame.Actions.SendSelected:Disable()
        frame.Actions.DeleteSelected:Disable()
        frame.Actions.PoolSelected:Disable()
    end
    frame.Actions.SendSelected.count = markcount
    frame.Actions.DeleteSelected.count = markcount
    frame.Actions.PoolSelected.count = markcount

    frame.Actions.SelectCount:SetText(FarmText_CMN..markcount)
end

function IlarosFarmResultsScroll()
    private.UpdateResults()
end

local function filter(searchString, ...)
    local show = false
    local f, s, var = string.gmatch(searchString, "[%p%w]+")
    while true do
        local match = f(s, var)
        var = match
        if ( var == nil ) then
            break
        end

        if ( match:sub(1, 1) == '"' ) then
            local nextToken = f(s, var)
            while ( nextToken ) do
                match = match .. " " .. nextToken
                if ( nextToken:sub(-1) == '"' ) then
                    break
                end
                nextToken = f(s, var)
            end
            match = match:sub(2, #match - 1)
        end

        for filterName, button in pairs(private.SearchButtons) do
            if ( button.active and button.filter(match, ...) ) then
                show = true
                break
            end
        end
        if ( show ) then
            break
        end
    end
    return show
end

function public.UpdateDisplay()
    local parameter = frame.SearchBox:GetText() or ""

    private.results.size = 0
    for i, continent in IlarosFarm.Storage.GetAreaIndices() do
        for i, zone in IlarosFarm.Storage.GetAreaIndices(continent) do
            for id, gtype in IlarosFarm.Storage.ZoneFarmNames(continent, zone) do
                for index in IlarosFarm.Storage.ZoneFarmNodes(continent, zone, id) do
                    local posX, posY, count, gType, harvested, inspected, source = IlarosFarm.Storage.GetNodeInfo(continent, zone, id, index)

                    if (source == "REQUIRE") then source = FarmText_TT8
                    elseif (source == "IMPORTED") then source = FarmText_TT7
                    elseif (not source) then source = ""
                    end

                    if ( (parameter == "") or filter(parameter, continent, zone, id, index, posX, posY, count, harvested, inspected, source, gType) ) then
                        local size = private.results.size + 1
                        if not private.results.data[size] then private.results.data[size] = {} end
                        local data = private.results.data[size]
                        data[1]  = continent
                        data[2]  = zone
                        data[3]  = id
                        data[4]  = index
                        data[5]  = posX
                        data[6]  = posY
                        data[7]  = count
                        data[8]  = harvested
                        data[9]  = inspected
                        data[10] = source
                        data[11] = gType
                        private.results.size = size
                    end
                end
            end
        end
    end
    private.needsUpdate = false
    private.UpdateResults()
end

function private.SearchButtonClickHandler(button)
    if ( button:GetChecked() ) then
        button.active = true
    else
        button.active = false
    end
    public.NeedsUpdate()
end

local checkUpdate = 0
function private.UpdateHandler(delay)
    if frame:IsVisible() and private.needsUpdate then
        private.needsUpdate = private.needsUpdate - delay
        if private.needsUpdate < 0 then
            private.needsUpdate = false
            public.UpdateDisplay()
        end
    end
    checkUpdate = checkUpdate + delay
    if (checkUpdate > THROTTLE_RATE) then
        private.SendNodes()
        checkUpdate = 0
    end
end

private.queue = {}
function public.SendFeedback(who, action, result)
    if not who then return end

    if (private.sendingTo and who:lower() == private.sendingTo) then
        if (action == "PROMPT") then
            setStatus(FarmText_TLK1)
        elseif (action == "ACCEPT") then
            setStatus(FarmText_TLK2)
            local list = {}
            for sig, data in pairs(private.results.mark) do
                table.insert(list, sig..":"..data)
            end
            table.insert(private.queue, { to = who, list = list, pos = 1 })
        elseif (action == "REJECT") then
            setStatus(FarmText_TLK3)
        elseif (action == "TIMEOUT") then
            setStatus(FarmText_TLK4)
        elseif (action == "BUSY") then
            setStatus(FarmText_TLK5)
        elseif (action == "CLOSED") then
            setStatus(FarmText_TLK6)
        elseif (action == "COMPLETE") then
            setStatus(FarmText_TLK7)
        elseif (action == "CONTINUE") then
            if (private.queue and private.queue[1] and private.queue[1].paused) then
                private.queue[1].paused = nil
            end
        end
    end
    if (private.recvFrom and who:lower() == private.recvFrom:lower()) then
        if (action == "RECV") then
            setStatus(FarmText_TLK8..private.recvCount, true)
            private.recvCount = private.recvCount + 1
        elseif (action == "DONE") then
            setStatus(FarmText_TLK9..private.recvCount)
            private.recvFrom = nil
            private.recvCount = 0
        elseif (action == "ABORTED") then
            setStatus(FarmText_TLK10..private.recvCount)
            private.recvFrom = nil
            private.recvCount = 0
        end
        private.UpdateResults()
    end
    if (action == "ACCEPTED") then
        setStatus(FarmText_TLK711)
        private.recvFrom = who
        private.recvCount = 0
    end
end


function private.SendNodes()
    if (private.queue and private.queue[1]) then
        local q = private.queue[1]
        local who = q.to
        if (q.paused) then
            if (time() - q.paused > 30) then
                table.remove(private.queue, 1)
                SendAddonMessage("IlarosFarm", "SENDNODES:ABORTED", "WHISPER", who)
                setStatus(FarmText_TLK12)
            end
            return
        end
        local size = #(q.list)
        local start = q.pos
        local limit = math.min(size,start+THROTTLE_COUNT)
        for pos=start, limit do
            local c,z,n,i,x,y = strsplit(":", q.list[pos])
            c=tonumber(c) z=tonumber(z) n=tonumber(n) i=tonumber(i) x=tonumber(x) y=tonumber(y)
            local t = IlarosFarm.ZoneTokens.GetZoneToken(c,z)
            local px, py = IlarosFarm.Storage.GetNodeInfo(c,z,n,i)
            if (px and py and math.abs(x-px)<0.001 and math.abs(y-py)<0.001) then
                -- This node is in the correct location
                sendMessage = strjoin(";", n, c, t, x, y, "")
                SendAddonMessage("GathX", sendMessage, "WHISPER", who)
            end
            setStatus(FarmText_TLK13..(pos-1), true)
            q.pos = pos
        end
        if (limit == size) then
            table.remove(private.queue, 1)
            SendAddonMessage("IlarosFarm", "SENDNODES:DONE", "WHISPER", who)
        else
            SendAddonMessage("IlarosFarm", "SENDNODES:PAUSE", "WHISPER", who)
            q.paused = time()
        end
    end
end

-- Auswahloptionen für Suchfeld
-- Anwenden auf Typ
function filterFunction(parameter, continent, zone, nodeid, index, x,y, count, harvest, inspect, source, gtype)
    local nodeName = IlarosFarm.Util.GetNodeName(nodeid)
    if (nodeName and nodeName:lower():find(parameter:lower(), 1, true)) then return true end
    if (not nodeName) then DEFAULT_CHAT_FRAME:AddMessage(FarmText_UKNN..tostring(nodeid)) end
    return false
end
IlarosFarm.Report.AddButton(FarmText_OPT1, filterFunction)

-- Anwenden auf Region
function filterFunction(parameter, continent, zone, nodeid, index, x,y, count, harvest, inspect, source, gtype)
    if (continent and zone) then
        local cdata = IlarosFarm.Util.ZoneNames[continent]
        if (cdata and cdata[zone]) then
            local zoneName = tostring(cdata[0] or "") .. " " .. tostring(cdata[zone] or "")
            if (zoneName:lower():find(parameter:lower(), 1, true)) then return true end
        end
    end
    return false
end
IlarosFarm.Report.AddButton(FarmText_OPT2, filterFunction)

-- Anwenden auf Quelle
function findSource(source, ...)
    local value, found
    for i = 1, select("#", ...) do
        value = select(i, ...)
        found = value:find(source, 1, true)
        if (found == 1) then return value end
    end
    return false
end
function filterFunction(parameter, continent, zone, nodeid, index, x,y, count, harvest, inspect, source, gtype)
    if (findSource(parameter:lower(), strsplit(",", source:lower())) ~= false) then return true end
    return false
end
IlarosFarm.Report.AddButton(FarmText_OPT3, filterFunction)
