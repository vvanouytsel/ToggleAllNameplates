local addonName, addon = ...

-- Default settings
local defaultSettings = {
    enemyInOpenWorld              = false,
    friendlyPlayerInOpenWorld     = false,
    friendlyNPCInOpenWorld        = false,
    enemyInDungeons               = true,
    friendlyPlayerInDungeons      = true,
    friendlyNPCInDungeons         = true,
    enemyInRaids                  = true,
    friendlyPlayerInRaids         = true,
    friendlyNPCInRaids            = true,
    enemyInScenarios              = true,
    friendlyPlayerInScenarios     = true,
    friendlyNPCInScenarios        = true,
    enemyInBattlegrounds          = false,
    friendlyPlayerInBattlegrounds = false,
    friendlyNPCInBattlegrounds    = false,
    enemyInArenas                 = false,
    friendlyPlayerInArenas        = false,
    friendlyNPCInArenas           = false,
    showStatusMessages            = true,
}

-- ToggleAllNameplatesDB is populated from disk by the engine before ADDON_LOADED fires.
-- Do NOT initialise it here; doing so would overwrite the saved data.

local function GetSetting(key)
    if ToggleAllNameplatesDB and ToggleAllNameplatesDB[key] ~= nil then
        return ToggleAllNameplatesDB[key]
    end
    return defaultSettings[key]
end

local function SetSetting(key, value)
    if not ToggleAllNameplatesDB then ToggleAllNameplatesDB = {} end
    ToggleAllNameplatesDB[key] = value
end

-- Determine which nameplate types should be shown in the current zone
-- instanceType values: "none", "party" (dungeon), "raid", "scenario", "pvp" (battleground), "arena"
-- Returns: enemyEnabled, friendlyPlayerEnabled, friendlyNPCEnabled
local function GetNameplateSettings()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        if instanceType == "scenario" then
            -- This happens for some Delves
            return GetSetting("enemyInScenarios"), GetSetting("friendlyPlayerInScenarios"), GetSetting("friendlyNPCInScenarios")
        end
        return GetSetting("enemyInOpenWorld"), GetSetting("friendlyPlayerInOpenWorld"), GetSetting("friendlyNPCInOpenWorld")
    end
    if instanceType == "party"    then return GetSetting("enemyInDungeons"),      GetSetting("friendlyPlayerInDungeons"),      GetSetting("friendlyNPCInDungeons")      end
    if instanceType == "raid"     then return GetSetting("enemyInRaids"),         GetSetting("friendlyPlayerInRaids"),         GetSetting("friendlyNPCInRaids")         end
    if instanceType == "scenario" then return GetSetting("enemyInScenarios"),     GetSetting("friendlyPlayerInScenarios"),     GetSetting("friendlyNPCInScenarios")     end
    if instanceType == "pvp"      then return GetSetting("enemyInBattlegrounds"), GetSetting("friendlyPlayerInBattlegrounds"), GetSetting("friendlyNPCInBattlegrounds") end
    if instanceType == "arena"    then return GetSetting("enemyInArenas"),        GetSetting("friendlyPlayerInArenas"),        GetSetting("friendlyNPCInArenas")        end
    return false, false, false
end

-- Apply nameplate CVars based on the current zone and settings
local function UpdateNameplates()
    local enemyEnabled, friendlyPlayerEnabled, friendlyNPCEnabled = GetNameplateSettings()

    if enemyEnabled or friendlyPlayerEnabled or friendlyNPCEnabled then
        SetCVar("nameplateShowAll", 1)
        SetCVar("nameplateShowEnemies", enemyEnabled and 1 or 0)
        SetCVar("nameplateShowFriends", friendlyPlayerEnabled and 1 or 0)
        SetCVar("nameplateShowFriendlyNPCs", friendlyNPCEnabled and 1 or 0)
    else
        SetCVar("nameplateShowAll", 0)
        SetCVar("nameplateShowEnemies", 1)
        SetCVar("nameplateShowFriends", 1)
        SetCVar("nameplateShowFriendlyNPCs", 1)
    end

    if GetSetting("showStatusMessages") then
        local parts = {}
        if enemyEnabled then table.insert(parts, "|cFF00FF00Enemy|r") end
        if friendlyPlayerEnabled then table.insert(parts, "|cFF00FF00Friendly player|r") end
        if friendlyNPCEnabled then table.insert(parts, "|cFF00FF00Friendly NPC|r") end

        if #parts == 3 then
            print("|cFF00FF00ToggleAllNameplates:|r Nameplates are now |cFF00FF00always shown|r for all units in this zone.")
        elseif #parts > 0 then
            print("|cFF00FF00ToggleAllNameplates:|r Showing: " .. table.concat(parts, ", ") .. " nameplates.")
        else
            print("|cFF00FF00ToggleAllNameplates:|r Nameplates are now |cFFFF4444hidden by default|r — only shown when targeted or interacted with.")
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Config panel (matches SpellCooldown layout style)
-- ─────────────────────────────────────────────────────────────────────────────
local configFrame = CreateFrame("Frame", "ToggleAllNameplatesConfig", UIParent)
configFrame.name = "ToggleAllNameplates"

