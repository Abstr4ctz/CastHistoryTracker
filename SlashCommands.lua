-- SlashCommands.lua
-- Handles slash commands for Cast History Tracker (CHT).

local CastHistoryTracker = CastHistoryTrackerNamespace.CastHistoryTracker


----------------------------------------------------
-- Helper Functions
----------------------------------------------------

local function ValidateNumber(value, min, max)
    -- Validates if a value is a number within a specified range, returns boolean and message.
    if not value then
        return false, CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker] " .. CastHistoryTracker.COLOR_ERROR .. "Number required.|r"
    elseif value < min or value > max then
        return false, CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker] " .. CastHistoryTracker.COLOR_ERROR ..
                   "Value must be between " .. CastHistoryTracker.COLOR_VALUE .. min ..
                   CastHistoryTracker.COLOR_ERROR .. " and " .. CastHistoryTracker.COLOR_VALUE .. max .. CastHistoryTracker.COLOR_ERROR .. ".|r"
    else
        return true
    end
end


local function HandleValueCommand(self, command, value, min, max, settingName, description)
    -- Handles slash commands that set numerical settings with validation and feedback.
    if not value then
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker] " .. CastHistoryTracker.COLOR_DESCRIPTION .. "Current " .. description .. " is " .. CastHistoryTracker.COLOR_VALUE .. tostring(self.db.profile[settingName]) .. "|r")
        return
    end

    local isValid, message = ValidateNumber(value, min, max)
    if isValid then
        self:UpdateSetting(settingName, value)
    elseif message then
        DEFAULT_CHAT_FRAME:AddMessage(message)
    end
end


----------------------------------------------------
-- Slash Command Handler
----------------------------------------------------

