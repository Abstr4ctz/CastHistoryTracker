-- Utils.lua
-- Utility functions for CastHistoryTracker.

local CastHistoryTracker = CastHistoryTrackerNamespace.CastHistoryTracker


----------------------------------------------------
-- Debug Functions
----------------------------------------------------

function CastHistoryTracker:Debug(message)
    -- Prints debug messages to the chat frame if debug mode is enabled.
    if self.db.profile.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_DEBUG .. "[CastHistoryTracker Debug]: " .. tostring(message))
    end
end


function CastHistoryTracker:ToggleDebugMode()
    -- Toggles debug mode on or off via slash command.
    self.db.profile.debugMode = not self.db.profile.debugMode
    local modeText = self.db.profile.debugMode and CastHistoryTracker.COLOR_HIGHLIGHT .. "enabled" or CastHistoryTracker.COLOR_VALUE .. "disabled"
    DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: Debug mode " .. modeText .. "|r")
end


function CastHistoryTracker:TableToString(tbl)
    -- Converts a table to a string for debug output.
    if not tbl then return "nil" end

    local result = "{"
    for k, v in pairs(tbl) do
        if type(v) == "table" then
          result = result .. tostring(k) .. " = " .. self:TableToString(v) .. ", "
        else
          result = result .. tostring(k) .. " = " .. tostring(v) .. ", "
        end
    end
    result = result .. "}"
    return result
end


----------------------------------------------------
-- Settings Functions
----------------------------------------------------

function CastHistoryTracker:UpdateAllSettings()
    -- Updates all relevant settings from the profile.
    self.db.profile.fadeTime     = self.db.profile.fadeTime or CastHistoryTracker.DEFAULT_FADE_TIME
    self.db.profile.moveDuration = self.db.profile.moveDuration or CastHistoryTracker.DEFAULT_MOVE_DURATION
    self:UpdateAnchorFrameSizes()
	self:UpdateFrameAnimationSettings()
end


function CastHistoryTracker:UpdateSetting(setting, newValue)
    -- Updates a specific setting in the profile and provides chat feedback.
    if newValue then
        self.db.profile[setting] = newValue
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: " .. CastHistoryTracker.COLOR_DESCRIPTION .. setting .. CastHistoryTracker.COLOR_COMMAND .. " set to " .. CastHistoryTracker.COLOR_VALUE .. tostring(newValue) .. "|r")
        if setting == "fadeTime" or setting == "moveDuration" then
            self:UpdateFrameAnimationSettings()
        end
    end
end

----------------------------------------------------
-- Cache Update Function
----------------------------------------------------
function CastHistoryTracker:UpdateFrameAnimationSettings()
    -- Updates the cached fadeTime and moveDuration from the profile.
    self.fadeTimeCache = self.db.profile.fadeTime
    self.moveDurationCache = self.db.profile.moveDuration
    self:Debug(self.COLOR_DEBUG .. "[UpdateFrameAnimationSettings]: Cached fadeTime: " .. tostring(self.fadeTimeCache) .. ", moveDuration: " .. tostring(self.moveDurationCache))
end


----------------------------------------------------
-- Anchor Frame Functions
----------------------------------------------------

function CastHistoryTracker:UpdateAnchorFrameSizes(unit)
    -- Updates the size of anchor frames, optionally for a specific unit or all units.
    if unit then
        local frameSize = self:GetFrameSize(unit)
        local anchor = CastHistoryTracker.anchorFrames[unit]
        if anchor then
            anchor:SetWidth(frameSize)
            anchor:SetHeight(frameSize)
            if anchor.label then
                anchor.label:SetFont("Fonts\\FRIZQT__.TTF", math.max(frameSize * 0.4, 12), "OUTLINE")
            end
            self:Debug("[UpdateAnchorFrameSizes] Updated anchor size for " .. unit .. " to " .. frameSize)
        end
    else
        self:Debug("[UpdateAnchorFrameSizes] Updating all anchor sizes")
        for unit in pairs(CastHistoryTracker.anchorFrames) do
            self:UpdateAnchorFrameSizes(unit)
        end
    end
