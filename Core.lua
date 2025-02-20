-- Core.lua

CastHistoryTrackerNamespace = CastHistoryTrackerNamespace or {}
local CastHistoryTracker = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDB-2.0")
CastHistoryTrackerNamespace.CastHistoryTracker = CastHistoryTracker

----------------------------------------------------
-- Constants & Defaults
----------------------------------------------------

-- Frame appearance defaults and limits
CastHistoryTracker.DEFAULT_FRAME_SIZE   = 40
CastHistoryTracker.DEFAULT_FADE_TIME    = 5
CastHistoryTracker.DEFAULT_MOVE_DURATION = 0.25
CastHistoryTracker.MIN_FRAME_SIZE       = 10
CastHistoryTracker.MAX_FRAME_SIZE       = 100
CastHistoryTracker.MIN_FADE_TIME        = 1
CastHistoryTracker.MAX_FADE_TIME        = 10
CastHistoryTracker.MIN_MOVE_DURATION    = 0.1
CastHistoryTracker.MAX_MOVE_DURATION    = 1.0
CastHistoryTracker.MAX_FRAMES           = 5

-- Spell history limits
CastHistoryTracker.MAX_SPELL_HISTORY    = 100

-- Enhanced Color codes for chat output
CastHistoryTracker.COLOR_COMMAND     = "|cFF00FF00" -- Green
CastHistoryTracker.COLOR_VALUE       = "|cFFFFFF00" -- Yellow
CastHistoryTracker.COLOR_DESCRIPTION = "|cFFADD8E6" -- Light Blue
CastHistoryTracker.COLOR_ERROR       = "|cFFFF0000" -- Red
CastHistoryTracker.COLOR_HEADER      = "|cFFFFA500" -- Orange
CastHistoryTracker.COLOR_HIGHLIGHT   = "|cFFFFD700" -- Gold
CastHistoryTracker.COLOR_SYSTEM      = "|cFF800080" -- Purple
CastHistoryTracker.COLOR_DEBUG       = "|cFF808080" -- Gray

-- Units tracked by the addon
CastHistoryTracker.TRACKED_UNITS = {
    "player", "target", "party1", "party2", "party3", "party4",
    "focus1", "focus2", "focus3", "focus4", "focus5"
}

-- Initializes tables to hold addon data
CastHistoryTracker.frames = {}             -- Frames for spell icons
CastHistoryTracker.trackedUnitGUIDs = {}   -- GUIDs of tracked units
for _, unit in pairs(CastHistoryTracker.TRACKED_UNITS) do
	CastHistoryTracker.frames[unit] = {}    -- Initialize frame table for each unit
	CastHistoryTracker.trackedUnitGUIDs[unit] = nil -- Initialize GUID tracking for each unit
end

CastHistoryTracker.spellHistory = {}         -- History of cast spells
CastHistoryTracker.framePool = {}            -- Frame recycling
CastHistoryTracker.uniqueSpellIDs = {}        -- Tracks unique spell IDs for spell history display
CastHistoryTracker.activeSimpleSpellFilters = {} -- Active simple spell filter list
CastHistoryTracker.activeAdvancedPlayerFilters = {} -- Active advanced filters for player
CastHistoryTracker.activeAdvancedTargetFilters = {} -- Active advanced filters for target
CastHistoryTracker.activeAdvancedPartyFilters = {}  -- Active advanced filters for party
CastHistoryTracker.activeAdvancedFocusFilters = {}  -- Active advanced filters for focus

----------------------------------------------------
-- Addon Lifecycle Functions
----------------------------------------------------

