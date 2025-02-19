-- Gui.lua
-- Configuration GUI for CastHistoryTracker.

local Dewdrop = AceLibrary("Dewdrop-2.0")
local CastHistoryTracker = CastHistoryTrackerNamespace.CastHistoryTracker


----------------------------------------------------
-- UI Element Defaults
----------------------------------------------------

local defaultAnchors = {
    FontString  = "CENTER",
    Button      = "CENTER",
    CheckButton = "CENTER",
    EditBox     = "TOP",
    ScrollFrame = "TOPLEFT",
    Dropdown    = "TOPRIGHT",
}


local defaultFonts = {
    FontString  = "GameFontHighlight",
    CheckButton = "GameFontNormal",
    ButtonLabel = "GameFontHighlight",
    SpellRowText = "GameFontNormal",
}


local defaultFont = defaultFonts.FontString


local defaultTemplates = {
    CheckButton = "UICheckButtonTemplate",
    EditBox     = "InputBoxTemplate",
    Dropdown    = "UIDropDownMenuTemplate",
    ScrollFrame = "UIPanelScrollFrameTemplate",
}


----------------------------------------------------
-- UI Element Creation Functions
----------------------------------------------------

local function CreateFontStringElement(parent, data)
    -- Creates a FontString UI element.
    local label = parent:CreateFontString(nil, "OVERLAY", data.font or defaultFont)
    label:SetPoint(data.anchor or defaultAnchors.FontString, parent, "CENTER", data.x, data.y)
    label:SetText(data.text)
    label:SetFont("Fonts\\FRIZQT__.TTF", data.size, "OUTLINE")
    return label
end


local function CreateButtonElement(parent, data)
    -- Creates a Button UI element.
    local button = CreateFrame("Button", data.name, parent)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetPoint(data.anchor or defaultAnchors.Button, parent, "CENTER", data.x, data.y)
    button:SetNormalTexture(data.texture)
    button:SetHighlightTexture(data.texture)
    button:GetHighlightTexture():SetBlendMode("ADD")

    local buttonLabel = parent:CreateFontString(nil, "OVERLAY", data.buttonLabelFont or defaultFonts.ButtonLabel)
    buttonLabel:SetPoint("BOTTOM", button, "TOP", 0, 5)
    buttonLabel:SetText(data.label)
    buttonLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

    button:SetScript("OnClick", data.onClick)
    return button
end


local function CreateCheckButtonElement(parent, data)
    -- Creates a CheckButton UI element.
    local checkbox = CreateFrame("CheckButton", nil, parent, data.template or defaultTemplates.CheckButton)
    checkbox:SetPoint(data.anchor or defaultAnchors.CheckButton, data.x, data.y)

    checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", data.textFontStyle or defaultFonts.CheckButton)
    checkbox.text:SetPoint("BOTTOM", checkbox, "TOP", 0, 3)
    checkbox.text:SetText(data.label)

    checkbox:SetScript("OnClick", function(self)
        CastHistoryTracker:HandleCheckboxBehavior(self, data)
    end)
    checkbox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(checkbox, "ANCHOR_RIGHT")
        GameTooltip:SetText(data.tooltip, 1, 1, 0)
        GameTooltip:Show()
    end)
    checkbox:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return checkbox
end


local function CreateEditBoxElement(parent, data)
    -- Creates an EditBox UI element.
    local inputField = CreateFrame("EditBox", data.key, parent, data.template or defaultTemplates.EditBox)
    inputField:SetWidth(data.width)
    inputField:SetHeight(data.height)
    inputField:SetPoint(data.anchor or defaultAnchors.EditBox, parent, "BOTTOM", data.x, data.y)
    inputField:SetAutoFocus(false)
    inputField:SetMaxLetters(data.maxLetters)
    inputField:SetText(data.defaultText)

    local function OnEditFocusGainedHandler()
        if inputField:GetText() == data.defaultText then
            inputField:SetText("")
        end
    end

    local function OnEditFocusLostHandler()
        if inputField:GetText() == "" then
            inputField:SetText(data.defaultText)
        end
    end

    local function OnEnterPressedHandler()
        CastHistoryTracker:AddSpellToFilterList(inputField:GetText())
        inputField:SetText("")
        inputField:ClearFocus()
    end

    inputField:SetScript("OnEditFocusGained", OnEditFocusGainedHandler)
    inputField:SetScript("OnEditFocusLost", OnEditFocusLostHandler)
    inputField:SetScript("OnEnterPressed", OnEnterPressedHandler)

    return inputField
end