end


function CastHistoryTracker:CreateAnchorFrame(unit)
    -- Creates an anchor frame for a given unit.
    if not unit then
        self:Debug(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: No unit for CreateAnchorFrame.")
        return
    end

    local anchorName = "CastHistoryTrackerAnchor"..unit
    local anchor = CreateFrame("Frame", anchorName, UIParent)
    local frameSize = self:GetFrameSize(unit)
    anchor:SetWidth(frameSize)
    anchor:SetHeight(frameSize)

    local anchorX = self.db.profile.anchorPositions[unit].x
    local anchorY = self.db.profile.anchorPositions[unit].y

    anchor:SetPoint("CENTER", UIParent, "BOTTOMLEFT", anchorX, anchorY)
    anchor:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    anchor:SetBackdropColor(1, 0, 0, 0.3)
    anchor.defaultBackdropColor = {1, 0, 0, 0.3}

    local label = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOM", anchor, "TOP", 0, 2)
    label:SetText(unit)
    label:SetTextColor(1, 1, 1, 1)
    label:SetFont("Fonts\\FRIZQT__.TTF", math.max(frameSize * 0.4, 12), "OUTLINE")
    anchor.label = label
    anchor.unit = unit

    anchor:EnableMouse(true)
    anchor:SetMovable(true)
    anchor:RegisterForDrag("LeftButton")

    local function startMoving()
        if not self.db.profile.locked then
            anchor:StartMoving()
        end
    end

    local function stopMoving()
        anchor:StopMovingOrSizing()
        local x, y = anchor:GetCenter()
        self.db.profile.anchorPositions[unit] = { x = x, y = y }
        self:Debug(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: " .. unit .. " position saved. X: " .. x .. " Y: " .. y)
    end

    anchor:SetScript("OnDragStart", startMoving)
    anchor:SetScript("OnDragStop", stopMoving)

    CastHistoryTracker.anchorFrames[unit] = anchor
    self:UpdateAnchorVisibility(unit)
    self:Debug("[CreateAnchorFrame] Anchor frame created for " .. unit)
end


function CastHistoryTracker:CreateAnchorFrameForFocus(focus)
    -- Creates an anchor frame for focus unit if it doesn't exist.
    if not CastHistoryTracker.anchorFrames[focus] then
        self:CreateAnchorFrame(focus)
    end
end


function CastHistoryTracker:ToggleAnchorLock()
    -- Toggles the anchor lock setting.
    self.db.profile.locked = not self.db.profile.locked
    self:Debug("[ToggleAnchorLock] Toggling anchor lock to " .. tostring(self.db.profile.locked))
    for unit in pairs(CastHistoryTracker.anchorFrames) do
        self:UpdateAnchorVisibility(unit)
    end
end


function CastHistoryTracker:UpdateAnchorVisibility(unit)
    -- Updates the visibility and appearance of an anchor frame based on lock status and unit type.
    local anchor = CastHistoryTracker.anchorFrames[unit]
    if anchor then
        local label = anchor.label
        local guid = CastHistoryTracker.trackedUnitGUIDs[unit]

        if self.db.profile.locked then
            anchor:SetBackdropColor(0,0,0,0)
            if string.find(unit, "focus") and guid then
                local unitName = UnitName(guid)
                label:SetText(unitName or "Unknown")
                label:Show()
            else
                label:Hide()
            end
        else
            anchor:SetBackdropColor(anchor.defaultBackdropColor[1], anchor.defaultBackdropColor[2], anchor.defaultBackdropColor[3], anchor.defaultBackdropColor[4])
            label:SetText(unit)
            label:Show()
        end
    end
end


----------------------------------------------------
-- Unit GUID Functions
----------------------------------------------------

function CastHistoryTracker:GetUnitGUID(unit)
    -- Retrieves the GUID for a given unit.
    local _, guid = UnitExists(unit)
    return guid
end


function CastHistoryTracker:UpdateTrackedUnitGUIDs()
    -- Updates the GUIDs for all tracked units based on visibility settings.
	if self.db.profile.showPlayer then
		CastHistoryTracker.trackedUnitGUIDs["player"] = self:GetUnitGUID("player")
	else
		CastHistoryTracker.trackedUnitGUIDs["player"] = nil
	end

	if self.db.profile.showTarget then
		CastHistoryTracker.trackedUnitGUIDs["target"] = self:GetUnitGUID("target")
	else
		CastHistoryTracker.trackedUnitGUIDs["target"] = nil
	end

	if self.db.profile.showParty then
		for i = 1, 4 do
			local partyUnit = "party"..i
			if UnitName(partyUnit) then
				CastHistoryTracker.trackedUnitGUIDs[partyUnit] = self:GetUnitGUID(partyUnit)
			end
		end
	else
		for i = 1, 4 do
			local partyUnit = "party"..i
			CastHistoryTracker.trackedUnitGUIDs[partyUnit] = nil
		end
	end
end


function CastHistoryTracker:SetUnitFocus(focus)
    -- Sets a unit as a focus unit and updates its GUID.
    local guid = self:GetUnitGUID("target")
    CastHistoryTracker.trackedUnitGUIDs[focus] = guid
    if guid then
        local unitName = UnitName("target")
        self:Debug("[SetUnitFocus] Setting " .. focus .. " to GUID " .. tostring(guid) .. " (" .. unitName .. ")")
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker] " .. focus .. " set to " .. CastHistoryTracker.COLOR_VALUE .. unitName .. "|r")
    else
        self:Debug("[SetUnitFocus] Clearing focus " .. focus)
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker] " .. focus .. " cleared.|r")
    end
    self:UpdateAnchorVisibility(focus)
    return guid