SLASH_CHT1 = "/cht"
SlashCmdList["CHT"] = function(msg)
    -- Main slash command handler for /cht.
    local args = {}
    if msg and msg ~= "" then
        for word in string.gfind(msg, "%S+") do
            table.insert(args, word)
        end
    end

   local function printHelpMessage()
        -- Prints help message with available commands.
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_HEADER .. "[CastHistoryTracker] Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "/cht debug " .. CastHistoryTracker.COLOR_DESCRIPTION .. "- Toggle debug mode.|r")
		DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "/cht size " .. CastHistoryTracker.COLOR_VALUE .. "<player|target|party|focus|all> <number> " .. CastHistoryTracker.COLOR_DESCRIPTION .. "- Set frame size.|r")
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "/cht fade " .. CastHistoryTracker.COLOR_VALUE .. "<number> " .. CastHistoryTracker.COLOR_DESCRIPTION .. "- Set fade time (" .. CastHistoryTracker.COLOR_VALUE .. CastHistoryTracker.MIN_FADE_TIME .. CastHistoryTracker.COLOR_DESCRIPTION .. "-" .. CastHistoryTracker.COLOR_VALUE .. CastHistoryTracker.MAX_FADE_TIME .. CastHistoryTracker.COLOR_DESCRIPTION .. ").|r")
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "/cht move " .. CastHistoryTracker.COLOR_VALUE .. "<number> " .. CastHistoryTracker.COLOR_DESCRIPTION .. "- Set move duration (" .. CastHistoryTracker.COLOR_VALUE .. CastHistoryTracker.MIN_MOVE_DURATION .. CastHistoryTracker.COLOR_DESCRIPTION .. "-" .. CastHistoryTracker.COLOR_VALUE .. CastHistoryTracker.MAX_MOVE_DURATION .. CastHistoryTracker.COLOR_DESCRIPTION .. ").|r")
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "/cht lock " .. CastHistoryTracker.COLOR_DESCRIPTION .. "- Toggle anchor lock.|r")
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "/cht focus " .. CastHistoryTracker.COLOR_VALUE .. "<1-5> " .. CastHistoryTracker.COLOR_DESCRIPTION .. "- Set/Clear focus target.|r")
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "/cht clear " .. CastHistoryTracker.COLOR_DESCRIPTION .. "- Clear all focuses.|r")
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "/cht reset " .. CastHistoryTracker.COLOR_DESCRIPTION .. "- Reset anchor positions.|r")
		DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "/cht show " .. CastHistoryTracker.COLOR_VALUE .. "<player|target|party> " .. CastHistoryTracker.COLOR_DESCRIPTION .. "- Toggle unit frame visibility.|r")
		DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "/cht config " .. CastHistoryTracker.COLOR_DESCRIPTION .. "- Show/Hide config GUI.|r")
	end

	local function printShowStatus(self)
		-- Prints current visibility status of tracked units.
		DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_HEADER .. "[CastHistoryTracker] Visibility Status:|r")
		DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "Player:|r " .. (self.db.profile.showPlayer and CastHistoryTracker.COLOR_VALUE .. "Visible|r" or CastHistoryTracker.COLOR_VALUE .. "Hidden|r"))
		DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "Target:|r " .. (self.db.profile.showTarget and CastHistoryTracker.COLOR_VALUE .. "Visible|r" or CastHistoryTracker.COLOR_VALUE .. "Hidden|r"))
		DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "Party:|r " .. (self.db.profile.showParty and CastHistoryTracker.COLOR_VALUE .. "Visible|r" or CastHistoryTracker.COLOR_VALUE .. "Hidden|r"))
	end

    if table.getn(args) == 0 then
        printHelpMessage()
        return
    end

    local cmd = args[1]

    if cmd == "size" then
        if table.getn(args) == 2 then
            CastHistoryTracker:HandleSizeCommand(nil, tonumber(args[2]))
        else
            CastHistoryTracker:HandleSizeCommand(args[2], tonumber(args[3]))
        end
    elseif cmd == "fade" then
        CastHistoryTracker:HandleFadeCommand(tonumber(args[2]))
    elseif cmd == "move" then
        CastHistoryTracker:HandleMoveCommand(tonumber(args[2]))
    elseif cmd == "lock" then
        CastHistoryTracker:HandleLockCommand()
    elseif cmd == "focus" then
        local focusNum = args[2]
        if focusNum and tonumber(focusNum) then
            local focusNumber = tonumber(focusNum)
            if focusNumber >= 1 and focusNumber <= 5 then
                CastHistoryTracker:HandleFocusCommand("focus"..focusNumber)
            else
                DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Invalid focus number. Use 1-5.|r")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Focus number required. Use /cht focus <1-5>.|r")
        end
    elseif cmd == "clear" then
        CastHistoryTracker:ClearAllFocusUnits()
    elseif cmd == "reset" then
        CastHistoryTracker:HandleResetCommand()
    elseif cmd == "debug" then
        CastHistoryTracker:ToggleDebugMode()
	elseif cmd == "show" then
		if args[2] then
			local unit = args[2]
			if unit == "player" or unit == "target" or unit == "party" then
				CastHistoryTracker:HandleShowCommand(unit)
			else
				DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Invalid unit. Use player, target, or party.|r")
			end
		else
			printShowStatus(CastHistoryTracker)
		end
	elseif cmd == "config" then
        if CastHistoryTrackerConfigFrame:IsShown() then
            CastHistoryTrackerConfigFrame:Hide()
        else
            CastHistoryTrackerConfigFrame:Show()
			CastHistoryTracker:RefreshSpellList()
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Unknown command. Type /cht for help.|r")
    end
end


----------------------------------------------------
-- Command Handlers
----------------------------------------------------