local function CreateScrollFrameElement(parent, data)
    -- Creates a ScrollFrame UI element.
    local scrollFrame = CreateFrame("ScrollFrame", data.name, parent, data.template or defaultTemplates.ScrollFrame)
    scrollFrame:SetPoint(data.anchor or defaultAnchors.ScrollFrame, parent, "TOPLEFT", data.x, data.y)
    scrollFrame:SetWidth(data.width)
    scrollFrame:SetHeight(data.height)
    scrollFrame:SetBackdrop(data.backdrop)
    scrollFrame:SetBackdropColor(0, 0, 0, 0.5)
    scrollFrame:SetBackdropBorderColor(0.5, 0.5, 0.5)

    local scrollChild = CreateFrame("Frame", data.name .. "Child", scrollFrame)
    scrollChild:SetWidth(data.width - 20)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    local scrollbar = getglobal(scrollFrame:GetName() .. "ScrollBar")
    scrollbar:ClearAllPoints()
    if string.find(data.name, "Left") then
        scrollbar:SetPoint("TOPRIGHT", scrollFrame, "TOPLEFT", 16, -16)
        scrollbar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMLEFT", 16, 16)
    else
        scrollbar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -16, -16)
        scrollbar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -16, 16)
    end
    return scrollFrame, scrollChild, scrollbar
end


local function CreateDropdownElement(parent, data)
    -- Creates a Dropdown UI element.
    local dropdown = CreateFrame("Button", data.name, parent, data.template or defaultTemplates.Dropdown)
    dropdown:SetPoint(data.anchor or defaultAnchors.Dropdown, parent, "TOPRIGHT", data.x, data.y)
    UIDropDownMenu_SetWidth(data.width, dropdown)

    local function Dropdown_OnClick(clickedButton)
        UIDropDownMenu_SetSelectedName(dropdown, clickedButton:GetText())
        CastHistoryTracker.selectedDropdownValue = clickedButton:GetText()
        data.onSelect(clickedButton:GetText())
    end

    local function Dropdown_Initialize()
        for name, value in pairs(data.options) do
            local info = {
                text  = name,
                value = value,
                func  = function() Dropdown_OnClick(this) end
            }
            UIDropDownMenu_AddButton(info)
        end
    end

    UIDropDownMenu_Initialize(dropdown, Dropdown_Initialize)
    UIDropDownMenu_SetText(CastHistoryTracker.selectedDropdownValue or data.default, dropdown)

    return dropdown
end


local function CreateUIElement(parent, elementType, data)
    -- Factory function to create UI elements based on type.
    local elementCreator = {
        FontString  = CreateFontStringElement,
        Button      = CreateButtonElement,
        CheckButton = CreateCheckButtonElement,
        EditBox     = CreateEditBoxElement,
        ScrollFrame = CreateScrollFrameElement,
        Dropdown    = CreateDropdownElement,
    }

    local creator = elementCreator[elementType]
    if creator then
        return creator(parent, data)
    else
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CreateUIElement]: Unknown element type: " .. tostring(elementType))
        return nil
    end
end


----------------------------------------------------
-- List Refresh Functions
----------------------------------------------------

local function RefreshSpellHistoryList()
    -- Refreshes the spell history list in the GUI.
    local scrollFrame     = CastHistoryTracker.leftScrollFrame
    local scrollChild     = CastHistoryTracker.leftScrollChild
    local linesTable      = CastHistoryTracker.lines
    local selectedRowKey  = "selectedRow"
    local sourceList      = CastHistoryTracker.spellHistory
    local uniqueSpellIDs    = CastHistoryTracker.uniqueSpellIDs
    CastHistoryTracker.uniqueSpellIDs = {}

    if not scrollChild then return end

    for _, row in pairs(linesTable or {}) do
        row:Hide()
        row:SetParent(nil)
    end
    linesTable = {}

    scrollChild:SetHeight(1)
    scrollFrame:SetVerticalScroll(0)
    local yOffset = -10

    local topPadding = CreateFrame("Frame", nil, scrollChild)
    topPadding:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    topPadding:SetWidth(260)
    topPadding:SetHeight(10)
    yOffset = yOffset - 10

    if sourceList then
        for i = table.getn(sourceList), 1, -1 do
            local entry     = sourceList[i]
            local spellName   = entry.spellName
            local spellID     = entry.spellID
            if not uniqueSpellIDs[spellID] then
                local row = CastHistoryTracker:CreateSpellRow(scrollChild, spellName, spellID, yOffset, selectedRowKey)
                table.insert(linesTable, row)
                yOffset = yOffset - 20
                uniqueSpellIDs[spellID] = true
            end
        end
    end

    local numLines = table.getn(linesTable)
    scrollChild:SetHeight(math.max(numLines * 20, 1) + 20)

    CastHistoryTracker.lines = linesTable
    CastHistoryTracker:UpdateScrollbar(true)
end