end


function CastHistoryTracker:ClearFocusUnit(focus)
    -- Clears a specific focus unit and its GUID.
    self:Debug("[ClearFocusUnit] Clearing focus " .. focus)
    CastHistoryTracker.trackedUnitGUIDs[focus] = nil
    self:UpdateAnchorVisibility(focus)
end


function CastHistoryTracker:ClearAllFocusUnits()
    -- Clears all focus units and their GUIDs.
    self:Debug("[ClearAllFocusUnits] Clearing all focuses")
    for i = 1, 5 do
        local focusUnit = "focus" .. i
        CastHistoryTracker.trackedUnitGUIDs[focusUnit] = nil
        self:UpdateAnchorVisibility(focusUnit)
    end
    DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker] All focuses cleared.|r")
end


----------------------------------------------------
-- Frame Size Functions
----------------------------------------------------

local function getUnitFrameSize(self, unit)
    -- Local helper function to get frame size for a unit from profile.
    if unit == "player" then
        return self.db.profile.playerFrameSize
    elseif unit == "target" then
        return self.db.profile.targetFrameSize
    elseif string.find(unit, "party") then
        return self.db.profile.partyFrameSize
    elseif string.find(unit, "focus") then
        return self.db.profile.focusFrameSize
    else
        return self.db.profile.playerFrameSize
    end
end


local function updateUnitFrames(self, unit, value)
    -- Local helper function to update frame sizes for a unit's existing frames.
    local frames = CastHistoryTracker.frames[unit]
    if frames then
        for _, frameData in ipairs(frames) do
            if frameData and frameData.frame then
                frameData.frame:SetWidth(value)
                frameData.frame:SetHeight(value)
            end
        end
    end
    self:UpdateAnchorFrameSizes(unit)
end


function CastHistoryTracker:GetFrameSize(unit)
    -- Retrieves the frame size for a given unit.
	return getUnitFrameSize(self, unit)
end


