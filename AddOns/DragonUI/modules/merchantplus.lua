local addon = select(2, ...)
local L = addon.L

local MerchantPlusModule = {
    initialized = false,
    applied = false,
    hooks = {},
    frames = {},
    original = {},
}

if addon.RegisterModule then
    addon:RegisterModule("merchantplus", MerchantPlusModule,
        (L and L["Merchant Enhancements"]) or "Merchant Enhancements",
        (L and L["Automatic repairs and an expanded merchant list layout."]) or "Automatic repairs and an expanded merchant list layout.", {
        lifecyclePrefix = "MerchantPlus",
        loadOnce = true,
    })
end

local DEFAULT_ITEMS_PER_PAGE = 10
local EXPANDED_ITEMS_PER_PAGE = 20
local BUYBACK_ITEMS_PER_PAGE = BUYBACK_ITEMS_PER_PAGE or 12
local REPAIR_REPORT_DELAY = 0.05
local EXPANDED_FRAME_WIDTH = 715
local TEXTURE_ROOT = "Interface\\AddOns\\DragonUI\\Textures\\MerchantPlus\\"

local layoutBusy = false

local function GetModuleConfig()
    return addon:GetModuleConfig("merchantplus")
end

local function IsModuleEnabled()
    return addon:IsModuleEnabled("merchantplus")
end

local function IsExpandedLayoutEnabled()
    local cfg = GetModuleConfig()
    return cfg and cfg.expanded_layout ~= false
end

local function FormatMoney(money)
    if type(GetCoinTextureString) == "function" then
        return GetCoinTextureString(money or 0)
    end

    return tostring(money or 0)
end

local function PrintStatus(message)
    if not message or message == "" then
        return
    end

    if addon and addon.Print then
        addon:Print(message)
    else
        print("|cFF00FF00[DragonUI]|r " .. message)
    end
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

local function CaptureTexture(texture)
    if texture and texture.GetTexture then
        return texture:GetTexture()
    end
end

local function RestoreTexture(texture, path)
    if texture and path and texture.SetTexture then
        texture:SetTexture(path)
    end
end