function CastHistoryTracker:HandleSizeCommand(target, value)
    -- Handles the /cht size command to set frame sizes.
    local validTargets = { player = true, target = true, party = true, focus = true, all = true }

    if not target and not value then
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_HEADER .. "[CastHistoryTracker]: Frame Sizes:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  " .. CastHistoryTracker.COLOR_COMMAND .. "Player:|r " .. CastHistoryTracker.COLOR_VALUE .. self:GetFrameSize("player") .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("  " .. CastHistoryTracker.COLOR_COMMAND .. "Target:|r " .. CastHistoryTracker.COLOR_VALUE .. self:GetFrameSize("target") .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("  " .. CastHistoryTracker.COLOR_COMMAND .. "Party:|r " .. CastHistoryTracker.COLOR_VALUE .. self:GetFrameSize("party") .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("  " .. CastHistoryTracker.COLOR_COMMAND .. "Focus:|r " .. CastHistoryTracker.COLOR_VALUE .. self:GetFrameSize("focus") .. "|r")
        return
    end

    local function setAllSizes(size)
        -- Local function to set frame size for all unit types.
        self.db.profile.playerFrameSize = size
        self.db.profile.targetFrameSize = size
        self.db.profile.partyFrameSize = size
        self.db.profile.focusFrameSize = size

        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: " .. CastHistoryTracker.COLOR_DESCRIPTION .. "All frame sizes set to " .. CastHistoryTracker.COLOR_VALUE .. tostring(size) .. "|r")

        for unit, frames in pairs(CastHistoryTracker.frames) do
            for i = table.getn(frames), 1, -1 do
                local frameData = frames[i]
                if frameData and frameData.frame and frameData.frame:GetScript("OnUpdate") then
                    frameData.frame:Hide()
                    frameData.frame:SetScript("OnUpdate", nil)
                    self.Compost:Reclaim(frameData)
                    table.remove(frames, i)
                end
            end
        end

        for unit in pairs(validTargets) do
            if unit ~= "all" then
                self:UpdateFrameSize(unit, size)
            end
        end
    end

    if not target and value then
        local isValid, message = ValidateNumber(value, CastHistoryTracker.MIN_FRAME_SIZE, CastHistoryTracker.MAX_FRAME_SIZE)
        if not isValid then
            DEFAULT_CHAT_FRAME:AddMessage(message)
            return
        end
        setAllSizes(value)
        return
    end

    if target == "all" and value then
        local isValid, message = ValidateNumber(value, CastHistoryTracker.MIN_FRAME_SIZE, CastHistoryTracker.MAX_FRAME_SIZE)
        if not isValid then
            DEFAULT_CHAT_FRAME:AddMessage(message)
            return
        end
        setAllSizes(value)
        return
    end

    if target and value then
        local isValid, message = ValidateNumber(value, CastHistoryTracker.MIN_FRAME_SIZE, CastHistoryTracker.MAX_FRAME_SIZE)
        if not isValid then
            DEFAULT_CHAT_FRAME:AddMessage(message)
            return
        end

        if validTargets[target] then
            self:UpdateFrameSize(target, value)
            DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: " .. CastHistoryTracker.COLOR_DESCRIPTION .. target .. " frame size set to " .. CastHistoryTracker.COLOR_VALUE .. tostring(value) .. "|r")

            local updateUnits = {}
            if target == "party" then
                updateUnits = {"party1", "party2", "party3", "party4"}
            elseif target == "focus" then
                updateUnits = {"focus1", "focus2", "focus3", "focus4", "focus5"}
            else
                updateUnits = {target}
            end

            for _, unit in pairs(updateUnits) do
                local frames = CastHistoryTracker.frames[unit]
                if frames then
                    for i = table.getn(frames), 1, -1 do
                        local frameData = frames[i]
                        if frameData and frameData.frame and frameData.frame:GetScript("OnUpdate") then
                            frameData.frame:Hide()
                            frameData.frame:SetScript("OnUpdate", nil)
                            self.Compost:Reclaim(frameData)
                            table.remove(frames, i)
                        end
                    end
                end
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Invalid target|r")
        end
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_ERROR .. "[CastHistoryTracker]: Usage: /cht size <player|target|party|focus|all> <number>|r")
end


function CastHistoryTracker:HandleFadeCommand(value)
    -- Handles the /cht fade command to set fade time.
    HandleValueCommand(self, "fade", value, CastHistoryTracker.MIN_FADE_TIME, CastHistoryTracker.MAX_FADE_TIME, "fadeTime", "fade time")
end


function CastHistoryTracker:HandleMoveCommand(value)
    -- Handles the /cht move command to set move duration.
    HandleValueCommand(self, "move", value, CastHistoryTracker.MIN_MOVE_DURATION, CastHistoryTracker.MAX_MOVE_DURATION, "moveDuration", "move duration")
end


function CastHistoryTracker:HandleLockCommand()
    -- Handles the /cht lock command to toggle anchor lock.
    self:ToggleAnchorLock()
    if self.db.profile.locked then
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker] " .. CastHistoryTracker.COLOR_DESCRIPTION .. "Anchors Locked (Hidden)|r") -- Improved feedback
    else
        DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker] " .. CastHistoryTracker.COLOR_DESCRIPTION .. "Anchors Unlocked (Visible)|r") -- Improved feedback
    end
