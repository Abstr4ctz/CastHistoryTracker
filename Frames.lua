-- Frames.lua
-- Spell icon frame creation and management.

local CastHistoryTracker = CastHistoryTrackerNamespace.CastHistoryTracker

----------------------------------------------------
-- Frame Creation and Management
----------------------------------------------------

function CastHistoryTracker:CreateSpellFrame(icon, unit)
    -- Creates and animates a spell icon frame for a given unit.

    -- Check if unit display is enabled
    if unit == "player" and not self.db.profile.showPlayer then return end
    if unit == "target" and not self.db.profile.showTarget then return end
    if string.find(unit, "party") and not self.db.profile.showParty then return end

    -- Get the frames table for the unit, initializing if necessary
    local frames = CastHistoryTracker.frames[unit]
    if not frames then
        CastHistoryTracker.frames[unit] = {}
        frames = CastHistoryTracker.frames[unit]
    end

    self:Debug(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: Creating frame for " .. unit)

    -- Cleanup faded frames
    local i = table.getn(frames)
    while i > 0 do
        local frameData = frames[i]
        if frameData and frameData.isFaded then
            self:CleanupFrame(frameData)
            table.remove(frames, i)
        end
        i = i - 1
    end

    -- Shift existing frames to the right
    local activeFrames = table.getn(frames)
    local shiftAmount  = math.min(activeFrames, CastHistoryTracker.MAX_FRAMES - 1)

    for i = activeFrames, 1, -1 do
        local frameData = frames[i]
        frameData.targetOffsetX = (i) * (self:GetFrameSize(unit) + 5)
        frameData.startTime   = GetTime()
        frameData.moveDuration = self.db.profile.moveDuration
        frameData.frame:SetFrameStrata("MEDIUM")
    end

    -- Get a frameData table from the Compost object pool
    local frameData = self.Compost:GetTable()

    -- Create the frame
    local frame = CreateFrame("Frame", nil, UIParent)
    local frameSize = self:GetFrameSize(unit)
    frame:SetWidth(frameSize)
    frame:SetHeight(frameSize)
    frame:SetPoint("CENTER", "CastHistoryTrackerAnchor"..unit, "CENTER", 0, 0)
    frame:SetFrameStrata("HIGH")
    frame:Show()

    -- Create the texture and set the spell icon
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    texture:SetTexture(icon)
    texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    -- Initialize frame data
    frameData.fadeTime      = self.db.profile.fadeTime
    frameData.elapsed       = 0
    frameData.isFaded       = false
    frameData.startTime     = GetTime()
    frameData.moveDuration  = self.db.profile.moveDuration
    frameData.targetOffsetX = 0
    frameData.currentOffsetX = 0
    frameData.unit = unit
    frameData.frame = frame

    -- Frame Animation (Movement and Fade) - OnUpdate script
    local lastUpdateTime = GetTime()
    frame:SetScript("OnUpdate", function()
        local now = GetTime()
        local deltaTime = now - lastUpdateTime
        lastUpdateTime = now

        -- Movement Animation
        if not frameData.startTime then frameData.startTime = now end
        local progress = (now - frameData.startTime) / frameData.moveDuration
        if progress < 1 then
            local deltaX = (frameData.targetOffsetX - frameData.currentOffsetX) * progress
            frameData.currentOffsetX = frameData.currentOffsetX + deltaX
            frame:SetPoint("CENTER", "CastHistoryTrackerAnchor"..unit, "CENTER", frameData.currentOffsetX, 0)
        end

        -- Fade Animation
        frameData.elapsed = (frameData.elapsed or 0) + deltaTime
        frameData.isFaded = frameData.elapsed >= frameData.fadeTime
        frame:SetAlpha(frameData.isFaded and 0 or 1 - (frameData.elapsed / frameData.fadeTime))
        if frameData.isFaded then
            frame:SetScript("OnUpdate", nil)
        end
    end)

    -- Insert the new frameData at the beginning of the frames table
    table.insert(frames, 1, frameData)
end


----------------------------------------------------
-- Frame Cleanup
----------------------------------------------------

function CastHistoryTracker:CleanupFrame(frameData)
    -- Cleans up a frame and reclaims its associated data.

    if frameData.frame then
        self:Debug("[CleanupFrame] Cleaning frame for unit: " .. frameData.unit)
        frameData.frame:Hide()          -- Hide the frame
        frameData.frame:SetParent(nil)  -- Detach from UI
    else
        self:Debug(CastHistoryTracker.COLOR_ERROR .. "[CleanupFrame] frameData.frame is nil during cleanup for unit: " .. frameData.unit .. ". Possible GC issue?")
    end
    self.Compost:Reclaim(frameData) -- Reclaim frameData table for reuse
end