local function RefreshFilterListInternal()
    -- Refreshes the filter list in the GUI based on the current filter mode.
    local scrollFrame     = CastHistoryTracker.rightScrollFrame
    local scrollChild     = CastHistoryTracker.rightScrollChild
    local linesTable      = CastHistoryTracker.filterListLines
    local selectedRowKey  = "selectedFilterRow"
    local sourceList
    local uniqueSpellIDs  = nil

    if CastHistoryTracker.db.profile.filterMode == "Simple" then
        sourceList = CastHistoryTracker.activeSimpleSpellFilters
    elseif CastHistoryTracker.db.profile.filterMode == "Advanced" then
        local unit       = CastHistoryTracker.selectedFilter or "player"

        if     unit == "player"  then sourceList = CastHistoryTracker.activeAdvancedPlayerFilters
        elseif unit == "target"  then sourceList = CastHistoryTracker.activeAdvancedTargetFilters
        elseif unit == "party"   then sourceList = CastHistoryTracker.activeAdvancedPartyFilters
        elseif unit == "focus"   then sourceList = CastHistoryTracker.activeAdvancedFocusFilters
        else
            DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[RefreshList] Advanced Mode: Invalid unit: " .. tostring(unit))
            return
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[RefreshList] Invalid filterMode: " .. tostring(CastHistoryTracker.db.profile.filterMode))
        return
    end

    if not scrollChild then return end

    for _, row in pairs(linesTable or {}) do
        row:Hide()
        row:SetParent(nil)
    end
    linesTable = {}

    scrollChild:SetHeight(1)
    scrollFrame:SetVerticalScroll(0)
    local yOffset = -10

    local topPadding = CreateFrame("Frame", nil, scrollChild)
    topPadding:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    topPadding:SetWidth(260)
    topPadding:SetHeight(10)
    yOffset = yOffset - 10

    if sourceList then
        local sortedSpellIDs = {}
        for spellID in pairs(sourceList) do
            table.insert(sortedSpellIDs, spellID)
        end
        table.sort(sortedSpellIDs, function(a, b) return tostring(a) < tostring(b) end)
        for _, spellID in ipairs(sortedSpellIDs) do
            local spellNameValue = sourceList[spellID]
            local spellName      = spellNameValue

            if type(spellNameValue) ~= "string" then
                spellName = spellID
            end

            local row = CastHistoryTracker:CreateSpellRow(scrollChild, spellName, spellID, yOffset, selectedRowKey)
            table.insert(linesTable, row)
            yOffset = yOffset - 20
        end
    end

    local numLines = table.getn(linesTable)
    scrollChild:SetHeight(math.max(numLines * 20, 1) + 20)

    CastHistoryTracker.filterListLines = linesTable
    CastHistoryTracker:UpdateScrollbar(false)
end


local function RefreshList(isLeft)
    -- General function to refresh either spell history or filter list.
    if isLeft then
        RefreshSpellHistoryList()
    else
        RefreshFilterListInternal()
    end
end


function CastHistoryTracker:RefreshSpellList()
    -- Public function to refresh the spell history list.
    RefreshSpellHistoryList()
end


function CastHistoryTracker:RefreshFilterList()
    -- Public function to refresh the filter list.
    RefreshFilterListInternal()
end


----------------------------------------------------
-- UI Element Data
----------------------------------------------------