local function CaptureMerchantState()
    if MerchantPlusModule.original.captured or not MerchantFrame then
        return
    end

    local original = MerchantPlusModule.original
    original.captured = true
    original.frameWidth = MerchantFrame:GetWidth()
    original.itemsPerPage = _G.MERCHANT_ITEMS_PER_PAGE or DEFAULT_ITEMS_PER_PAGE
    original.mouseWheelScript = MerchantFrame:GetScript("OnMouseWheel")

    if MerchantFrame.IsMouseWheelEnabled then
        original.mouseWheelEnabled = MerchantFrame:IsMouseWheelEnabled()
    end

    original.buyBackPoint = CapturePoint(MerchantBuyBackItem)
    original.prevPoint = CapturePoint(MerchantPrevPageButton)
    original.pageTextPoint = CapturePoint(MerchantPageText)
    original.nextPoint = CapturePoint(MerchantNextPageButton)
    original.bottomLeftBorderPoint = CapturePoint(MerchantFrameBottomLeftBorder)
    original.bottomRightBorderPoint = CapturePoint(MerchantFrameBottomRightBorder)

    original.itemPoints = {}
    for i = 1, DEFAULT_ITEMS_PER_PAGE do
        original.itemPoints[i] = CapturePoint(_G["MerchantItem" .. i])
    end

    original.unnamedRegions = {}
    local regions = { MerchantFrame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.IsObjectType and region:IsObjectType("Texture") and not region:GetName() then
            table.insert(original.unnamedRegions, region)
        end
    end

    original.bottomLeftBorderTexture = CaptureTexture(MerchantFrameBottomLeftBorder)
    original.bottomRightBorderTexture = CaptureTexture(MerchantFrameBottomRightBorder)

    if MerchantFrameExtraCurrencyTex then
        original.extraCurrencyPoint = CapturePoint(MerchantFrameExtraCurrencyTex)
        original.extraCurrencyTexture = CaptureTexture(MerchantFrameExtraCurrencyTex)
    end

    original.buybackTopLeftTexture = CaptureTexture(BuybackFrameTopLeft)
    original.buybackBotLeftTexture = CaptureTexture(BuybackFrameBotLeft)
    original.buybackTopRightTexture = CaptureTexture(BuybackFrameTopRight)
    original.buybackBotRightTexture = CaptureTexture(BuybackFrameBotRight)
    original.buybackTopRightPoint = CapturePoint(BuybackFrameTopRight)
    original.buybackBotRightPoint = CapturePoint(BuybackFrameBotRight)
    original.buybackTopRightWidth = BuybackFrameTopRight and BuybackFrameTopRight:GetWidth() or nil
    original.buybackBotRightWidth = BuybackFrameBotRight and BuybackFrameBotRight:GetWidth() or nil
end

local function HideOriginalMerchantTextures()
    local original = MerchantPlusModule.original
    if not original.unnamedRegions then
        return
    end

    for _, region in ipairs(original.unnamedRegions) do
        region:Hide()
    end
end

local function ShowOriginalMerchantTextures()
    local original = MerchantPlusModule.original
    if not original.unnamedRegions then
        return
    end

    for _, region in ipairs(original.unnamedRegions) do
        region:Show()
    end
end

local function GetOrCreateManagedTexture(key, layer)
    local texture = MerchantPlusModule.frames[key]
    if texture then
        return texture
    end

    texture = MerchantFrame:CreateTexture(nil, layer or "BORDER")
    MerchantPlusModule.frames[key] = texture

    if not MerchantPlusModule.frames.managedTextures then
        MerchantPlusModule.frames.managedTextures = {}
    end
    table.insert(MerchantPlusModule.frames.managedTextures, texture)

    return texture
end

local function SetManagedTexture(key, layer, asset, width, height, point, relativeTo, relativePoint, x, y)
    local texture = GetOrCreateManagedTexture(key, layer)
    texture:SetTexture(TEXTURE_ROOT .. asset)
    texture:SetWidth(width)
    texture:SetHeight(height)
    texture:ClearAllPoints()
    texture:SetPoint(point, relativeTo, relativePoint, x, y)
    texture:Show()
    return texture
end

local function ShowManagedTextures()
    local managed = MerchantPlusModule.frames.managedTextures
    if not managed then
        return
    end

    for _, texture in ipairs(managed) do
        texture:Show()
    end
end

local function HideManagedTextures()
    local managed = MerchantPlusModule.frames.managedTextures
    if not managed then
        return
    end

    for _, texture in ipairs(managed) do
        texture:Hide()
    end
end

local function EnsureExtraMerchantItems()
    if not MerchantFrame then
        return
    end

    for i = DEFAULT_ITEMS_PER_PAGE + 1, EXPANDED_ITEMS_PER_PAGE do
        if not _G["MerchantItem" .. i] then
            CreateFrame("Frame", "MerchantItem" .. i, MerchantFrame, "MerchantItemTemplate")
        end
    end
end

local function EnsureMerchantVisuals()
    if not MerchantFrame then
        return
    end

    HideOriginalMerchantTextures()

    SetManagedTexture("bgTopLeft", "BORDER", "bg-top-left.blp", 256, 256, "TOPLEFT", MerchantFrame, "TOPLEFT", 0, 0)
    SetManagedTexture("bgTopMid", "BORDER", "bg-top-mid.blp", 256, 256, "TOPLEFT", MerchantFrame, "TOPLEFT", 256, 0)
    SetManagedTexture("bgTopRight", "BORDER", "bg-top-right.blp", 256, 256, "TOPRIGHT", MerchantFrame, "TOPRIGHT", 0, 0)
    SetManagedTexture("bgBottomLeft", "BORDER", "bg-bottom-left.blp", 256, 256, "TOPLEFT", MerchantFrame, "TOPLEFT", 0, -256)
    SetManagedTexture("bgBottomMid", "BORDER", "bg-bottom-mid.blp", 256, 256, "TOPLEFT", MerchantFrame, "TOPLEFT", 256, -256)
    SetManagedTexture("bgBottomRight", "BORDER", "bg-bottom-right.blp", 256, 256, "TOPRIGHT", MerchantFrame, "TOPRIGHT", 0, -256)

    if MerchantFrameBottomLeftBorder then
        MerchantFrameBottomLeftBorder:SetTexture(TEXTURE_ROOT .. "bottomborder.tga")
        MerchantFrameBottomLeftBorder:Show()
    end
    if MerchantFrameBottomRightBorder then
        MerchantFrameBottomRightBorder:SetTexture(TEXTURE_ROOT .. "bottomborder.tga")
        MerchantFrameBottomRightBorder:Show()
    end

    if MerchantFrameExtraCurrencyTex then
        MerchantFrameExtraCurrencyTex:ClearAllPoints()
        MerchantFrameExtraCurrencyTex:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -130, 53)
        MerchantFrameExtraCurrencyTex:SetTexture(TEXTURE_ROOT .. "botleft-currency.blp")
        MerchantFrameExtraCurrencyTex:Show()
    end

    if BuybackFrameTopLeft then
        BuybackFrameTopLeft:SetTexture(TEXTURE_ROOT .. "buyback-topleft.blp")
    end
    if BuybackFrameBotLeft then
        BuybackFrameBotLeft:SetTexture(TEXTURE_ROOT .. "buyback-bottomleft.blp")
    end

    local buybackTopMid = SetManagedTexture("buybackTopMid", "ARTWORK", "buyback-topmid.blp", 256, 256, "TOPLEFT", BuybackFrameTopLeft, "TOPRIGHT", 0, 0)
    local buybackBotMid = SetManagedTexture("buybackBotMid", "ARTWORK", "buyback-bottommid.blp", 256, 128, "TOPLEFT", BuybackFrameBotLeft, "TOPRIGHT", 0, 0)

    if BuybackFrameTopRight then
        BuybackFrameTopRight:ClearAllPoints()
        BuybackFrameTopRight:SetPoint("TOPLEFT", buybackTopMid, "TOPRIGHT", 0, 0)
        BuybackFrameTopRight:SetTexture(TEXTURE_ROOT .. "buyback-topright.blp")
        BuybackFrameTopRight:SetWidth(256)
    end

    if BuybackFrameBotRight then
        BuybackFrameBotRight:ClearAllPoints()
        BuybackFrameBotRight:SetPoint("BOTTOMLEFT", buybackBotMid, "BOTTOMRIGHT", 0, 0)
        BuybackFrameBotRight:SetTexture(TEXTURE_ROOT .. "buyback-bottomright.blp")
        BuybackFrameBotRight:SetWidth(256)
    end
