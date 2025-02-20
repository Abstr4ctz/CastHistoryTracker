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

    -- Shift existing frames to the right
    local activeFrames = table.getn(frames)
    local shiftAmount  = math.min(activeFrames, CastHistoryTracker.MAX_FRAMES - 1)

    for i = activeFrames, 1, -1 do
        local frameData = frames[i]
        frameData.targetOffsetX = (i) * (self:GetFrameSize(unit) + 5)
        frameData.startTime   = GetTime()
        frameData.moveDuration = self.moveDurationCache
        frameData.frame:SetFrameStrata("MEDIUM")
    end

    -- Get a frame from the pool or create a new one
    local frame = table.remove(CastHistoryTracker.framePool) -- Try to get from pool
    if not frame then
        frame = CreateFrame("Frame", nil, UIParent) -- Create new if pool is empty
        self:Debug(CastHistoryTracker.COLOR_DEBUG .. "[CreateSpellFrame]: Creating NEW frame from scratch. Pool size: " .. table.getn(CastHistoryTracker.framePool)) -- Debug message to track pool usage
    else
        self:Debug(CastHistoryTracker.COLOR_DEBUG .. "[CreateSpellFrame]: Reusing frame from pool. Pool size: " .. table.getn(CastHistoryTracker.framePool)) -- Debug message to track pool usage
    end

    local frameSize = self:GetFrameSize(unit)
    frame:SetWidth(frameSize)
    frame:SetHeight(frameSize)
    frame:SetPoint("CENTER", "CastHistoryTrackerAnchor"..unit, "CENTER", 0, 0)
    frame:SetFrameStrata("HIGH")
    frame:Show()

    -- Create the texture and set the spell icon
    local texture = frame:GetRegions()
    if not texture or texture:GetObjectType() ~= "Texture" then
        texture = frame:CreateTexture(nil, "BACKGROUND")
        texture:SetAllPoints()
    end
    texture:SetTexture(icon)
    texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    -- Get a frameData table from the Compost object pool
    local frameData = self.Compost:GetTable()
    -- Initialize frame data
    frameData.fadeTime      = self.fadeTimeCache
    frameData.elapsed       = 0
    frameData.isFaded       = false
    frameData.startTime     = GetTime()
    frameData.moveDuration  = self.moveDurationCache
    frameData.targetOffsetX = 0
    frameData.currentOffsetX = 0
    frameData.unit = unit
    frameData.frame = frame

    -- Insert the new frameData at the beginning of the frames table
    table.insert(frames, 1, frameData)

	-- Add to active frames if OnUpdate isn't already running
    if not CastHistoryTracker.isUpdatingFrames then
      CastHistoryTracker:StartUpdatingFrames()
    end
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

        table.insert(CastHistoryTracker.framePool, frameData.frame) -- Return frame to the pool!
        self:Debug(CastHistoryTracker.COLOR_DEBUG .. "[CleanupFrame]: Returned frame to pool. Pool size: " .. table.getn(CastHistoryTracker.framePool))

    else
        self:Debug(CastHistoryTracker.COLOR_ERROR .. "[CleanupFrame] frameData.frame is nil during cleanup for unit: " .. frameData.unit .. ". Possible GC issue?")
    end
    self.Compost:Reclaim(frameData) -- Reclaim frameData table for reuse
end



----------------------------------------------------
-- Centralized Frame Update
----------------------------------------------------

function CastHistoryTracker:StartUpdatingFrames()
  if not CastHistoryTracker.isUpdatingFrames then
    CastHistoryTracker.isUpdatingFrames = true
    CastHistoryTracker.lastUpdateTime = GetTime()

    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        CastHistoryTracker:UpdateFrames(elapsed)
    end)
	self.updateFrame = updateFrame -- Store a reference so we can stop it later
  end
end

function CastHistoryTracker:StopUpdatingFrames()
	if self.isUpdatingFrames then
		self.isUpdatingFrames = false
		if self.updateFrame then
			self.updateFrame:SetScript("OnUpdate", nil)
			self.updateFrame = nil -- Remove the reference
		end
	end
end


function CastHistoryTracker:UpdateFrames(elapsed)
    local now = GetTime()
    local deltaTime = now - CastHistoryTracker.lastUpdateTime
    CastHistoryTracker.lastUpdateTime = now
    local anyFramesActive = false -- Flag to check if we need to keep updating

    for unit, frames in pairs(CastHistoryTracker.frames) do
        local i = table.getn(frames)
        while i > 0 do
            local frameData = frames[i]

            if frameData and frameData.frame then  -- Ensure frameData and frame exist
                if not frameData.isFaded then
                    anyFramesActive = true

                    -- Movement Animation
                    if not frameData.startTime then frameData.startTime = now end
                    local progress = (now - frameData.startTime) / frameData.moveDuration
                    if progress < 1 then
                        local deltaX = (frameData.targetOffsetX - frameData.currentOffsetX) * progress
                        frameData.currentOffsetX = frameData.currentOffsetX + deltaX
                        frameData.frame:SetPoint("CENTER", "CastHistoryTrackerAnchor"..frameData.unit, "CENTER", frameData.currentOffsetX, 0)
                    end

                    -- Fade Animation
                    frameData.elapsed = (frameData.elapsed or 0) + deltaTime
                    frameData.isFaded = frameData.elapsed >= frameData.fadeTime
                    frameData.frame:SetAlpha(frameData.isFaded and 0 or 1 - (frameData.elapsed / frameData.fadeTime))


                    if frameData.isFaded then
                       self:CleanupFrame(frameData)
                       table.remove(frames,i)
                    end
                else
					-- Just in case
					if frameData.isFaded then
						self:CleanupFrame(frameData)
						table.remove(frames, i)
					end
                end
            else
				-- If frameData or frameData.frame is nil remove from table
				table.remove(frames, i)
            end
            i = i - 1
        end
    end


    if not anyFramesActive then
        CastHistoryTracker:StopUpdatingFrames() -- Stop the update loop if no frames are active
    end

end