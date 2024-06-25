-- Initialize the saved variables
ActionBarProfilesDB = ActionBarProfilesDB or {}
local profilesInMemory = {}

-- Create the main frame
local frame = CreateFrame("Frame", "ActionBarProfilesFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(300, 200)
frame:SetPoint("CENTER")

-- Title
frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFontObject("GameFontHighlight")
frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
frame.title:SetText("ActionBar Profiles")

-- Input box for profile name
local inputBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
inputBox:SetSize(140, 30)
inputBox:SetPoint("TOP", frame, "TOP", 0, -40)
inputBox:SetAutoFocus(false)

-- Function to scan the spellbook and return a list of spells
local function getSpellsFromSpellbook()
    local spells = {}
    for i = 1, GetNumSpellTabs() do
        local name, texture, offset, numSpells = GetSpellTabInfo(i)
        for j = 1, numSpells do
            local spellIndex = offset + j
            local spellName, spellSubName = GetSpellBookItemName(spellIndex, BOOKTYPE_SPELL)
            local spellType, spellID = GetSpellBookItemInfo(spellIndex, BOOKTYPE_SPELL)
            if spellType == "SPELL" then
                table.insert(spells, spellID)
            end
        end
    end
    return spells
end

-- Function to clear all action bar slots
local function clearActionBars()
    for i = 1, 120 do
        PickupAction(i)
        ClearCursor()
    end
end

-- Save button
local saveButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
saveButton:SetSize(100, 30)
saveButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -80)
saveButton:SetText("Save Profile")
saveButton:SetScript("OnClick", function()
    local profileName = inputBox:GetText()
    if profileName ~= "" then
        local spells = {}
        for i = 1, 120 do
            local type, id, subType = GetActionInfo(i)
            if type then
                table.insert(spells, {type = type, id = id, subType = subType, slot = i})
            end
        end
        profilesInMemory[profileName] = spells
        ActionBarProfilesDB[profileName] = spells
        print("Profile saved: " .. profileName)
    end
end)

-- Load button
local loadButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
loadButton:SetSize(100, 30)
loadButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -80)
loadButton:SetText("Load Profile")
loadButton:SetScript("OnClick", function()
    local profileName = inputBox:GetText()
    if profileName ~= "" and profilesInMemory[profileName] then
        local spells = profilesInMemory[profileName]
        print("Profile loaded: " .. profileName)
        
        -- Clear all action bar slots first
        clearActionBars()
        
        -- Attempt to place the spells on the action bar
        for _, spell in ipairs(spells) do
            if spell.type == "spell" then
                PickupSpell(spell.id)
            elseif spell.type == "item" then
                PickupItem(spell.id)
            elseif spell.type == "macro" then
                PickupMacro(spell.id)
            elseif spell.type == "companion" then
                PickupCompanion(spell.subType, spell.id)
            end
            PlaceAction(spell.slot)
            ClearCursor()
        end
        ClearCursor()
    end
end)

-- Function to save the profiles when the player logs out
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGOUT" then
        for profileName, spells in pairs(profilesInMemory) do
            ActionBarProfilesDB[profileName] = spells
        end
    end
end)

-- Slash command to show the frame
SLASH_ACTIONBARPROFILES1 = "/abprofiles"
SlashCmdList["ACTIONBARPROFILES"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