end


function CastHistoryTracker:HandleFocusCommand(focus)
    -- Handles the /cht focus command to set or clear focus units.
    local guid = self:SetUnitFocus(focus)
    if guid then
        self:CreateAnchorFrameForFocus(focus)
    end
end


function CastHistoryTracker:HandleShowCommand(unit)
    -- Handles the /cht show command to toggle unit frame visibility.
	local setting = "show" .. string.upper(string.sub(unit, 1, 1)) .. string.sub(unit, 2)
	self.db.profile[setting] = not self.db.profile[setting]
	local visibility = self.db.profile[setting] and CastHistoryTracker.COLOR_VALUE .. "Visible|r" or CastHistoryTracker.COLOR_VALUE .. "Hidden|r"
	DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker]: " .. CastHistoryTracker.COLOR_DESCRIPTION .. unit .. " frames are now " .. visibility)

	self:UpdateTrackedUnitGUIDs()
end


----------------------------------------------------
-- New Command Handlers
----------------------------------------------------

function CastHistoryTracker:HandleResetCommand()
    -- Handles the /cht reset command to reset anchor positions to default.
    local defaultPositions = {
        player = { x = UIParent:GetWidth() / 2, y = UIParent:GetHeight() / 2 - 150 },
        target = { x = TargetFrame:GetRight() + 10, y = TargetFrame:GetTop() - (TargetFrame:GetHeight()/2) },
        party1 = { x = PartyMemberFrame1:GetRight() + 50, y = PartyMemberFrame1:GetTop() - (PartyMemberFrame1:GetHeight()/2) },
        party2 = { x = PartyMemberFrame2:GetRight() + 50, y = UIParent:GetHeight() / 2 - 150 },
        party3 = { x = PartyMemberFrame3:GetRight() + 50, y = UIParent:GetHeight() / 2 - 150 },
        party4 = { x = PartyMemberFrame4:GetRight() + 50, y = UIParent:GetHeight() / 2 - 150 },
        focus1  = { x = UIParent:GetWidth() - 350, y = UIParent:GetHeight() - 300 },
        focus2 = { x = UIParent:GetWidth() - 350, y = UIParent:GetHeight() - 370 },
        focus3 = { x = UIParent:GetWidth() - 350, y = UIParent:GetHeight() - 440 },
        focus4 = { x = UIParent:GetWidth() - 350, y = UIParent:GetHeight() - 510 },
        focus5 = { x = UIParent:GetWidth() - 350, y = UIParent:GetHeight() - 580 }
    }

    for unit, defaultPos in pairs(defaultPositions) do
        self.db.profile.anchorPositions[unit] = defaultPos
        if CastHistoryTracker.anchorFrames[unit] then
            CastHistoryTracker.anchorFrames[unit]:SetPoint("CENTER", UIParent, "BOTTOMLEFT", defaultPos.x, defaultPos.y)
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(CastHistoryTracker.COLOR_COMMAND .. "[CastHistoryTracker] " .. CastHistoryTracker.COLOR_DESCRIPTION .. "Anchor positions reset.|r")
end