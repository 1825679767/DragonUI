---@class WorldMapButton
---@field Initialize function
local WorldMapButton = QuestieLoader:CreateModule("WorldMapButton")

---@type l10n
local l10n = QuestieLoader:ImportModule("l10n")
---@type QuestieLib
local QuestieLib = QuestieLoader:ImportModule("QuestieLib")
---@type QuestieQuest
local QuestieQuest = QuestieLoader:ImportModule("QuestieQuest")
---@type QuestieMenu
local QuestieMenu = QuestieLoader:ImportModule("QuestieMenu")

local KButtons = QuestieCompat.KButtons or LibStub("Krowi_WorldMapButtons-1.4")

local mapButton

function WorldMapButton.Initialize()
    -- The 3.3.5 fork keeps the XML template disabled in the TOC because the
    -- modern widget template syntax is not available on this client.
    if not (KButtons and KButtons.Add and _G.QuestieWorldMapButtonTemplate) then
        return
    end

    local ok, button = pcall(KButtons.Add, KButtons, "QuestieWorldMapButtonTemplate", "BUTTON")
    if not ok then
        return
    end

    mapButton = button

    Questie.WorldMap = {
        Button = mapButton
    }
end

---@param shouldShow boolean
function WorldMapButton.Toggle(shouldShow)
    if not mapButton then
        return
    end

    if shouldShow then
        mapButton:Show()
    else
        mapButton:Hide()
    end
end

QuestieWorldMapButtonMixin = {
    OnLoad = function() end,
    OnHide = function() end,
    OnMouseDown = function(_, button)
        if button == "LeftButton" then
            Questie.db.profile.enabled = (not Questie.db.profile.enabled)
            QuestieQuest:ToggleNotes(Questie.db.profile.enabled)
        elseif button == "RightButton" then
            QuestieMenu:Show()
        end
    end,
    OnMouseUp = function() end,
    OnEnter = function(self)
        local GameTooltip = QuestieCompat.SetupTooltip(self)
        GameTooltip:SetOwner(self, "ANCHOR_NONE");
        GameTooltip:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 0);
        GameTooltip:AddLine("Questie ".. QuestieLib:GetAddonVersionString(), 1, 1, 1)
        GameTooltip:AddLine(Questie:Colorize(l10n('Left Click') , 'gray') .. ": ".. l10n('Toggle Questie'))
        GameTooltip:AddLine(Questie:Colorize(l10n('Right Click') , 'gray') .. ": ".. l10n('Toggle Menu'))
        GameTooltip:Show()
    end,
    OnLeave = function() end,
    OnClick = function() end, -- Only fires on left click
    Refresh = function() end,
}