-- Scroll frame
local scrollFrame = CreateFrame("ScrollFrame", nil, configFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 3, -4)
scrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(600, 900)
scrollFrame:SetScrollChild(scrollChild)

-- Title
local title = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("ToggleAllNameplates Settings")

local desc = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetText("Control enemy and friendly nameplate visibility per zone type.\nWhen disabled, nameplates are only shown when targeting or interacting with a unit.")

-- ── Section header ──────────────────────────────────────────────────────────
local sectionLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
sectionLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -24)
sectionLabel:SetText("Show Nameplates in:")

-- Helper to create a zone section with enemy, friendly player, and friendly NPC checkboxes
local zoneSections = {}
local function CreateZoneSection(anchor, offsetX, offsetY, zoneId, zoneName, enemyKey, friendlyPlayerKey, friendlyNPCKey)
    local section = {}

    section.header = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    section.header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", offsetX, offsetY)
    section.header:SetText(zoneName)

    local enemyName = "TANEnemy" .. zoneId
    section.enemyCB = CreateFrame("CheckButton", enemyName, scrollChild, "UICheckButtonTemplate")
    section.enemyCB:SetPoint("TOPLEFT", section.header, "BOTTOMLEFT", 16, -4)
    section.enemyCB:SetChecked(GetSetting(enemyKey))
    _G[enemyName .. "Text"]:SetText("Enemy nameplates")
    section.enemyCB.settingKey = enemyKey
    section.enemyCB:SetScript("OnClick", function(self)
        SetSetting(enemyKey, self:GetChecked())
        UpdateNameplates()
    end)

    local friendlyPlayerName = "TANFriendlyPlayer" .. zoneId
    section.friendlyPlayerCB = CreateFrame("CheckButton", friendlyPlayerName, scrollChild, "UICheckButtonTemplate")
    section.friendlyPlayerCB:SetPoint("TOPLEFT", section.enemyCB, "BOTTOMLEFT", 0, -2)
    section.friendlyPlayerCB:SetChecked(GetSetting(friendlyPlayerKey))
    _G[friendlyPlayerName .. "Text"]:SetText("Friendly player nameplates")
    section.friendlyPlayerCB.settingKey = friendlyPlayerKey
    section.friendlyPlayerCB:SetScript("OnClick", function(self)
        SetSetting(friendlyPlayerKey, self:GetChecked())
        UpdateNameplates()
    end)

    local friendlyNPCName = "TANFriendlyNPC" .. zoneId
    section.friendlyNPCCB = CreateFrame("CheckButton", friendlyNPCName, scrollChild, "UICheckButtonTemplate")
    section.friendlyNPCCB:SetPoint("TOPLEFT", section.friendlyPlayerCB, "BOTTOMLEFT", 0, -2)
    section.friendlyNPCCB:SetChecked(GetSetting(friendlyNPCKey))
    _G[friendlyNPCName .. "Text"]:SetText("Friendly NPC nameplates")
    section.friendlyNPCCB.settingKey = friendlyNPCKey
    section.friendlyNPCCB:SetScript("OnClick", function(self)
        SetSetting(friendlyNPCKey, self:GetChecked())
        UpdateNameplates()
    end)

    section.lastElement = section.friendlyNPCCB
    table.insert(zoneSections, section)
    return section
end

local openWorld = CreateZoneSection(sectionLabel, 0, -8,
    "OpenWorld", "Open World", "enemyInOpenWorld", "friendlyPlayerInOpenWorld", "friendlyNPCInOpenWorld")

local dungeons = CreateZoneSection(openWorld.lastElement, -16, -12,
    "Dungeons", "Dungeons (5-man instances)", "enemyInDungeons", "friendlyPlayerInDungeons", "friendlyNPCInDungeons")