local uiElements = {
    -- Labels
    { type = "FontString", key = "TitleLabel",      text = "Cast History Tracker - Spell Filter", size = 20, x = 0,     y = 220,   anchor = "TOP"    },
    { type = "FontString", key = "LastSeenLabel",   text = "Last Seen Spells",                size = 14, x = -330,  y = 200,   anchor = "TOP"    },
    { type = "FontString", key = "ActiveFilterLabel", text = "Active Filter List",              size = 14, x = 330,   y = 200,   anchor = "TOP"    },
    { type = "FontString", key = "SpellIDLabel",    text = "Add by Spell Name or ID",         size = 15, x = 247.5, y = -180,  anchor = "BOTTOM" },
    { type = "FontString", key = "AboutLabel",      text = "| Cast History Tracker |",        size = 12, x = -250,  y = -188,  anchor = "BOTTOM" },
    { type = "FontString", key = "AboutLabe2",      text = "| Created by Abstractz |",        size = 12, x = -250,  y = -208,  anchor = "BOTTOM" },

    -- Checkboxes
    { type = "CheckButton", key = "Checkbox1",     label = "Simple",    x = -40,  y = 130, tooltip = "Configure for all frames.",      group = "group1", disableCheckbox = "Checkbox1", checkAgainst = "Checkbox2", enableCheckbox = "Checkbox2", disable = "FilterDropdown", anchor = "CENTER" },
    { type = "CheckButton", key = "Checkbox2",     label = "Advanced",  x = 40,   y = 130, tooltip = "Configure each frame separately.", group = "group1", disableCheckbox = "Checkbox2", checkAgainst = "Checkbox1", enableCheckbox = "Checkbox1", enable  = "FilterDropdown", anchor = "CENTER" },
    { type = "CheckButton", key = "Checkbox3",     label = "Blacklist", x = -40,  y = 60,  tooltip = "Only show spells NOT in the list.",  group = "group2", disableCheckbox = "Checkbox3", checkAgainst = "Checkbox4", enableCheckbox = "Checkbox4", anchor = "CENTER" },
    { type = "CheckButton", key = "Checkbox4",     label = "Whitelist", x = 40,   y = 60,  tooltip = "Only show spells IN the list.",   group = "group2", disableCheckbox = "Checkbox4", checkAgainst = "Checkbox3", enableCheckbox = "Checkbox3", anchor = "CENTER" },

    -- Buttons
    { type = "Button",    key = "RightButton",     name  = "CastHistoryTrackerRightButton", texture = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", x = 0,     y = -20,  label = "ADD",    onClick = function()
        if not CastHistoryTracker.selectedRow then
            DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: No spell selected on left.|r")
            return
        end

        local filterMode = CastHistoryTracker.db.profile.filterMode
        local spellName  = CastHistoryTracker.selectedRow.spellName
        local spellID    = CastHistoryTracker.selectedRow.spellID

        if filterMode == "Simple" then
            local filterType      = CastHistoryTracker.db.profile.filterTypeList
            local savedFilterList = (filterType == "Whitelist") and CastHistoryTracker.db.profile.SimpleWhitelist or CastHistoryTracker.db.profile.SimpleBlacklist

            if not savedFilterList[spellID] then
                savedFilterList[spellID] = spellName
                CastHistoryTracker:LoadSimpleFilterList()
                CastHistoryTracker:RefreshFilterList()
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: Added spell " .. CastHistoryTracker.COLOR_VALUE .. spellName .. " (" .. spellID .. ") " .. CastHistoryTracker.COLOR_DESCRIPTION .. "to Simple " .. filterType .. "|r")
            else
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Spell already in list.|r")
            end
        elseif filterMode == "Advanced" then
            local unit          = CastHistoryTracker.selectedFilter or "player"
            local filterType    = CastHistoryTracker:GetUnitFilterType(unit)
            local savedFilterList = (filterType == "Whitelist") and CastHistoryTracker.db.profile.AdvancedWhitelist[unit] or CastHistoryTracker.db.profile.AdvancedBlacklist[unit]

            if not savedFilterList[spellID] then
                savedFilterList[spellID] = spellName
                CastHistoryTracker:LoadAdvancedFilterListForUnit(unit)
                CastHistoryTracker:RefreshFilterList()
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: Added spell " .. CastHistoryTracker.COLOR_VALUE .. spellName .. " (" .. spellID .. ") " .. CastHistoryTracker.COLOR_DESCRIPTION .. "to Advanced " .. filterType .. " for " .. unit .. "|r")
            else
                 DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Spell already in list.|r")
            end
        end
    end, anchor = "CENTER" },
    { type = "Button",    key = "LeftButton",      name  = "CastHistoryTrackerLeftButton", texture = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up", x = 0,     y = -80,  label = "REMOVE", onClick = function()
        if not CastHistoryTracker.selectedFilterRow then
            DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: No spell selected on right.|r")
            return
        end

        local filterMode = CastHistoryTracker.db.profile.filterMode
        local spellID    = CastHistoryTracker.selectedFilterRow.spellID
        local spellName  = CastHistoryTracker.selectedFilterRow.spellName

         if filterMode == "Simple" then
            local filterType      = CastHistoryTracker.db.profile.filterTypeList
            local savedFilterList = (filterType == "Whitelist") and CastHistoryTracker.db.profile.SimpleWhitelist or CastHistoryTracker.db.profile.SimpleBlacklist

            if savedFilterList and savedFilterList[spellID] then
                savedFilterList[spellID] = nil
                CastHistoryTracker:LoadSimpleFilterList()
                CastHistoryTracker:RefreshFilterList()
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: Removed spell " .. CastHistoryTracker.COLOR_VALUE .. spellName .. " (" .. spellID .. ") " .. CastHistoryTracker.COLOR_DESCRIPTION .. "from Simple " .. filterType .. "|r")
            else
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Spell not in list.|r")
            end
        elseif filterMode == "Advanced" then
            local unit          = CastHistoryTracker.selectedFilter or "player"
            local filterType    = CastHistoryTracker:GetUnitFilterType(unit)
            local savedFilterList = (filterType == "Whitelist") and CastHistoryTracker.db.profile.AdvancedWhitelist[unit] or CastHistoryTracker.db.profile.AdvancedBlacklist[unit]

            if savedFilterList and savedFilterList[spellID] then
                savedFilterList[spellID] = nil
                CastHistoryTracker:LoadAdvancedFilterListForUnit(unit)
                CastHistoryTracker:RefreshFilterList()
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: Removed spell " .. CastHistoryTracker.COLOR_VALUE .. spellName .. " (" .. spellID .. ") " .. CastHistoryTracker.COLOR_DESCRIPTION .. "from Advanced " .. filterType .. " for " .. unit .. "|r")
            else
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Spell not in list.|r")
            end
        end
    end, anchor = "CENTER" },

    -- Input Field
    { type = "EditBox",   key = "SpellIDInput",    x = 247.5, y = 52,  width = 285, height = 20, defaultText = "Enter exact Spell Name or ID", maxLetters = 50, onEnterPressed = nil, anchor = "TOP" },

    -- Dropdown
    { type = "Dropdown",  key = "FilterDropdown",  name  = "CastHistoryTrackerFilterDropdown", x = -20,  y = -45,  width = 150, options = { ["player"] = "player", ["target"] = "target", ["party"] = "party", ["focus"] = "focus" }, default = "player",
        onSelect = function(selected)
            if CastHistoryTracker.selectedFilter then
                local previousUnit     = CastHistoryTracker.selectedFilter
                local previousFilterType = CastHistoryTracker.Checkbox4:GetChecked() and "Whitelist" or "Blacklist"
                CastHistoryTracker:SetUnitFilterType(previousUnit, previousFilterType)
            end

            CastHistoryTracker.selectedFilter = selected

            local newFilterType = CastHistoryTracker:GetUnitFilterType(selected)

            if newFilterType == "Whitelist" then
                CastHistoryTracker.Checkbox4:SetChecked(true)
                CastHistoryTracker.Checkbox3:SetChecked(false)
                CastHistoryTracker.Checkbox4:EnableMouse(false)
                CastHistoryTracker.Checkbox3:EnableMouse(true)
            else
                CastHistoryTracker.Checkbox3:SetChecked(true)
                CastHistoryTracker.Checkbox4:SetChecked(false)
                CastHistoryTracker.Checkbox3:EnableMouse(false)
                CastHistoryTracker.Checkbox4:EnableMouse(true)
            end

            CastHistoryTracker:LoadAdvancedFilterListForUnit(selected)
            CastHistoryTracker:RefreshFilterList()
        end, anchor = "TOPRIGHT" }
}


