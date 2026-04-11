local addonName, addon = ...

-- Default settings
local defaultSettings = {
    enableInOpenWorld     = false,
    enableInDungeons      = true,
    enableInRaids         = true,
    enableInScenarios     = true,
    enableInBattlegrounds = false,
    enableInArenas        = false,
    showStatusMessages    = true,
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

-- Determine whether all nameplates should be shown in the current zone
-- instanceType values: "none", "party" (dungeon), "raid", "scenario", "pvp" (battleground), "arena"
local function ShouldShowNameplates()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        if instanceType == "scenario" then
            -- This happens for some Delves
            return GetSetting("enableInScenarios")
        end
        return GetSetting("enableInOpenWorld")
    end
    if instanceType == "party"    and GetSetting("enableInDungeons")      then return true end
    if instanceType == "raid"     and GetSetting("enableInRaids")         then return true end
    if instanceType == "scenario" and GetSetting("enableInScenarios")     then return true end
    if instanceType == "pvp"      and GetSetting("enableInBattlegrounds") then return true end
    if instanceType == "arena"    and GetSetting("enableInArenas")        then return true end
    return false
end

-- Apply the nameplate CVar based on the current zone and settings
local function UpdateNameplates()
    if ShouldShowNameplates() then
        SetCVar("nameplateShowAll", 1)
        if GetSetting("showStatusMessages") then
            print("|cFF00FF00ToggleAllNameplates:|r Nameplates are now |cFF00FF00always shown|r for all units in this zone.")
        end
    else
        SetCVar("nameplateShowAll", 0)
        if GetSetting("showStatusMessages") then
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
scrollChild:SetSize(600, 600)
scrollFrame:SetScrollChild(scrollChild)

-- Title
local title = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("ToggleAllNameplates Settings")

local desc = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetText("Automatically shows all nameplates for all units in selected zone types.\nWhen disabled for a zone, nameplates are only shown when targeting or interacting with a unit.")

-- ── Section header ──────────────────────────────────────────────────────────
local sectionLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
sectionLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -24)
sectionLabel:SetText("Always Show All Nameplates in:")

-- ── Open World checkbox ──────────────────────────────────────────────────────
local openWorldCheckbox = CreateFrame("CheckButton", "TANOpenWorldCheckbox", scrollChild, "UICheckButtonTemplate")
openWorldCheckbox:SetPoint("TOPLEFT", sectionLabel, "BOTTOMLEFT", 0, -8)
openWorldCheckbox:SetChecked(GetSetting("enableInOpenWorld"))
_G[openWorldCheckbox:GetName() .. "Text"]:SetText("Open World")
openWorldCheckbox:SetScript("OnClick", function(self)
    SetSetting("enableInOpenWorld", self:GetChecked())
    UpdateNameplates()
end)

local openWorldDesc = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
openWorldDesc:SetPoint("TOPLEFT", openWorldCheckbox, "BOTTOMLEFT", 20, -2)
openWorldDesc:SetText("Show all nameplates while out in the open world (not in any instance).")

-- ── Dungeons checkbox ────────────────────────────────────────────────────────
local dungeonsCheckbox = CreateFrame("CheckButton", "TANDungeonsCheckbox", scrollChild, "UICheckButtonTemplate")
dungeonsCheckbox:SetPoint("TOPLEFT", openWorldDesc, "BOTTOMLEFT", -20, -10)
dungeonsCheckbox:SetChecked(GetSetting("enableInDungeons"))
_G[dungeonsCheckbox:GetName() .. "Text"]:SetText("Dungeons (5-man instances)")
dungeonsCheckbox:SetScript("OnClick", function(self)
    SetSetting("enableInDungeons", self:GetChecked())
    UpdateNameplates()
end)

local dungeonsDesc = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
dungeonsDesc:SetPoint("TOPLEFT", dungeonsCheckbox, "BOTTOMLEFT", 20, -2)
dungeonsDesc:SetText("Show all nameplates when inside a 5-man dungeon or heroic dungeon.")

-- ── Raids checkbox ─────────────────────────────────────────────────────
local raidsCheckbox = CreateFrame("CheckButton", "TANRaidsCheckbox", scrollChild, "UICheckButtonTemplate")
raidsCheckbox:SetPoint("TOPLEFT", dungeonsDesc, "BOTTOMLEFT", -20, -10)
raidsCheckbox:SetChecked(GetSetting("enableInRaids"))
_G[raidsCheckbox:GetName() .. "Text"]:SetText("Raids")
raidsCheckbox:SetScript("OnClick", function(self)
    SetSetting("enableInRaids", self:GetChecked())
    UpdateNameplates()
end)