end

local function ApplyMerchantTabVisuals()
    ShowManagedTextures()

    if MerchantBuyBackItem then
        MerchantBuyBackItem:Show()
    end
    if MerchantFrameBottomLeftBorder then
        MerchantFrameBottomLeftBorder:Show()
    end
    if MerchantFrameBottomRightBorder then
        MerchantFrameBottomRightBorder:Show()
    end

    if BuybackFrameTopLeft then BuybackFrameTopLeft:Hide() end
    if BuybackFrameTopRight then BuybackFrameTopRight:Hide() end
    if BuybackFrameBotLeft then BuybackFrameBotLeft:Hide() end
    if BuybackFrameBotRight then BuybackFrameBotRight:Hide() end
    if MerchantPlusModule.frames.buybackTopMid then MerchantPlusModule.frames.buybackTopMid:Hide() end
    if MerchantPlusModule.frames.buybackBotMid then MerchantPlusModule.frames.buybackBotMid:Hide() end
end

local function ApplyBuybackTabVisuals()
    ShowManagedTextures()

    if MerchantBuyBackItem then
        MerchantBuyBackItem:Hide()
    end
    if MerchantFrameBottomLeftBorder then
        MerchantFrameBottomLeftBorder:Hide()
    end
    if MerchantFrameBottomRightBorder then
        MerchantFrameBottomRightBorder:Hide()
    end

    if BuybackFrameTopLeft then BuybackFrameTopLeft:Show() end
    if BuybackFrameTopRight then BuybackFrameTopRight:Show() end
    if BuybackFrameBotLeft then BuybackFrameBotLeft:Show() end
    if BuybackFrameBotRight then BuybackFrameBotRight:Show() end
    if MerchantPlusModule.frames.buybackTopMid then MerchantPlusModule.frames.buybackTopMid:Show() end
    if MerchantPlusModule.frames.buybackBotMid then MerchantPlusModule.frames.buybackBotMid:Show() end