local raids = CreateZoneSection(dungeons.lastElement, -16, -12,
    "Raids", "Raids", "enemyInRaids", "friendlyPlayerInRaids", "friendlyNPCInRaids")

local scenarios = CreateZoneSection(raids.lastElement, -16, -12,
    "Scenarios", "Scenarios", "enemyInScenarios", "friendlyPlayerInScenarios", "friendlyNPCInScenarios")

local battlegrounds = CreateZoneSection(scenarios.lastElement, -16, -12,
    "Battlegrounds", "Battlegrounds", "enemyInBattlegrounds", "friendlyPlayerInBattlegrounds", "friendlyNPCInBattlegrounds")

local arenas = CreateZoneSection(battlegrounds.lastElement, -16, -12,
    "Arenas", "Arenas", "enemyInArenas", "friendlyPlayerInArenas", "friendlyNPCInArenas")

-- ── Section header (notifications) ──────────────────────────────────────────
local notifSectionLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
notifSectionLabel:SetPoint("TOPLEFT", arenas.lastElement, "BOTTOMLEFT", -16, -24)
notifSectionLabel:SetText("Notifications:")

local statusMsgCheckbox = CreateFrame("CheckButton", "TANStatusMessagesCheckbox", scrollChild, "UICheckButtonTemplate")
statusMsgCheckbox:SetPoint("TOPLEFT", notifSectionLabel, "BOTTOMLEFT", 0, -8)
statusMsgCheckbox:SetChecked(GetSetting("showStatusMessages"))
_G[statusMsgCheckbox:GetName() .. "Text"]:SetText("Show console notifications")
statusMsgCheckbox:SetScript("OnClick", function(self)
    SetSetting("showStatusMessages", self:GetChecked())
end)

local statusMsgDesc = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
statusMsgDesc:SetPoint("TOPLEFT", statusMsgCheckbox, "BOTTOMLEFT", 20, -2)
statusMsgDesc:SetText("Print addon messages to the console (e.g. when nameplates are shown or hidden).")

-- Refresh all config checkboxes to reflect the current (post-load) saved values.
-- Defined here because it references checkbox locals declared above.
local function RefreshCheckboxes()
    for _, section in ipairs(zoneSections) do
        section.enemyCB:SetChecked(GetSetting(section.enemyCB.settingKey))
        section.friendlyPlayerCB:SetChecked(GetSetting(section.friendlyPlayerCB.settingKey))
        section.friendlyNPCCB:SetChecked(GetSetting(section.friendlyNPCCB.settingKey))
    end
    statusMsgCheckbox:SetChecked(GetSetting("showStatusMessages"))
end

-- ── Current status label ──────────────────────────────────────────────────────
local statusLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
statusLabel:SetPoint("TOPLEFT", statusMsgDesc, "BOTTOMLEFT", 0, -30)
statusLabel:SetText("")

local zoneTypeNames = {
    ["open world"] = "Open World",
    ["party"]      = "Dungeon",
    ["raid"]       = "Raid",
    ["scenario"]   = "Scenario",
    ["pvp"]        = "Battleground",
    ["arena"]      = "Arena",
}

local function RefreshStatusLabel()
    local inInstance, instanceType = IsInInstance()
    local rawType = inInstance and instanceType or "open world"
    local displayType = zoneTypeNames[rawType] or rawType
    statusLabel:SetText("Current zone type: |cFFFFD100" .. displayType .. "|r")
end

-- Refresh status when config panel is shown
configFrame:SetScript("OnShow", RefreshStatusLabel)

-- ── Register config panel ─────────────────────────────────────────────────────
local settingsCategoryID = nil
if Settings and Settings.RegisterCanvasLayoutCategory then
    local category, layout = Settings.RegisterCanvasLayoutCategory(configFrame, "ToggleAllNameplates")
    Settings.RegisterAddOnCategory(category)
    settingsCategoryID = category:GetID()
else
    InterfaceOptions_AddCategory(configFrame)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Slash command  /tan  (Toggle All Nameplates)