local raidsDesc = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
raidsDesc:SetPoint("TOPLEFT", raidsCheckbox, "BOTTOMLEFT", 20, -2)
raidsDesc:SetText("Show all nameplates when inside a raid instance.")

-- ── Scenarios checkbox ───────────────────────────────────────────────────────
local scenariosCheckbox = CreateFrame("CheckButton", "TANScenariosCheckbox", scrollChild, "UICheckButtonTemplate")
scenariosCheckbox:SetPoint("TOPLEFT", raidsDesc, "BOTTOMLEFT", -20, -10)
scenariosCheckbox:SetChecked(GetSetting("enableInScenarios"))
_G[scenariosCheckbox:GetName() .. "Text"]:SetText("Scenarios")
scenariosCheckbox:SetScript("OnClick", function(self)
    SetSetting("enableInScenarios", self:GetChecked())
    UpdateNameplates()
end)

local scenariosDesc = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
scenariosDesc:SetPoint("TOPLEFT", scenariosCheckbox, "BOTTOMLEFT", 20, -2)
scenariosDesc:SetText("Show all nameplates when inside a scenario.")

-- ── Battlegrounds checkbox ───────────────────────────────────────────────────
local bgCheckbox = CreateFrame("CheckButton", "TANBattlegroundsCheckbox", scrollChild, "UICheckButtonTemplate")
bgCheckbox:SetPoint("TOPLEFT", scenariosDesc, "BOTTOMLEFT", -20, -10)
bgCheckbox:SetChecked(GetSetting("enableInBattlegrounds"))
_G[bgCheckbox:GetName() .. "Text"]:SetText("Battlegrounds")
bgCheckbox:SetScript("OnClick", function(self)
    SetSetting("enableInBattlegrounds", self:GetChecked())
    UpdateNameplates()
end)

local bgDesc = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
bgDesc:SetPoint("TOPLEFT", bgCheckbox, "BOTTOMLEFT", 20, -2)
bgDesc:SetText("Show all nameplates when inside a battleground.")

-- ── Arenas checkbox ──────────────────────────────────────────────────────────
local arenaCheckbox = CreateFrame("CheckButton", "TANArenaCheckbox", scrollChild, "UICheckButtonTemplate")
arenaCheckbox:SetPoint("TOPLEFT", bgDesc, "BOTTOMLEFT", -20, -10)
arenaCheckbox:SetChecked(GetSetting("enableInArenas"))
_G[arenaCheckbox:GetName() .. "Text"]:SetText("Arenas")
arenaCheckbox:SetScript("OnClick", function(self)
    SetSetting("enableInArenas", self:GetChecked())
    UpdateNameplates()
end)

local arenaDesc = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
arenaDesc:SetPoint("TOPLEFT", arenaCheckbox, "BOTTOMLEFT", 20, -2)
arenaDesc:SetText("Show all nameplates when inside an arena.")

-- ── Section header (notifications) ──────────────────────────────────────────
local notifSectionLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
notifSectionLabel:SetPoint("TOPLEFT", arenaDesc, "BOTTOMLEFT", -20, -24)
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
    openWorldCheckbox:SetChecked(GetSetting("enableInOpenWorld"))
    dungeonsCheckbox:SetChecked(GetSetting("enableInDungeons"))
    raidsCheckbox:SetChecked(GetSetting("enableInRaids"))
    scenariosCheckbox:SetChecked(GetSetting("enableInScenarios"))
    bgCheckbox:SetChecked(GetSetting("enableInBattlegrounds"))
    arenaCheckbox:SetChecked(GetSetting("enableInArenas"))
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
            print("|cFF00FF00ToggleAllNameplates:|r Nameplates manually set to |cFFFF4444hidden by default|r.")
        else
            SetCVar("nameplateShowAll", 1)
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
        -- Sync checkboxes to persisted values.
        RefreshCheckboxes()
    elseif event == "PLAYER_LOGIN" then
        print("|cFF00FF00ToggleAllNameplates|r loaded! Use |cFFFFD100/tan|r to toggle manually, or |cFFFFD100/tan config|r to open settings.")
        UpdateNameplates()
    elseif event == "LOADING_SCREEN_DISABLED" then
        UpdateNameplates()
    end
end)
