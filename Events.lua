-- Events.lua
-- Handles game events for cast tracking.

local CastHistoryTracker = CastHistoryTrackerNamespace.CastHistoryTracker


----------------------------------------------------
-- Local Helpers
----------------------------------------------------

local function UpdateTrackedUnitGUID(self, unit)
    -- Helper function to update and debug tracked unit GUIDs.
    local guid = self:GetUnitGUID(unit)
    CastHistoryTracker.trackedUnitGUIDs[unit] = guid
    if guid then
        self:Debug(CastHistoryTracker.COLOR_SYSTEM .. "[CastHistoryTracker]: " .. unit .. " GUID " .. guid)
    else
        self:Debug(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Failed to get " .. unit .. " GUID!")
    end
end


----------------------------------------------------
-- Event Handlers
----------------------------------------------------

function CastHistoryTracker:OnCastEvent(casterGUID, targetGUID, eventType, spellID)
    -- Handles the UNIT_CASTEVENT to create spell frames based on filters.

    -- Check if event is a cast or channel event
    if eventType ~= "CAST" and eventType ~= "CHANNEL" then return end

    -- Get spell information
    local spellName, _, spellIcon = SpellInfo(spellID)
    if not spellIcon then return end

    -- Custom Icon Lookup
    local customIcon = CastHistoryTracker.customSpellIcons[spellID]
    if not customIcon then
        customIcon = CastHistoryTracker.customSpellIcons[spellName]
    end

    if customIcon then
        spellIcon = customIcon
    end

    -- Determine units to display for this caster GUID
    local unitsToDisplay = {}
    for unit, guid in pairs(CastHistoryTracker.trackedUnitGUIDs) do
        if guid == casterGUID then
            table.insert(unitsToDisplay, unit)
        end
    end
    if not next(unitsToDisplay) then return end -- Exit if no units to display

    local castInfo = { spellID = spellID, spellName = spellName } -- Define castInfo for history
    local frameCreated = false -- Flag to track if a frame was created

    -- Apply filtering based on current filter mode
    if CastHistoryTracker.currentFilterMode == "Simple" then
        -- Simple Mode Filtering
        local filterType = self.db.profile.filterTypeList
        local filterList = CastHistoryTracker.activeSimpleSpellFilters

        if filterType == "Whitelist" then
            if not filterList[spellID] and not filterList[spellName] then
                self:Debug(CastHistoryTracker.COLOR_SYSTEM .. "[OnCastEvent]: Spell " .. spellID .. " not in Simple Whitelist. Filtered out.")
            else
                self:Debug(CastHistoryTracker.COLOR_SYSTEM .. "[OnCastEvent]: Spell " .. spellID .. " in Simple Whitelist. Passing.")
                for _, unit in ipairs(unitsToDisplay) do
                    CastHistoryTracker:CreateSpellFrame(spellIcon, unit)
                    frameCreated = true
                end
            end

        elseif filterType == "Blacklist" then
            if filterList[spellID] or filterList[spellName] then
                self:Debug(CastHistoryTracker.COLOR_SYSTEM .. "[OnCastEvent]: Spell " .. spellID .. " in Simple Blacklist. Filtered out.")
            else
                self:Debug(CastHistoryTracker.COLOR_SYSTEM .. "[OnCastEvent]: Spell " .. spellID .. " not in Simple Blacklist. Passing.")
                for _, unit in ipairs(unitsToDisplay) do
                    CastHistoryTracker:CreateSpellFrame(spellIcon, unit)
                    frameCreated = true
                end
            end
        end

    elseif CastHistoryTracker.currentFilterMode == "Advanced" then
        local genericUnitFor = {} -- Table to store generic unit type for each unit
        for _, unit in ipairs(unitsToDisplay) do
            local genericUnit = unit
            if string.find(unit, "party") then
                genericUnit = "party"
            elseif string.find(unit, "focus") then
                genericUnit = "focus"
            end
            genericUnitFor[unit] = genericUnit
        end

        for _, unit in ipairs(unitsToDisplay) do
            local activeFilterTable
            local filterType

            if unit == "player" then
                activeFilterTable = CastHistoryTracker.activeAdvancedPlayerFilters
                filterType = self.db.profile.UnitFilterTypes["player"] or "Blacklist"
            elseif unit == "target" then
                activeFilterTable = CastHistoryTracker.activeAdvancedTargetFilters
                filterType = self.db.profile.UnitFilterTypes["target"] or "Blacklist"
            elseif genericUnitFor[unit] == "party" then
                activeFilterTable = CastHistoryTracker.activeAdvancedPartyFilters
                filterType = self.db.profile.UnitFilterTypes["party"] or "Blacklist"
            elseif genericUnitFor[unit] == "focus" then
                activeFilterTable = CastHistoryTracker.activeAdvancedFocusFilters
                filterType = self.db.profile.UnitFilterTypes["focus"] or "Blacklist"
            end

            if activeFilterTable then
                if filterType == "Whitelist" then
                    if activeFilterTable[spellID] or activeFilterTable[spellName] then
                        CastHistoryTracker:CreateSpellFrame(spellIcon, unit)
                        frameCreated = true
                    end
                elseif filterType == "Blacklist" then
                    if not activeFilterTable[spellID] and not activeFilterTable[spellName] then
                        CastHistoryTracker:CreateSpellFrame(spellIcon, unit)
                        frameCreated = true
                    end
                end
            end
        end
    end

    -- Add to spell history if a frame was created and refresh GUI if open
    if frameCreated then -- Only insert into history if a frame was created
        table.insert(CastHistoryTracker.spellHistory, castInfo)
    end

    if table.getn(CastHistoryTracker.spellHistory) > CastHistoryTracker.MAX_SPELL_HISTORY then
        table.remove(CastHistoryTracker.spellHistory, 1)
    end

    if CastHistoryTrackerConfigFrame:IsShown() then
        self:RefreshSpellList()
    end
end


function CastHistoryTracker:OnPlayerTargetChanged()
    -- Handles PLAYER_TARGET_CHANGED event to update target unit GUID.
    UpdateTrackedUnitGUID(self, "target")
end


function CastHistoryTracker:OnPartyMembersChanged()
    -- Handles PARTY_MEMBERS_CHANGED event to update party member GUIDs.
    for i = 1, 4 do
        UpdateTrackedUnitGUID(self, "party"..i)
    end
end