end

local function LayoutMerchantItems()
    for i = 1, EXPANDED_ITEMS_PER_PAGE do
        local button = _G["MerchantItem" .. i]
        if button then
            button:ClearAllPoints()

            if i == 1 then
                button:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 24, -80)
            elseif ((i - 1) % DEFAULT_ITEMS_PER_PAGE) == 0 then
                button:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - (DEFAULT_ITEMS_PER_PAGE - 1))], "TOPRIGHT", 12, 0)
            elseif (i % 2) == 1 then
                button:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 2)], "BOTTOMLEFT", 0, -16)
            else
                button:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 1)], "TOPRIGHT", 12, 0)
            end

            button:Show()
        end
    end

    if MerchantBuyBackItem then
        MerchantBuyBackItem:ClearAllPoints()
        MerchantBuyBackItem:SetPoint("TOPLEFT", MerchantItem10, "BOTTOMLEFT", 0, -20)
    end

    if MerchantPrevPageButton then
        MerchantPrevPageButton:ClearAllPoints()
        MerchantPrevPageButton:SetPoint("CENTER", MerchantFrame, "BOTTOM", 20, 115)
    end

    if MerchantPageText then
        MerchantPageText:ClearAllPoints()
        MerchantPageText:SetPoint("BOTTOM", MerchantFrame, "BOTTOM", 150, 110)
    end

    if MerchantNextPageButton then
        MerchantNextPageButton:ClearAllPoints()
        MerchantNextPageButton:SetPoint("CENTER", MerchantFrame, "BOTTOM", 280, 115)
    end
end

local function LayoutBuybackItems()
    for i = 1, EXPANDED_ITEMS_PER_PAGE do
        local button = _G["MerchantItem" .. i]
        if button then
            button:ClearAllPoints()

            if i > BUYBACK_ITEMS_PER_PAGE then
                button:Hide()
            else
                if i == 1 then
                    button:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 64, -120)
                elseif (i % 3) == 1 then
                    button:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 3)], "BOTTOMLEFT", 0, -30)
                else
                    button:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 1)], "TOPRIGHT", 50, 0)
                end

                button:Show()
            end
        end
    end

    if MerchantPrevPageButton then
        MerchantPrevPageButton:ClearAllPoints()
        MerchantPrevPageButton:SetPoint("CENTER", MerchantFrame, "BOTTOM", 20, 115)
    end

    if MerchantPageText then
        MerchantPageText:ClearAllPoints()
        MerchantPageText:SetPoint("BOTTOM", MerchantFrame, "BOTTOM", 150, 110)
    end

    if MerchantNextPageButton then
        MerchantNextPageButton:ClearAllPoints()
        MerchantNextPageButton:SetPoint("CENTER", MerchantFrame, "BOTTOM", 280, 115)
    end
end

local function HandleMerchantMouseWheel(_, delta)
    if not MerchantFrame or not MerchantFrame:IsShown() then
        return
    end

    if delta < 0 then
        if MerchantNextPageButton and MerchantNextPageButton:IsShown() and MerchantNextPageButton:IsEnabled() then
            MerchantNextPageButton:Click()
        end
    elseif delta > 0 then
        if MerchantPrevPageButton and MerchantPrevPageButton:IsShown() and MerchantPrevPageButton:IsEnabled() then
            MerchantPrevPageButton:Click()
        end
    end
end

local function RefreshMerchantFrame()
    if MerchantFrame and MerchantFrame:IsShown() and type(MerchantFrame_Update) == "function" then
        MerchantFrame_Update()
    end
end