----------------------------------------------------
-- Filter Mode UI Initialization
----------------------------------------------------

local function InitializeFilterModeUI()
    -- Initializes the Filter Mode UI elements based on profile settings.
    local savedFilterMode     = CastHistoryTracker.db.profile.filterMode
    local savedFilterTypeList = CastHistoryTracker.db.profile.filterTypeList

    if savedFilterMode == "Advanced" then
        CastHistoryTracker.Checkbox2:SetChecked(true)
        CastHistoryTracker.Checkbox1:SetChecked(false)
        CastHistoryTracker.Checkbox2:EnableMouse(false)
        CastHistoryTracker.Checkbox1:EnableMouse(true)
        CastHistoryTracker.FilterDropdown:SetAlpha(1)
        CastHistoryTracker.FilterDropdown:EnableMouse(true)
        CastHistoryTracker.ActiveFilterLabel:SetAlpha(0)

        local initialUnit     = CastHistoryTracker.selectedFilter or "player"
        local initialFilterType = CastHistoryTracker:GetUnitFilterType(initialUnit)

        if initialFilterType == "Whitelist" then
            CastHistoryTracker.Checkbox4:SetChecked(true)
            CastHistoryTracker.Checkbox3:SetChecked(false)
            CastHistoryTracker.Checkbox4:EnableMouse(false)
            CastHistoryTracker.Checkbox3:EnableMouse(true)
        else
            CastHistoryTracker.Checkbox3:SetChecked(true)
            CastHistoryTracker.Checkbox4:SetChecked(false)
            CastHistoryTracker.Checkbox3:EnableMouse(false)
            CastHistoryTracker.Checkbox4:EnableMouse(true)
        end

    else
        CastHistoryTracker.Checkbox1:SetChecked(true)
        CastHistoryTracker.Checkbox2:SetChecked(false)
        CastHistoryTracker.Checkbox1:EnableMouse(false)
        CastHistoryTracker.Checkbox2:EnableMouse(true)
        CastHistoryTracker.FilterDropdown:SetAlpha(0)
        CastHistoryTracker.FilterDropdown:EnableMouse(false)
        CastHistoryTracker.ActiveFilterLabel:SetAlpha(1)
        CastHistoryTracker.db.profile.filterMode = "Simple"

        if savedFilterTypeList == "Whitelist" then
            CastHistoryTracker.Checkbox4:SetChecked(true)
            CastHistoryTracker.Checkbox3:SetChecked(false)
            CastHistoryTracker.Checkbox4:EnableMouse(false)
            CastHistoryTracker.Checkbox3:EnableMouse(true)
        else
            CastHistoryTracker.Checkbox3:SetChecked(true)
            CastHistoryTracker.Checkbox4:SetChecked(false)
            CastHistoryTracker.Checkbox3:EnableMouse(false)
            CastHistoryTracker.Checkbox4:EnableMouse(true)
        end
    end
end


----------------------------------------------------
-- GUI Creation
----------------------------------------------------