function CastHistoryTracker:UpdateFrameSize(target, value)
    -- Updates frame size setting for a target type (player, target, party, focus) and updates frames.
    local updateUnits
    if target == "party" then
        self.db.profile.partyFrameSize = value
        updateUnits = {"party1", "party2", "party3", "party4"}
    elseif target == "focus" then
        self.db.profile.focusFrameSize = value
        updateUnits = {"focus1", "focus2", "focus3", "focus4", "focus5"}
    elseif target == "player" then
        self.db.profile.playerFrameSize = value
        updateUnits = {"player"}
    elseif target == "target" then
        self.db.profile.targetFrameSize = value
        updateUnits = {"target"}
    end

    if updateUnits then
        for _, unit in pairs(updateUnits) do
            updateUnitFrames(self, unit, value)
        end
    end
end


----------------------------------------------------
-- Filter List Management (Simple)
----------------------------------------------------

function CastHistoryTracker:LoadSimpleFilterList()
    -- Loads the simple filter list from the profile into active memory.
    CastHistoryTracker.activeSimpleSpellFilters = {}

    local filterType = self.db.profile.filterTypeList
    local savedFilterList = (filterType == "Whitelist") and self.db.profile.SimpleWhitelist or self.db.profile.SimpleBlacklist

    if savedFilterList then
        for spellID, spellName in pairs(savedFilterList) do
            CastHistoryTracker.activeSimpleSpellFilters[spellID] = spellName
        end
    end
end


----------------------------------------------------
-- Filter List Management (Advanced)
----------------------------------------------------

function CastHistoryTracker:GetUnitFilterType(unit)
    -- Gets the filter type (Blacklist/Whitelist) for a given unit.
    local genericUnit = unit  -- Assume generic unit is the same as unit initially

    if string.find(unit, "party") then
        genericUnit = "party"  -- Map "party1", "party2", etc., to "party"
    elseif string.find(unit, "focus") then
        genericUnit = "focus"  -- Map "focus1", "focus2", etc., to "focus"
    end

    local filterType = self.db.profile.UnitFilterTypes[genericUnit] or "Blacklist"  -- Use genericUnit for lookup
    self:Debug("[GetUnitFilterType] Filter type for " .. unit .. " (generic: " .. genericUnit .. ") is: " .. tostring(filterType)) -- Debug with both units
    return filterType
end


function CastHistoryTracker:SetUnitFilterType(unit, filterType)
    -- Sets the filter type (Blacklist/Whitelist) for a given unit.
    local genericUnit = unit  -- Assume generic unit is the same as unit initially

    if string.find(unit, "party") then
        genericUnit = "party"  -- Map "party1", "party2", etc., to "party"
    elseif string.find(unit, "focus") then
        genericUnit = "focus"  -- Map "focus1", "focus2", etc., to "focus"
    end

    self.db.profile.UnitFilterTypes[genericUnit] = filterType -- Use genericUnit for saving
    self:Debug("[SetUnitFilterType] Setting filter type for " .. unit .. " (generic: " .. genericUnit .. ") to: " .. tostring(filterType)) -- Debug with both units
end