local function UpdateExpandedLayout(skipRefresh)
    if layoutBusy or not MerchantFrame or not IsModuleEnabled() or not IsExpandedLayoutEnabled() then
        return
    end

    layoutBusy = true

    CaptureMerchantState()
    EnsureExtraMerchantItems()
    EnsureMerchantVisuals()

    _G.MERCHANT_ITEMS_PER_PAGE = EXPANDED_ITEMS_PER_PAGE
    MerchantFrame:SetWidth(EXPANDED_FRAME_WIDTH)

    if MerchantFrame.EnableMouseWheel then
        MerchantFrame:EnableMouseWheel(true)
    end
    MerchantFrame:SetScript("OnMouseWheel", HandleMerchantMouseWheel)

    if MerchantFrame.selectedTab == 2 then
        LayoutBuybackItems()
        ApplyBuybackTabVisuals()
    else
        LayoutMerchantItems()
        ApplyMerchantTabVisuals()
    end

    MerchantPlusModule.applied = true
    MerchantPlusModule.initialized = true

    layoutBusy = false

    if not skipRefresh then
        RefreshMerchantFrame()
    end
end

local function EnsureMerchantHooks()
    if MerchantPlusModule.hooks.frameUpdate or not MerchantFrame_Update then
        return
    end

    hooksecurefunc("MerchantFrame_Update", function()
        if not MerchantFrame or not MerchantFrame:IsShown() then
            return
        end
        if not IsModuleEnabled() or not IsExpandedLayoutEnabled() then
            return
        end
        UpdateExpandedLayout(true)
    end)

    MerchantPlusModule.hooks.frameUpdate = true
end

local function ReportRepairResult(startCost, usedGuildBank)
    local remaining = GetRepairAllCost()
    if not remaining then
        remaining = 0
    end

    if remaining < startCost then
        local repaired = startCost - remaining
        if repaired > 0 then
            if usedGuildBank then
                PrintStatus(string.format((L and L["Auto-repaired using guild bank funds for %s."]) or "Auto-repaired using guild bank funds for %s.", FormatMoney(repaired)))
            else
                PrintStatus(string.format((L and L["Auto-repaired for %s."]) or "Auto-repaired for %s.", FormatMoney(repaired)))
            end
        end
    end

    if remaining > 0 then
        if usedGuildBank then
            if GetMoney() >= remaining then
                RepairAllItems()
                addon:After(REPAIR_REPORT_DELAY, function()
                    ReportRepairResult(remaining, false)
                end)
            else
                PrintStatus((L and L["Not enough money to repair equipment."]) or "Not enough money to repair equipment.")
            end
        elseif remaining >= startCost then
            PrintStatus((L and L["Not enough money to repair equipment."]) or "Not enough money to repair equipment.")
        end
    end
end

local function PerformAutoRepair()
    local cfg = GetModuleConfig()
    if not IsModuleEnabled() or not cfg or cfg.auto_repair == false then
        return
    end

    if not CanMerchantRepair or not CanMerchantRepair() then
        return
    end

    local repairCost = GetRepairAllCost()
    if not repairCost or repairCost <= 0 then
        return
    end

    if cfg.use_guild_bank ~= false and CanGuildBankRepair and CanGuildBankRepair() then
        RepairAllItems(1)
        addon:After(REPAIR_REPORT_DELAY, function()
            ReportRepairResult(repairCost, true)
        end)
        return
    end

    if GetMoney() < repairCost then
        PrintStatus((L and L["Not enough money to repair equipment."]) or "Not enough money to repair equipment.")
        return
    end

    RepairAllItems()
    addon:After(REPAIR_REPORT_DELAY, function()
        ReportRepairResult(repairCost, false)
    end)
end

function addon.ApplyMerchantPlusSystem()
    EnsureMerchantHooks()
    UpdateExpandedLayout(false)
end