function CastHistoryTracker:CreateGUI()
    -- Creates the configuration GUI frame and its elements.
    local configFrame = CreateFrame("Frame", "CastHistoryTrackerConfigFrame", UIParent)
    configFrame:SetWidth(850)
    configFrame:SetHeight(500)
    configFrame:SetPoint("CENTER", UIParent, "CENTER")
    configFrame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 }})
    configFrame:Hide()

    configFrame:SetScript("OnShow", function(self)
        CastHistoryTracker:RefreshSpellList()
        CastHistoryTracker:LoadSimpleFilterList()
        if CastHistoryTracker.db.profile.filterMode == "Advanced" then
            local initialUnit = CastHistoryTracker.selectedFilter or "player"
            CastHistoryTracker:LoadAdvancedFilterListForUnit(initialUnit)
        end
        CastHistoryTracker:RefreshFilterList()
    end)

    CastHistoryTracker.configFrame = configFrame

    local closeButton = CreateUIElement(configFrame, "Button", {
        name    = nil,
        x       = -5,
        y       = -5,
        texture = "Interface\\Buttons\\UI-Panel-MinimizeButton-Up",
        onClick = function() configFrame:Hide() end,
        parent  = configFrame,
        label   = nil
    })
    closeButton:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -5, -5)

    local scrollFrameBackdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }}
    CastHistoryTracker.leftScrollFrame, CastHistoryTracker.leftScrollChild, CastHistoryTracker.leftScrollbar =
        CreateUIElement(configFrame, "ScrollFrame", {
            name     = "CastHistoryScrollFrameLeft",
            x        = 30,
            y        = -80,
            width    = 300,
            height   = 320,
            backdrop = scrollFrameBackdrop,
            isLeft   = true
        })

    for _, elementData in ipairs(uiElements) do
        CastHistoryTracker[elementData.key] = CreateUIElement(configFrame, elementData.type, elementData)
    end

    InitializeFilterModeUI()

    CastHistoryTracker.rightScrollFrame, CastHistoryTracker.rightScrollChild, CastHistoryTracker.rightScrollbar =
        CreateUIElement(configFrame, "ScrollFrame", {
            name     = "CastHistoryScrollFrameRight",
            x        = 520,
            y        = -80,
            width    = 300,
            height   = 320,
            backdrop = scrollFrameBackdrop,
            isLeft   = false
        })
    CastHistoryTracker.RefreshSpellList  = function() RefreshList(true) end
    CastHistoryTracker.RefreshFilterList = function() RefreshList(false) end
end


----------------------------------------------------
-- Row Selection & Creation
----------------------------------------------------

function CastHistoryTracker:HandleRowSelection(row, selectedRowKey)
    -- Handles row selection in scroll frames, visually highlighting selected row.
    if CastHistoryTracker[selectedRowKey] then
        CastHistoryTracker[selectedRowKey].bg:SetVertexColor(0, 0, 0, 0)
    end
    if selectedRowKey == "selectedRow" and CastHistoryTracker.selectedFilterRow then
        CastHistoryTracker.selectedFilterRow.bg:SetVertexColor(0, 0, 0, 0)
        CastHistoryTracker.selectedFilterRow = nil
    elseif selectedRowKey == "selectedFilterRow" and CastHistoryTracker.selectedRow then
        CastHistoryTracker.selectedRow.bg:SetVertexColor(0, 0, 0, 0)
        CastHistoryTracker.selectedRow = nil
    end

    row.bg:SetVertexColor(1, 1, 0, 0.3)
    CastHistoryTracker[selectedRowKey] = row
end


function CastHistoryTracker:CreateSpellRow(scrollChild, spellName, spellID, yOffset, selectedRowKey)
    -- Creates a row for spell lists in scroll frames.
    local row = CreateFrame("Button", nil, scrollChild)
    row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    row:SetWidth(260)
    row:SetHeight(20)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    bg:SetVertexColor(0, 0, 0, 0)
    row.bg = bg

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.text:SetPoint("CENTER", row, "CENTER", 0, 0)

    if type(spellID) == "number" then
        row.text:SetText(string.format("%s (%s)", spellName, spellID))
    else
        row.text:SetText(spellName)
    end

    row.spellName = spellName
    row.spellID   = spellID

    row:SetScript("OnClick", function()
        CastHistoryTracker:HandleRowSelection(row, selectedRowKey)
    end)
    row:Show()
    return row
end


----------------------------------------------------
-- Scrollbar Management
----------------------------------------------------

function CastHistoryTracker:UpdateScrollbar(isLeft)
    -- Updates the scrollbar for spell history or filter list.
    local scrollFrame = isLeft and CastHistoryTracker.leftScrollFrame or CastHistoryTracker.rightScrollFrame
    local scrollChild = isLeft and CastHistoryTracker.leftScrollChild or CastHistoryTracker.rightScrollChild
    local scrollbar   = isLeft and CastHistoryTracker.leftScrollbar or CastHistoryTracker.rightScrollbar

    local maxScroll = math.max(0, scrollChild:GetHeight() - scrollFrame:GetHeight()) + 20
    scrollbar:SetMinMaxValues(0, maxScroll)
    scrollbar:SetValueStep(20)

    if maxScroll > 0 then
        scrollbar:Show()
    else
        scrollbar:Hide()
    end
end


----------------------------------------------------
-- Checkbox Behavior
----------------------------------------------------