function CastHistoryTracker:LoadAdvancedFilterListForUnit(unit)
    -- Loads the advanced filter list for a specific unit from the profile into active memory.
    self:Debug("[LoadAdvancedFilterListForUnit] Called for unit: " .. unit)
    local filterType = self:GetUnitFilterType(unit)
    local savedFilterList = (filterType == "Whitelist") and self.db.profile.AdvancedWhitelist[unit] or self.db.profile.AdvancedBlacklist[unit]
    local activeFilterTable

    if unit == "player" then
        activeFilterTable = CastHistoryTracker.activeAdvancedPlayerFilters
    elseif unit == "target" then
        activeFilterTable = CastHistoryTracker.activeAdvancedTargetFilters
    elseif unit == "party" then
        activeFilterTable = CastHistoryTracker.activeAdvancedPartyFilters
    elseif unit == "focus" then
        activeFilterTable = CastHistoryTracker.activeAdvancedFocusFilters
    else
        self:Debug(CastHistoryTracker.COLOR_ERROR .. "[LoadAdvancedFilterListForUnit] Invalid unit: " .. tostring(unit))
        return
    end

    -- Clear current active filter table.  Crucial step.
    for k, _ in pairs(activeFilterTable) do
        activeFilterTable[k] = nil
    end

    if savedFilterList then
        self:Debug("[LoadAdvancedFilterListForUnit] savedFilterList exists, Count: " .. table.getn(savedFilterList))
        for spellID, spellName in pairs(savedFilterList) do
            self:Debug("[LoadAdvancedFilterListForUnit] Loading spellID: " .. tostring(spellID) .. ", spellName: " .. tostring(spellName))
            activeFilterTable[spellID] = spellName  -- Populate the active table
        end
        self:Debug("[LoadAdvancedFilterListForUnit] Loaded " .. table.getn(activeFilterTable) .. " spells into " .. unit .. "'s active filter.")
    else
        self:Debug(CastHistoryTracker.COLOR_ERROR .. "[LoadAdvancedFilterListForUnit] No saved filter list found for unit: " .. unit)
    end
end


function CastHistoryTracker:SaveAdvancedFilterListForUnit(unit, filterType, filterList)
    -- Saves the advanced filter list for a specific unit to the profile.
    self:Debug("[SaveAdvancedFilterListForUnit] Called for unit: " .. unit .. ", filterType: " .. filterType)
    local databaseList = (filterType == "Whitelist") and self.db.profile.AdvancedWhitelist[unit] or self.db.profile.AdvancedBlacklist[unit]
	local activeFilterTable

    if unit == "player" then
        activeFilterTable = CastHistoryTracker.activeAdvancedPlayerFilters
    elseif unit == "target" then
        activeFilterTable = CastHistoryTracker.activeAdvancedTargetFilters
    elseif unit == "party" then
        activeFilterTable = CastHistoryTracker.activeAdvancedPartyFilters
    elseif unit == "focus" then
        activeFilterTable = CastHistoryTracker.activeAdvancedFocusFilters
    end

    -- Clear existing list in the database.
	for k, _ in pairs(databaseList) do
		databaseList[k] = nil
	end

    -- Save the new list to database
    for spellID, spellName in pairs(filterList) do
		self:Debug("[SaveAdvancedFilterListForUnit] Saving to DB: spellID: " .. tostring(spellID) .. ", spellName: " .. tostring(spellName))
        databaseList[spellID] = spellName
    end

	-- Update the active filter table
	-- Clear current active table first.
	for k, _ in pairs(activeFilterTable) do
		activeFilterTable[k] = nil
	end

	--Copy to activeFilterTable.
	for spellID, spellName in pairs(filterList) do
		activeFilterTable[spellID] = spellName
	end

    self:Debug("[SaveAdvancedFilterListForUnit] Saved filter list for unit: " .. unit .. " to database.")
	self:Debug("[SaveAdvancedFilterListForUnit] Active table for " .. unit .. " now has " .. table.getn(activeFilterTable) .. " entries.")
end


function CastHistoryTracker:LoadActiveFiltersForAdvancedMode()
    -- Loads all active advanced filter lists for all units when switching to Advanced Mode.
    self:Debug("[LoadActiveFiltersForAdvancedMode] Called.")
    local units = {"player", "target", "party", "focus"}

    -- Clear ALL active filter tables first
    for _, filterTable in ipairs({CastHistoryTracker.activeAdvancedPlayerFilters,
                                  CastHistoryTracker.activeAdvancedTargetFilters,
                                  CastHistoryTracker.activeAdvancedPartyFilters,
                                  CastHistoryTracker.activeAdvancedFocusFilters}) do
        for k, _ in pairs(filterTable) do
            filterTable[k] = nil
        end
    end

    -- Reload ALL active filter tables
    for _, unit in ipairs(units) do
        self:LoadAdvancedFilterListForUnit(unit)
    end
end