function CastHistoryTracker:OnInitialize()
    -- Addon initialization sequence

    -- Initialize AceDB and Compost libraries
    self:RegisterDB("CastHistoryTrackerDB")
    self.Compost = AceLibrary("Compost-2.0")

    -- Register default profile settings using AceDB
    self:RegisterDefaults("profile", {
        playerFrameSize = self.DEFAULT_FRAME_SIZE,
        targetFrameSize = self.DEFAULT_FRAME_SIZE,
        partyFrameSize  = self.DEFAULT_FRAME_SIZE,
        focusFrameSize  = self.DEFAULT_FRAME_SIZE,
        fadeTime        = self.DEFAULT_FADE_TIME,
        moveDuration    = self.DEFAULT_MOVE_DURATION,
        anchorPositions = { -- Default anchor positions for each unit frame
            player = { x = UIParent:GetWidth() / 2, y = UIParent:GetHeight() / 2 - 150 },
            target = { x = TargetFrame:GetRight() + 10, y = TargetFrame:GetTop() - (TargetFrame:GetHeight()/2) },
            party1 = { x = PartyMemberFrame1:GetRight() + 50, y = PartyMemberFrame1:GetTop() - (PartyMemberFrame1:GetHeight()/2) },
            party2 = { x = PartyMemberFrame2:GetRight() + 50, y = PartyMemberFrame2:GetTop() - (PartyMemberFrame2:GetHeight()/2) },
            party3 = { x = PartyMemberFrame3:GetRight() + 50, y = PartyMemberFrame3:GetTop() - (PartyMemberFrame3:GetHeight()/2) },
            party4 = { x = PartyMemberFrame4:GetRight() + 50, y = PartyMemberFrame4:GetTop() - (PartyMemberFrame4:GetHeight()/2) },
            focus1 = { x = UIParent:GetWidth() - 350, y = UIParent:GetHeight() - 300 },
            focus2 = { x = UIParent:GetWidth() - 350, y = UIParent:GetHeight() - 370 },
            focus3 = { x = UIParent:GetWidth() - 350, y = UIParent:GetHeight() - 440 },
            focus4 = { x = UIParent:GetWidth() - 350, y = UIParent:GetHeight() - 510 },
            focus5 = { x = UIParent:GetWidth() - 350, y = UIParent:GetHeight() - 580 }
        },
        locked          = true,
        debugMode       = false,
        useAdvancedFilter = false,
        filterMode      = "Simple",
        filterTypeList  = "Blacklist",
        showPlayer      = true,
        showTarget      = true,
        showParty       = true,
        SimpleBlacklist = {},
        SimpleWhitelist = {},
        AdvancedBlacklist = { player = {}, target = {}, party = {}, focus = {} },
        AdvancedWhitelist = { player = {}, target = {}, party = {}, focus = {} },
        UnitFilterTypes = { player = "Blacklist", target = "Blacklist", party = "Blacklist", focus = "Blacklist" }
    })

    -- Initialize anchor frames
    self.anchorFrames = {}

    -- Update settings from profile
    self:UpdateAllSettings()

    -- Register game event listeners
    self:RegisterEvent("UNIT_CASTEVENT", "OnCastEvent")
    self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnPlayerTargetChanged")
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", "OnPartyMembersChanged")

    -- Create configuration GUI
	self:CreateGUI()

    DEFAULT_CHAT_FRAME:AddMessage(self.COLOR_HEADER .. "[CastHistoryTracker]: |r" .. self.COLOR_HIGHLIGHT .. "Loaded! |r" .. self.COLOR_HEADER .. "Ready.|r")
end


function CastHistoryTracker:OnEnable()
    -- Create anchor frames
    for _, unit in pairs(self.TRACKED_UNITS) do
        self:CreateAnchorFrame(unit)
    end

    -- Update GUIDs of tracked units
    self:UpdateTrackedUnitGUIDs()

    -- Load Active Filter Lists
    if self.db.profile.filterMode == "Simple" then
        self:LoadSimpleFilterList()
    elseif self.db.profile.filterMode == "Advanced" then
        self:LoadActiveFiltersForAdvancedMode()
    end
    self.currentFilterMode = self.db.profile.filterMode -- Remember Active Filter

    if self.trackedUnitGUIDs["player"] then
        self:Debug(self.COLOR_SYSTEM .. "[CastHistoryTracker]: Player GUID " .. self.trackedUnitGUIDs["player"])
    else
        self:Debug(self.COLOR_ERROR .. "[CastHistoryTracker]: Player frame hidden.")
    end
end