local function HandleFilterModeCheckboxChange(checkbox, data)
    -- Handles changes to Filter Mode checkboxes (Simple/Advanced).
    if data.key == "Checkbox1" then
        CastHistoryTracker.db.profile.filterMode = "Simple"
        CastHistoryTracker.currentFilterMode = "Simple"
        CastHistoryTracker.FilterDropdown:SetAlpha(0)
        CastHistoryTracker.FilterDropdown:EnableMouse(false)
        CastHistoryTracker.ActiveFilterLabel:SetAlpha(1)

        local simpleFilterType = CastHistoryTracker.db.profile.filterTypeList
        if simpleFilterType == "Whitelist" then
            CastHistoryTracker.Checkbox4:SetChecked(true)
            CastHistoryTracker.Checkbox3:SetChecked(false)
            CastHistoryTracker.Checkbox4:EnableMouse(false)
            CastHistoryTracker.Checkbox3:EnableMouse(true)
        else
            CastHistoryTracker.Checkbox3:SetChecked(true)
            CastHistoryTracker.Checkbox4:SetChecked(false)
            CastHistoryTracker.Checkbox3:EnableMouse(false)
            CastHistoryTracker.Checkbox4:EnableMouse(true)
        end
        CastHistoryTracker:LoadSimpleFilterList()
        CastHistoryTracker:RefreshFilterList()

    elseif data.key == "Checkbox2" then
        CastHistoryTracker.db.profile.filterMode = "Advanced"
        CastHistoryTracker.currentFilterMode = "Advanced"
        CastHistoryTracker.FilterDropdown:SetAlpha(1)
        CastHistoryTracker.FilterDropdown:EnableMouse(true)
        CastHistoryTracker.ActiveFilterLabel:SetAlpha(0)

        local playerFilterType = CastHistoryTracker:GetUnitFilterType("player")
        if playerFilterType == "Whitelist" then
            CastHistoryTracker.Checkbox4:SetChecked(true)
            CastHistoryTracker.Checkbox3:SetChecked(false)
            CastHistoryTracker.Checkbox4:EnableMouse(false)
            CastHistoryTracker.Checkbox3:EnableMouse(true)
        else
            CastHistoryTracker.Checkbox3:SetChecked(true)
            CastHistoryTracker.Checkbox4:SetChecked(false)
            CastHistoryTracker.Checkbox3:EnableMouse(false)
            CastHistoryTracker.Checkbox4:EnableMouse(true)
        end

        CastHistoryTracker:LoadActiveFiltersForAdvancedMode()
        CastHistoryTracker:RefreshFilterList()
    end
end


local function HandleFilterTypeCheckboxChange(checkbox, data)
    -- Handles changes to Filter Type checkboxes (Blacklist/Whitelist).
    local filterMode = CastHistoryTracker.db.profile.filterMode
    if data.key == "Checkbox3" then
        if filterMode == "Simple" then
            CastHistoryTracker.db.profile.filterTypeList = "Blacklist"
            CastHistoryTracker:LoadSimpleFilterList()
        elseif filterMode == "Advanced" then
            local currentUnit = CastHistoryTracker.selectedFilter or "player"
            CastHistoryTracker:SetUnitFilterType(currentUnit, "Blacklist")
            CastHistoryTracker:LoadAdvancedFilterListForUnit(currentUnit)
        end
    elseif data.key == "Checkbox4" then
        if filterMode == "Simple" then
            CastHistoryTracker.db.profile.filterTypeList = "Whitelist"
            CastHistoryTracker:LoadSimpleFilterList()
        elseif filterMode == "Advanced" then
            local currentUnit = CastHistoryTracker.selectedFilter or "player"
            CastHistoryTracker:SetUnitFilterType(currentUnit, "Whitelist")
            CastHistoryTracker:LoadAdvancedFilterListForUnit(currentUnit)
        end
    end
    CastHistoryTracker:RefreshFilterList()
end


local checkboxGroups = {
    group1 = {
        checkboxKeys    = {"Checkbox1", "Checkbox2"},
        mutualExclusion = true,
        onChange        = HandleFilterModeCheckboxChange,
    },
    group2 = {
        checkboxKeys    = {"Checkbox3", "Checkbox4"},
        mutualExclusion = true,
        onChange        = HandleFilterTypeCheckboxChange,
    },
}


function CastHistoryTracker:HandleCheckboxBehavior(checkbox, data)
    -- General handler for checkbox clicks, managing mutual exclusion and onChange events.
    local groupData = checkboxGroups[data.group]
    if not groupData then return end

    if groupData.mutualExclusion then
        for _, key in ipairs(groupData.checkboxKeys) do
            if key ~= data.key and CastHistoryTracker[key] then
                CastHistoryTracker[key]:SetChecked(false)
            end
        end
    end

    if data.disableCheckbox and CastHistoryTracker[data.disableCheckbox] then
        CastHistoryTracker[data.disableCheckbox]:EnableMouse(false)
    end
    if data.enableCheckbox and CastHistoryTracker[data.enableCheckbox] then
        CastHistoryTracker[data.enableCheckbox]:EnableMouse(true)
    end

    if groupData.onChange then
        groupData.onChange(checkbox, data)
    end
end


----------------------------------------------------
-- Input Field Behavior
----------------------------------------------------

