local addon = select(2, ...)
local L = addon.L

local QuickLootModule = {
    initialized = false,
    applied = false,
    hooks = {},
    state = {},
    original = {},
}
addon.QuickLootModule = QuickLootModule

if addon.RegisterModule then
    addon:RegisterModule("quickloot", QuickLootModule,
        (L and L["Quick Loot"]) or "Quick Loot",
        (L and L["Move the loot window to your cursor and optionally hide it when there is nothing to loot."]) or "Move the loot window to your cursor and optionally hide it when there is nothing to loot.", {
        lifecyclePrefix = "QuickLoot",
    })
end

local DEFAULT_FALLBACK_POINT = {
    point = "TOPLEFT",
    relativeTo = "UIParent",
    relativePoint = "TOPLEFT",
    x = 384,
    y = -104,
}

local function GetModuleConfig()
    return addon:GetModuleConfig("quickloot")
end

local function IsModuleEnabled()
    return addon:IsModuleEnabled("quickloot")
end

local function IsAutoHideEnabled()
    local cfg = GetModuleConfig()
    return cfg and cfg.auto_hide == true
end

local function GetRelativeFrameName(frame)
    if not frame or frame == UIParent then
        return "UIParent"
    end

    if frame.GetName then
        return frame:GetName()
    end
end

local function CapturePoint(frame)
    if not frame then
        return nil
    end

    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    if not point then
        return nil
    end

    if not relativeTo and frame.GetParent then
        relativeTo = frame:GetParent()
    end

    return {
        point = point,
        relativeTo = GetRelativeFrameName(relativeTo),
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
end

local function RestorePoint(frame, saved)
    if not frame or not saved then
        return
    end

    local relativeTo = UIParent
    if saved.relativeTo and saved.relativeTo ~= "UIParent" and _G[saved.relativeTo] then
        relativeTo = _G[saved.relativeTo]
    end

    frame:ClearAllPoints()
    frame:SetPoint(saved.point or "CENTER", relativeTo, saved.relativePoint or saved.point or "CENTER", saved.x or 0, saved.y or 0)
end

local function GetFallbackPoint()
    return QuickLootModule.original.lootFramePoint or DEFAULT_FALLBACK_POINT
end

local function CaptureOriginalState()
    if QuickLootModule.original.captured or not LootFrame then
        return
    end

    QuickLootModule.original.lootFramePoint = CapturePoint(LootFrame)
    QuickLootModule.original.captured = true
end

local function PositionLootFrame()
    if not LootFrame or not LootFrame:IsShown() then
        return
    end

    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetScale()
    if not cursorX or not cursorY or not scale or scale == 0 then
        RestorePoint(LootFrame, GetFallbackPoint())
        return
    end

    cursorX = cursorX / scale
    cursorY = cursorY / scale

    local startIndex
    if QuickLootModule.state.firstClickedButton == nil then
        startIndex = 1
    else
        startIndex = QuickLootModule.state.firstClickedButton + 1
    end

    for i = startIndex, LOOTFRAME_NUMBUTTONS do
        local button = _G["LootButton" .. i]
        if button and button:IsVisible() then
            cursorX = cursorX - 42
            cursorY = cursorY + 56 + (40 * i)

            if (cursorX + 185) > UIParent:GetRight() or (cursorY - 256) < 55 then
                RestorePoint(LootFrame, GetFallbackPoint())
            else
                LootFrame:ClearAllPoints()
                LootFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cursorX, cursorY)
            end
            return
        end
    end

    if LootFrameDownButton and LootFrameDownButton:IsVisible() then
        cursorX = cursorX - 158
        cursorY = cursorY + 223
        QuickLootModule.state.firstClickedButton = nil
    else
        cursorX = cursorX - 173
        cursorY = cursorY + 25
    end

    if (cursorX + 185) > UIParent:GetRight() or (cursorY - 256) < 55 then
        RestorePoint(LootFrame, GetFallbackPoint())
    else
        LootFrame:ClearAllPoints()
        LootFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cursorX, cursorY)
    end
end

local function HandleLootEvent(event)
    if not IsModuleEnabled() then
        return
    end

    if event == "LOOT_OPENED" then
        QuickLootModule.state.firstClickedButton = nil
    end

    if event == "LOOT_OPENED" or event == "LOOT_SLOT_CLEARED" then
        PositionLootFrame()
    end

    if event == "LOOT_OPENED" and IsAutoHideEnabled() and GetNumLootItems and GetNumLootItems() == 0 then
        HideUIPanel(LootFrame)
    end
end

local function TrackLootButton(button)
    if not IsModuleEnabled() or QuickLootModule.state.firstClickedButton ~= nil then
        return
    end

    if button and button.GetID then
        QuickLootModule.state.firstClickedButton = button:GetID()
    end
end

local function EnsureHooks()
    if QuickLootModule.hooks.installed or not LootFrame then
        return
    end

    CaptureOriginalState()

    LootFrame:HookScript("OnEvent", function(_, event)
        HandleLootEvent(event)
    end)

    hooksecurefunc("LootButton_OnClick", function(button)
        TrackLootButton(button)
    end)

    QuickLootModule.hooks.installed = true
end

function addon.ApplyQuickLootSystem()
    EnsureHooks()
    CaptureOriginalState()

    QuickLootModule.initialized = true
    QuickLootModule.applied = true

    if LootFrame and LootFrame:IsShown() then
        PositionLootFrame()
    end
end

function addon.RestoreQuickLootSystem()
    QuickLootModule.applied = false
    QuickLootModule.state.firstClickedButton = nil

    if LootFrame then
        RestorePoint(LootFrame, GetFallbackPoint())
    end
end

function addon.RefreshQuickLootSystem()
    EnsureHooks()

    if IsModuleEnabled() then
        addon.ApplyQuickLootSystem()
    else
        addon.RestoreQuickLootSystem()
    end
end