function addon.RestoreMerchantPlusSystem()
    if not MerchantFrame or not MerchantPlusModule.original.captured then
        return
    end

    local original = MerchantPlusModule.original

    _G.MERCHANT_ITEMS_PER_PAGE = original.itemsPerPage or DEFAULT_ITEMS_PER_PAGE
    MerchantFrame:SetWidth(original.frameWidth or MerchantFrame:GetWidth())

    for i = 1, DEFAULT_ITEMS_PER_PAGE do
        RestorePoint(_G["MerchantItem" .. i], original.itemPoints and original.itemPoints[i] or nil)
    end

    for i = DEFAULT_ITEMS_PER_PAGE + 1, EXPANDED_ITEMS_PER_PAGE do
        local button = _G["MerchantItem" .. i]
        if button then
            button:Hide()
        end
    end

    RestorePoint(MerchantBuyBackItem, original.buyBackPoint)
    RestorePoint(MerchantPrevPageButton, original.prevPoint)
    RestorePoint(MerchantPageText, original.pageTextPoint)
    RestorePoint(MerchantNextPageButton, original.nextPoint)
    RestorePoint(MerchantFrameBottomLeftBorder, original.bottomLeftBorderPoint)
    RestorePoint(MerchantFrameBottomRightBorder, original.bottomRightBorderPoint)
    RestorePoint(BuybackFrameTopRight, original.buybackTopRightPoint)
    RestorePoint(BuybackFrameBotRight, original.buybackBotRightPoint)

    if BuybackFrameTopRight and original.buybackTopRightWidth then
        BuybackFrameTopRight:SetWidth(original.buybackTopRightWidth)
    end
    if BuybackFrameBotRight and original.buybackBotRightWidth then
        BuybackFrameBotRight:SetWidth(original.buybackBotRightWidth)
    end

    RestoreTexture(MerchantFrameBottomLeftBorder, original.bottomLeftBorderTexture)
    RestoreTexture(MerchantFrameBottomRightBorder, original.bottomRightBorderTexture)
    RestoreTexture(BuybackFrameTopLeft, original.buybackTopLeftTexture)
    RestoreTexture(BuybackFrameBotLeft, original.buybackBotLeftTexture)
    RestoreTexture(BuybackFrameTopRight, original.buybackTopRightTexture)
    RestoreTexture(BuybackFrameBotRight, original.buybackBotRightTexture)

    if MerchantFrameExtraCurrencyTex then
        RestorePoint(MerchantFrameExtraCurrencyTex, original.extraCurrencyPoint)
        RestoreTexture(MerchantFrameExtraCurrencyTex, original.extraCurrencyTexture)
    end

    HideManagedTextures()
    ShowOriginalMerchantTextures()

    if MerchantFrameBottomLeftBorder then MerchantFrameBottomLeftBorder:Show() end
    if MerchantFrameBottomRightBorder then MerchantFrameBottomRightBorder:Show() end
    if BuybackFrameTopLeft then BuybackFrameTopLeft:Show() end
    if BuybackFrameTopRight then BuybackFrameTopRight:Show() end
    if BuybackFrameBotLeft then BuybackFrameBotLeft:Show() end
    if BuybackFrameBotRight then BuybackFrameBotRight:Show() end

    if MerchantFrame.EnableMouseWheel then
        MerchantFrame:EnableMouseWheel(original.mouseWheelEnabled and true or false)
    end
    MerchantFrame:SetScript("OnMouseWheel", original.mouseWheelScript)

    MerchantPlusModule.applied = false

    RefreshMerchantFrame()
end

function addon.RefreshMerchantPlusSystem()
    if not IsModuleEnabled() then
        addon.RestoreMerchantPlusSystem()
        return
    end

    EnsureMerchantHooks()

    if IsExpandedLayoutEnabled() then
        addon.ApplyMerchantPlusSystem()
    else
        addon.RestoreMerchantPlusSystem()
    end
end

local function OnProfileChanged()
    addon.RefreshMerchantPlusSystem()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("MERCHANT_SHOW")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "DragonUI" then
        addon:After(0.5, function()
            if addon.db and addon.db.RegisterCallback then
                addon.db.RegisterCallback(addon, "OnProfileChanged", OnProfileChanged)
                addon.db.RegisterCallback(addon, "OnProfileCopied", OnProfileChanged)
                addon.db.RegisterCallback(addon, "OnProfileReset", OnProfileChanged)
            end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        EnsureMerchantHooks()
    elseif event == "MERCHANT_SHOW" then
        if not IsModuleEnabled() then
            return
        end

        EnsureMerchantHooks()

        if IsExpandedLayoutEnabled() then
            addon.ApplyMerchantPlusSystem()
        end

        PerformAutoRepair()
    end
end)