-- ─────────────────────────────────────────────────────────────────────────────
SLASH_TOGGLEALLNAMEPLATES1 = "/tan"
SLASH_TOGGLEALLNAMEPLATES2 = "/togglenameplates"
SlashCmdList["TOGGLEALLNAMEPLATES"] = function(msg)
    local cmd = strtrim(msg):lower()
    if cmd == "config" or cmd == "options" then
        if Settings and Settings.OpenToCategory and settingsCategoryID then
            Settings.OpenToCategory(settingsCategoryID)
        else
            InterfaceOptionsFrame_OpenToCategory(configFrame)
        end
    else
        -- Manual toggle matching the original macro behaviour
        local v = GetCVar("nameplateShowAll")
        if v == "1" then
            SetCVar("nameplateShowAll", 0)
            SetCVar("nameplateShowEnemies", 1)
            SetCVar("nameplateShowFriends", 1)
            SetCVar("nameplateShowFriendlyNPCs", 1)
            print("|cFF00FF00ToggleAllNameplates:|r Nameplates manually set to |cFFFF4444hidden by default|r.")
        else
            SetCVar("nameplateShowAll", 1)
            SetCVar("nameplateShowEnemies", 1)
            SetCVar("nameplateShowFriends", 1)
            SetCVar("nameplateShowFriendlyNPCs", 1)
            print("|cFF00FF00ToggleAllNameplates:|r Nameplates manually set to |cFF00FF00always shown|r for all units.")
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Event handling
-- ─────────────────────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("LOADING_SCREEN_DISABLED")

eventFrame:SetScript("OnEvent", function(self, event, arg1, isReloadingUi)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- SavedVariables are now available; initialise DB if this is a first install.
        if not ToggleAllNameplatesDB then ToggleAllNameplatesDB = {} end
        -- Migrate from pre-1.1 single-toggle settings to enemy/friendly pairs.
        local migrationMap = {
            enableInOpenWorld     = { "enemyInOpenWorld",     "friendlyPlayerInOpenWorld",     "friendlyNPCInOpenWorld"     },
            enableInDungeons      = { "enemyInDungeons",      "friendlyPlayerInDungeons",      "friendlyNPCInDungeons"      },
            enableInRaids         = { "enemyInRaids",         "friendlyPlayerInRaids",         "friendlyNPCInRaids"         },
            enableInScenarios     = { "enemyInScenarios",     "friendlyPlayerInScenarios",     "friendlyNPCInScenarios"     },
            enableInBattlegrounds = { "enemyInBattlegrounds", "friendlyPlayerInBattlegrounds", "friendlyNPCInBattlegrounds" },
            enableInArenas        = { "enemyInArenas",        "friendlyPlayerInArenas",        "friendlyNPCInArenas"        },
        }
        for oldKey, newKeys in pairs(migrationMap) do
            if ToggleAllNameplatesDB[oldKey] ~= nil then
                for _, newKey in ipairs(newKeys) do
                    if ToggleAllNameplatesDB[newKey] == nil then
                        ToggleAllNameplatesDB[newKey] = ToggleAllNameplatesDB[oldKey]
                    end
                end
                ToggleAllNameplatesDB[oldKey] = nil
            end
        end
        -- Migrate from pre-1.2 combined friendly settings to player/NPC split.
        local friendlyMigrationMap = {
            friendlyInOpenWorld     = { "friendlyPlayerInOpenWorld",     "friendlyNPCInOpenWorld"     },
            friendlyInDungeons      = { "friendlyPlayerInDungeons",      "friendlyNPCInDungeons"      },
            friendlyInRaids         = { "friendlyPlayerInRaids",         "friendlyNPCInRaids"         },
            friendlyInScenarios     = { "friendlyPlayerInScenarios",     "friendlyNPCInScenarios"     },
            friendlyInBattlegrounds = { "friendlyPlayerInBattlegrounds", "friendlyNPCInBattlegrounds" },
            friendlyInArenas        = { "friendlyPlayerInArenas",        "friendlyNPCInArenas"        },
        }
        for oldKey, newKeys in pairs(friendlyMigrationMap) do
            if ToggleAllNameplatesDB[oldKey] ~= nil then
                for _, newKey in ipairs(newKeys) do
                    if ToggleAllNameplatesDB[newKey] == nil then
                        ToggleAllNameplatesDB[newKey] = ToggleAllNameplatesDB[oldKey]
                    end
                end
                ToggleAllNameplatesDB[oldKey] = nil
            end
        end
        -- Sync checkboxes to persisted values.
        RefreshCheckboxes()
    elseif event == "PLAYER_LOGIN" then
        print("|cFF00FF00ToggleAllNameplates|r loaded! Use |cFFFFD100/tan|r to toggle manually, or |cFFFFD100/tan config|r to open settings.")
        UpdateNameplates()
    elseif event == "LOADING_SCREEN_DISABLED" then
        UpdateNameplates()
    end
end)