function CastHistoryTracker:AddSpellToFilterList(input)
    -- Adds a spell (by name or ID) to the appropriate filter list based on current mode.
    local filterMode = CastHistoryTracker.db.profile.filterMode

    if filterMode == "Simple" then
        local spellID         = tonumber(input)
        local spellName       = input
        local filterType      = CastHistoryTracker.db.profile.filterTypeList
        local savedFilterList = (filterType == "Whitelist") and CastHistoryTracker.db.profile.SimpleWhitelist or CastHistoryTracker.db.profile.SimpleBlacklist

        if spellID then
            if savedFilterList[spellID] then
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Spell ID " .. CastHistoryTracker.COLOR_VALUE .. spellID .. CastHistoryTracker.COLOR_ERROR .. " is already in the " .. filterType .. ".|r")
                return
            end

            local actualSpellName, _, _ = SpellInfo(spellID)
            if actualSpellName then
                if savedFilterList[actualSpellName] then
                    DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Spell Name '" .. CastHistoryTracker.COLOR_VALUE .. actualSpellName .. CastHistoryTracker.COLOR_ERROR .. "' (for ID " .. CastHistoryTracker.COLOR_VALUE .. spellID .. CastHistoryTracker.COLOR_ERROR .. ") is already in the " .. filterType .. ". Use name or ID but not both for one spell.|r")
                    return
                end
                savedFilterList[spellID] = actualSpellName
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: Added Spell ID " .. CastHistoryTracker.COLOR_VALUE .. spellID .. CastHistoryTracker.COLOR_COMMAND .. " (" .. CastHistoryTracker.COLOR_VALUE .. actualSpellName .. CastHistoryTracker.COLOR_COMMAND .. ") to Simple " .. CastHistoryTracker.COLOR_DESCRIPTION .. filterType .. "|r")
            else
                savedFilterList[spellID] = true
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: Added Spell ID " .. CastHistoryTracker.COLOR_VALUE .. spellID .. CastHistoryTracker.COLOR_COMMAND .. " (Name not found) to Simple " .. CastHistoryTracker.COLOR_DESCRIPTION .. filterType .. "|r")
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Warning: Spell Name for ID " .. CastHistoryTracker.COLOR_VALUE .. spellID .. CastHistoryTracker.COLOR_ERROR .. " not found. Filtering by ID only.|r")
            end
        else
            if savedFilterList[spellName] then
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Spell Name '" .. CastHistoryTracker.COLOR_VALUE .. spellName .. CastHistoryTracker.COLOR_ERROR .. "' is already in the " .. filterType .. ".|r")
                return
            end
            savedFilterList[spellName] = true
            DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: Added Spell Name '" .. CastHistoryTracker.COLOR_VALUE .. spellName .. CastHistoryTracker.COLOR_COMMAND .. "' to Simple " .. CastHistoryTracker.COLOR_DESCRIPTION .. filterType .. "|r")
        end

        CastHistoryTracker:LoadSimpleFilterList()

    elseif filterMode == "Advanced" then
        local unit          = CastHistoryTracker.selectedFilter or "player"
        local filterType    = CastHistoryTracker:GetUnitFilterType(unit)
        local savedFilterList = (filterType == "Whitelist") and CastHistoryTracker.db.profile.AdvancedWhitelist[unit] or CastHistoryTracker.db.profile.AdvancedBlacklist[unit]
        local spellID         = tonumber(input)
        local spellName       = input

        if spellID then
            if savedFilterList[spellID] then
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Spell ID " .. CastHistoryTracker.COLOR_VALUE .. spellID .. CastHistoryTracker.COLOR_ERROR .. " is already in the " .. filterType .. " for " .. unit .. ".|r")
                return
            end

            local actualSpellName, _, _ = SpellInfo(spellID)
            if actualSpellName then
                if savedFilterList[actualSpellName] then
                    DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Spell Name '" .. CastHistoryTracker.COLOR_VALUE .. actualSpellName .. CastHistoryTracker.COLOR_ERROR .. "' (for ID " .. CastHistoryTracker.COLOR_VALUE .. spellID .. CastHistoryTracker.COLOR_ERROR .. ") is already in the " .. filterType .. " for " .. unit .. ". Use name or ID but not both for one spell.|r")
                    return
                end
                savedFilterList[spellID] = actualSpellName
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: Added spell " .. CastHistoryTracker.COLOR_VALUE .. actualSpellName .. " (" .. spellID .. ") " .. CastHistoryTracker.COLOR_DESCRIPTION .. "to Advanced " .. filterType .. " for " .. unit .. "|r")
            else
                savedFilterList[spellID] = true
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: Added Spell ID " .. CastHistoryTracker.COLOR_VALUE .. spellID .. CastHistoryTracker.COLOR_COMMAND .. " (Name not found) to Advanced " .. filterType .. "|r")
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Warning: Spell Name for ID " .. CastHistoryTracker.COLOR_VALUE .. spellID .. CastHistoryTracker.COLOR_ERROR .. " not found. Filtering by ID only.|r")
            end
        else
            if savedFilterList[spellName] then
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Spell name '" .. CastHistoryTracker.COLOR_VALUE .. spellName .. CastHistoryTracker.COLOR_ERROR .. "' is already in the " .. filterType .. " for " .. unit .. ".|r")
                return
            end
            savedFilterList[spellName] = true
            DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: Added spell " .. CastHistoryTracker.COLOR_VALUE .. spellName .. CastHistoryTracker.COLOR_COMMAND .. " to Advanced " .. filterType .. "|r")
        end
        CastHistoryTracker:LoadAdvancedFilterListForUnit(unit)
    end

    CastHistoryTracker:RefreshFilterList()
end