--[[
================================================================================
DragonUI Options Panel - Main Frame
================================================================================
Custom dark-themed options panel. Built with raw frames, not AceGUI containers.
Individual controls still use AceGUI widgets (skinned by controls.lua).
================================================================================
]]

local addon = DragonUI
if not addon then return end

local L = addon.L
local LO = addon.LO

local AceGUI = LibStub("AceGUI-3.0")

-- ============================================================================
-- PANEL MODULE
-- ============================================================================

local Panel = {}
addon.OptionsPanel = Panel

Panel.frame      = nil    -- raw Frame
Panel.tabs       = {}     -- { key = { text, builder, order } }
Panel.tabOrder   = {}     -- ordered keys
Panel.tabButtons = {}     -- visual tab buttons
Panel.mainSectionButtons = {}
Panel.currentTab = nil
Panel.currentMainSection = "ui"
Panel.scrollWidget = nil  -- current AceGUI ScrollFrame inside content

-- ============================================================================
-- THEME
-- ============================================================================

local T = {
    bg        = { 0.06, 0.06, 0.08, 0.96 },
    border    = { 0.20, 0.20, 0.22, 1 },
    titleBg   = { 0.08, 0.08, 0.10, 1 },
    tabNormal = { 0.12, 0.12, 0.14, 1 },
    tabHover  = { 0.20, 0.20, 0.24, 1 },
    tabActive = { 0.09, 0.52, 0.82, 1 },
    accent    = { 0.09, 0.52, 0.82, 1 },
    textWhite = { 1, 1, 1, 1 },
    textDim   = { 0.55, 0.55, 0.55, 1 },
    contentBg = { 0.09, 0.09, 0.11, 1 },
    font      = (addon.Fonts and addon.Fonts.NARROW) or "Interface\\AddOns\\DragonUI_Options\\fonts\\PTSansNarrow.ttf",
}

-- ============================================================================
-- BACKDROP TEMPLATES (3.3.5a)
-- ============================================================================

local BD_MAIN = {
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = false, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

local BD_INNER = {
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = false, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

-- Ensure FontStrings always get a valid font even if locale/custom font paths fail.
local function SetSafeFont(fs, size, flags)
    if not fs then return end

    local tryFonts = {
        T.font,
        addon.Fonts and addon.Fonts.PRIMARY,
        STANDARD_TEXT_FONT,
        "Fonts\\FRIZQT__.TTF",
    }

    local ok = false
    for _, fontPath in ipairs(tryFonts) do
        if fontPath and fs:SetFont(fontPath, size or 12, flags or "") then
            ok = true
            break
        end
    end

    if not ok then
        fs:SetFontObject(GameFontNormal)
    end
end

local function ReleaseScrollWidget()
    if Panel.customContentFrame then
        Panel.customContentFrame:Hide()
        Panel.customContentFrame:SetParent(nil)
        Panel.customContentFrame = nil
    end

    if Panel.scrollWidget then
        Panel.scrollWidget:ReleaseChildren()
        AceGUI:Release(Panel.scrollWidget)
        Panel.scrollWidget = nil
    end
end

-- ============================================================================
-- TAB REGISTRATION
-- ============================================================================

function Panel:RegisterTab(key, text, builder, order)
    self.tabs[key] = {
        text    = text,
        value   = key,
        builder = builder,
        order   = order or 999,
    }
    self.tabOrder = {}
    for k in pairs(self.tabs) do
        table.insert(self.tabOrder, k)
    end
    table.sort(self.tabOrder, function(a, b)
        return (self.tabs[a].order or 999) < (self.tabs[b].order or 999)
    end)
end

-- ============================================================================
-- CREATE FRAME
-- ============================================================================

local function CreatePanel()
    -- Main frame
    local f = CreateFrame("Frame", "DragonUIOptionsPanel", UIParent)
    f:SetFrameStrata("DIALOG")
    f:SetWidth(920)
    f:SetHeight(650)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetBackdrop(BD_MAIN)
    f:SetBackdropColor(unpack(T.bg))
    f:SetBackdropBorderColor(unpack(T.border))

    -- Drag
    f:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then self:StartMoving() end
    end)
    f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

    -- Resize support
    f:SetResizable(true)
    f:SetMinResize(700, 450)
    f:SetMaxResize(1400, 900)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(32)
    titleBar:SetBackdrop(BD_INNER)
    titleBar:SetBackdropColor(unpack(T.titleBg))
    titleBar:SetBackdropBorderColor(0, 0, 0, 0)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    SetSafeFont(titleText, 15, "OUTLINE")
    titleText:SetPoint("LEFT", 12, 0)
    titleText:SetText("|cff1784d1" .. LO["DragonUI"] .. "|r |cffaaaaaa2.5|r")

    -- Editor Mode button (in title bar) - styled pill button with neon green border
    local editorBtn = CreateFrame("Button", nil, titleBar)
    editorBtn:SetSize(104, 22)
    editorBtn:SetPoint("RIGHT", titleBar, "RIGHT", -36, 0)
    editorBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    editorBtn:SetBackdropColor(0.05, 0.12, 0.05, 1)
    editorBtn:SetBackdropBorderColor(0.0, 0.9, 0.0, 0.7)
    local editorText = editorBtn:CreateFontString(nil, "OVERLAY")
    SetSafeFont(editorText, 11, "")
    editorText:SetPoint("CENTER", 0, 0)
    editorText:SetText("|cff00dd00" .. LO["Editor Mode"] .. "|r")
    editorBtn:SetScript("OnClick", function()
        Panel:Close()
        if addon.EditorMode then addon.EditorMode:Toggle() end
    end)
    editorBtn:SetScript("OnEnter", function()
        editorBtn:SetBackdropColor(0.0, 0.9, 0.0, 0.25)
        editorBtn:SetBackdropBorderColor(0.0, 1.0, 0.0, 1.0)
        editorText:SetText("|cff00ff00" .. LO["Editor Mode"] .. "|r")
    end)
    editorBtn:SetScript("OnLeave", function()
        editorBtn:SetBackdropColor(0.05, 0.12, 0.05, 1)
        editorBtn:SetBackdropBorderColor(0.0, 0.9, 0.0, 0.7)
        editorText:SetText("|cff00dd00" .. LO["Editor Mode"] .. "|r")
    end)

    -- KeyBind Mode button (in title bar) - styled pill button with neon green border
    local keybindBtn = CreateFrame("Button", nil, titleBar)
    keybindBtn:SetSize(104, 22)
    keybindBtn:SetPoint("RIGHT", editorBtn, "LEFT", -6, 0)
    keybindBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    keybindBtn:SetBackdropColor(0.05, 0.12, 0.05, 1)
    keybindBtn:SetBackdropBorderColor(0.0, 0.9, 0.0, 0.7)
    local keybindText = keybindBtn:CreateFontString(nil, "OVERLAY")
    SetSafeFont(keybindText, 11, "")
    keybindText:SetPoint("CENTER", 0, 0)
    keybindText:SetText("|cff00dd00" .. LO["KeyBind Mode"] .. "|r")
    keybindBtn:SetScript("OnClick", function()
        Panel:Close()
        if addon.KeyBindingModule and LibStub and LibStub("LibKeyBound-1.0", true) then
            LibStub("LibKeyBound-1.0"):Toggle()
        end
    end)
    keybindBtn:SetScript("OnEnter", function()
        keybindBtn:SetBackdropColor(0.0, 0.9, 0.0, 0.25)
        keybindBtn:SetBackdropBorderColor(0.0, 1.0, 0.0, 1.0)
        keybindText:SetText("|cff00ff00" .. LO["KeyBind Mode"] .. "|r")
    end)
    keybindBtn:SetScript("OnLeave", function()
        keybindBtn:SetBackdropColor(0.05, 0.12, 0.05, 1)
        keybindBtn:SetBackdropBorderColor(0.0, 0.9, 0.0, 0.7)
        keybindText:SetText("|cff00dd00" .. LO["KeyBind Mode"] .. "|r")
    end)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", -8, 0)
    closeBtn:SetNormalFontObject(GameFontNormal)

    local closeTex = closeBtn:CreateFontString(nil, "OVERLAY")
    SetSafeFont(closeTex, 16, "OUTLINE")
    closeTex:SetPoint("CENTER", 0, 0)
    closeTex:SetText("|cffccccccx|r")
    closeBtn:SetScript("OnClick", function() Panel:Close() end)
    closeBtn:SetScript("OnEnter", function() closeTex:SetText("|cffff4444x|r") end)
    closeBtn:SetScript("OnLeave", function() closeTex:SetText("|cffccccccx|r") end)

    -- Accent line under title bar
    local accent = f:CreateTexture(nil, "OVERLAY")
    accent:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    accent:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
    accent:SetHeight(2)
    accent:SetVertexColor(unpack(T.accent))

    -- Main section bar (top-level tabs)
    local sectionBar = CreateFrame("Frame", nil, f)
    sectionBar:SetPoint("TOPLEFT", accent, "BOTTOMLEFT", 0, 0)
    sectionBar:SetPoint("TOPRIGHT", accent, "BOTTOMRIGHT", 0, 0)
    sectionBar:SetHeight(32)
    sectionBar:SetBackdrop(BD_INNER)
    sectionBar:SetBackdropColor(0.07, 0.07, 0.09, 1)
    sectionBar:SetBackdropBorderColor(0, 0, 0, 0)
    f.sectionBar = sectionBar

    local sectionBarAccent = f:CreateTexture(nil, "OVERLAY")
    sectionBarAccent:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    sectionBarAccent:SetPoint("TOPLEFT", sectionBar, "BOTTOMLEFT", 0, 0)
    sectionBarAccent:SetPoint("TOPRIGHT", sectionBar, "BOTTOMRIGHT", 0, 0)
    sectionBarAccent:SetHeight(1)
    sectionBarAccent:SetVertexColor(unpack(T.border))
    f.sectionBarAccent = sectionBarAccent

    -- Tab strip (left side vertical)
    local tabStrip = CreateFrame("Frame", nil, f)
    tabStrip:SetPoint("TOPLEFT", sectionBar, "BOTTOMLEFT", 1, -1)
    tabStrip:SetPoint("BOTTOMLEFT", 1, 1)
    tabStrip:SetWidth(140)
    tabStrip:SetBackdrop(BD_INNER)
    tabStrip:SetBackdropColor(0.07, 0.07, 0.09, 1)
    tabStrip:SetBackdropBorderColor(0, 0, 0, 0)
    f.tabStrip = tabStrip

    -- Separator line between tabs and content
    local sep = f:CreateTexture(nil, "OVERLAY")
    sep:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    sep:SetPoint("TOPLEFT", tabStrip, "TOPRIGHT", 0, 0)
    sep:SetPoint("BOTTOMLEFT", tabStrip, "BOTTOMRIGHT", 0, 0)
    sep:SetWidth(1)
    sep:SetVertexColor(unpack(T.border))
    f.tabSeparator = sep

    -- Content area
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", tabStrip, "TOPRIGHT", 1, 0)
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    content:SetBackdrop(BD_INNER)
    content:SetBackdropColor(unpack(T.contentBg))
    content:SetBackdropBorderColor(0, 0, 0, 0)
    f.content = content

    -- Status bar at bottom
    local statusText = f:CreateFontString(nil, "OVERLAY")
    SetSafeFont(statusText, 11, "")
    statusText:SetPoint("BOTTOM", f, "BOTTOM", 0, 4)
    statusText:SetTextColor(0.4, 0.4, 0.4, 1)
    statusText:SetText(LO["Commands: /dragonui, /dui, /pi — /dragonui edit (editor) — /dragonui help"])

    -- Resize grip (bottom-right corner)
    local resizeGrip = CreateFrame("Frame", nil, f)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
    resizeGrip:EnableMouse(true)
    resizeGrip:SetFrameLevel(f:GetFrameLevel() + 10)

    local gripTex = resizeGrip:CreateTexture(nil, "OVERLAY")
    gripTex:SetAllPoints()
    gripTex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    gripTex:SetVertexColor(0.4, 0.4, 0.4, 0.5)

    -- Draw diagonal grip lines
    for i = 1, 3 do
        local line = resizeGrip:CreateTexture(nil, "OVERLAY")
        line:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        line:SetVertexColor(0.6, 0.6, 0.6, 0.8)
        line:SetSize(i * 4, 1)
        line:SetPoint("BOTTOMRIGHT", resizeGrip, "BOTTOMRIGHT", -1, i * 4)
    end

    resizeGrip:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then
            f:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeGrip:SetScript("OnMouseUp", function(self)
        f:StopMovingOrSizing()
        -- Update scroll content width to match new panel size
        if Panel.scrollWidget then
            Panel.scrollWidget.content:SetWidth(f.content:GetWidth() - 32)
            Panel.scrollWidget:DoLayout()
        end
        if Panel.customContentFrame and Panel.customContentFrame.RefreshLayout then
            Panel.customContentFrame:RefreshLayout()
        end
    end)
    resizeGrip:SetScript("OnEnter", function()
        gripTex:SetVertexColor(0.6, 0.6, 0.6, 0.8)
    end)
    resizeGrip:SetScript("OnLeave", function()
        gripTex:SetVertexColor(0.4, 0.4, 0.4, 0.5)
    end)

    f:SetScript("OnSizeChanged", function(self, w, h)
        -- Live-update scroll content width during resize
        if Panel.scrollWidget then
            Panel.scrollWidget.content:SetWidth(self.content:GetWidth() - 32)
            Panel.scrollWidget:DoLayout()
        end
        if Panel.customContentFrame and Panel.customContentFrame.RefreshLayout then
            Panel.customContentFrame:RefreshLayout()
        end
    end)

    -- ESC to close
    tinsert(UISpecialFrames, "DragonUIOptionsPanel")

    return f
end

function Panel:RestoreFramePriority()
    if not self.frame then
        return
    end

    self.frame:SetFrameStrata("DIALOG")
    self.frame:SetFrameLevel(100)
end

function Panel:SendBehindExternalConfig()
    if not self.frame then
        return
    end

    self.frame:SetFrameStrata("MEDIUM")
    self.frame:SetFrameLevel(1)
end

local MAIN_SECTIONS = {
    { key = "plugins", text = function() return LO["Plugin Management"] end },
    { key = "ui", text = function() return LO["Interface Configuration"] end },
}

local function UpdateMainSectionVisuals()
    for key, btn in pairs(Panel.mainSectionButtons) do
        if key == Panel.currentMainSection then
            btn.bg:SetVertexColor(0.12, 0.12, 0.16, 1)
            btn.text:SetTextColor(1, 1, 1, 1)
            btn.indicator:Show()
        else
            btn.bg:SetVertexColor(unpack(T.tabNormal))
            btn.text:SetTextColor(0.72, 0.72, 0.72, 1)
            btn.indicator:Hide()
        end
    end
end

local function BuildMainSectionButtons()
    for _, btn in pairs(Panel.mainSectionButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    wipe(Panel.mainSectionButtons)

    local sectionBar = Panel.frame.sectionBar
    local xOff = 10

    for _, section in ipairs(MAIN_SECTIONS) do
        local btn = CreateFrame("Button", nil, sectionBar)
        btn:SetSize(110, 24)
        btn:SetPoint("LEFT", sectionBar, "LEFT", xOff, 0)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        bg:SetVertexColor(unpack(T.tabNormal))
        btn.bg = bg

        local indicator = btn:CreateTexture(nil, "OVERLAY")
        indicator:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        indicator:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        indicator:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        indicator:SetHeight(2)
        indicator:SetVertexColor(unpack(T.accent))
        indicator:Hide()
        btn.indicator = indicator

        local text = btn:CreateFontString(nil, "OVERLAY")
        SetSafeFont(text, 12, "")
        text:SetPoint("CENTER", 0, 0)
        text:SetText(section.text())
        text:SetTextColor(0.72, 0.72, 0.72, 1)
        btn.text = text

        btn.sectionKey = section.key
        btn:SetScript("OnClick", function(self)
            Panel:SelectMainSection(self.sectionKey)
        end)
        btn:SetScript("OnEnter", function(self)
            if Panel.currentMainSection ~= self.sectionKey then
                self.bg:SetVertexColor(unpack(T.tabHover))
                self.text:SetTextColor(1, 1, 1, 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if Panel.currentMainSection ~= self.sectionKey then
                self.bg:SetVertexColor(unpack(T.tabNormal))
                self.text:SetTextColor(0.72, 0.72, 0.72, 1)
            end
        end)

        Panel.mainSectionButtons[section.key] = btn
        xOff = xOff + 114
    end
end

local function UpdateSectionLayout()
    if not Panel.frame then
        return
    end

    local showingPlugins = Panel.currentMainSection == "plugins"
    local tabStrip = Panel.frame.tabStrip
    local sep = Panel.frame.tabSeparator
    local content = Panel.frame.content

    if showingPlugins then
        tabStrip:Hide()
        sep:Hide()
        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", Panel.frame.sectionBar, "BOTTOMLEFT", 1, -1)
        content:SetPoint("BOTTOMRIGHT", Panel.frame, "BOTTOMRIGHT", -1, 1)
    else
        tabStrip:Show()
        sep:Show()
        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", tabStrip, "TOPRIGHT", 1, 0)
        content:SetPoint("BOTTOMRIGHT", Panel.frame, "BOTTOMRIGHT", -1, 1)
    end

    if Panel.scrollWidget then
        Panel.scrollWidget.content:SetWidth(content:GetWidth() - 32)
        Panel.scrollWidget:DoLayout()
    end
    if Panel.customContentFrame and Panel.customContentFrame.RefreshLayout then
        Panel.customContentFrame:RefreshLayout()
    end
end

local function BuildPluginManagementPlaceholder(parent)
    local pluginDefinitions = {
        {
            key = "dbm",
            title = "DBM",
            subtitle = LO["Boss encounter warnings and timers."],
            category = "encounter",
            addons = {
                "DBM-Core", "DBM-GUI", "DBM-AQ20", "DBM-AQ40", "DBM-BlackTemple", "DBM-BurningCrusade",
                "DBM-BWL", "DBM-ChamberOfAspects", "DBM-Coliseum", "DBM-EyeOfEternity", "DBM-Hyjal",
                "DBM-Icecrown", "DBM-Karazhan", "DBM-MC", "DBM-Naxx", "DBM-Onyxia", "DBM-Outlands",
                "DBM-Party-BC", "DBM-Party-WotLK", "DBM-PvP", "DBM-Serpentshrine", "DBM-SpellTimers",
                "DBM-Sunwell", "DBM-TheEye", "DBM-Ulduar", "DBM-VoA", "DBM-WorldEvents", "DBM-ZG", "DBM-ZulAman",
            },
            getLoaded = function()
                return _G.DBM ~= nil
            end,
            openConfig = function()
                if _G.DBM and _G.DBM.LoadGUI then
                    _G.DBM:LoadGUI()
                    return true
                end
                return false
            end,
        },
        {
            key = "kui",
            title = "Kui_Nameplates",
            subtitle = LO["Enhanced enemy and friendly nameplates."],
            category = "interface",
            addons = { "Kui_Nameplates", "Kui_Nameplates_Auras" },
            getLoaded = function()
                return _G.KuiNameplates ~= nil
            end,
            openConfig = function()
                if _G.KuiNameplates and _G.KuiNameplates.OpenConfig then
                    _G.KuiNameplates:OpenConfig()
                    return true
                end
                return false
            end,
        },
        {
            key = "skada",
            title = "Skada",
            subtitle = LO["Damage, healing, threat, and combat statistics."],
            category = "stats",
            addons = { "Skada" },
            getLoaded = function()
                return _G.Skada ~= nil
            end,
            openConfig = function()
                if _G.Skada and _G.Skada.OpenOptions then
                    _G.Skada:OpenOptions()
                    return true
                end
                return false
            end,
        },
    }

    local categoryDefinitions = {
        { key = "all", text = LO["All"] },
        { key = "encounter", text = LO["Encounter Tools"] },
        { key = "interface", text = LO["Interface Enhancements"] },
        { key = "stats", text = LO["Combat Statistics"] },
    }

    local function IsPluginInstalled(def)
        for _, addonName in ipairs(def.addons) do
            if not GetAddOnInfo(addonName) then
                return false
            end
        end
        return true
    end

    local function IsAddOnEnabledCompat(addonName)
        if not addonName or not GetAddOnInfo(addonName) then
            return false
        end

        if type(GetAddOnEnableState) == "function" then
            local ok, enabled = pcall(GetAddOnEnableState, UnitName("player"), addonName)
            if ok then
                return enabled and enabled > 0
            end
        end

        local enabled = select(4, GetAddOnInfo(addonName))
        return enabled and enabled ~= 0 and enabled ~= false
    end

    local function IsPluginEnabled(def)
        for _, addonName in ipairs(def.addons) do
            if not IsAddOnEnabledCompat(addonName) then
                return false
            end
        end
        return true
    end

    local function SetPluginEnabled(def, enabled)
        for _, addonName in ipairs(def.addons) do
            if enabled then
                EnableAddOn(addonName)
            else
                DisableAddOn(addonName)
            end
        end
    end

    local function GetPluginStatusText(def)
        if not IsPluginInstalled(def) then
            return "|cffff6666" .. LO["Not installed"] .. "|r"
        end
        if not IsPluginEnabled(def) then
            return "|cff999999" .. LO["Disabled"] .. "|r"
        end
        if def.getLoaded and def.getLoaded() then
            return "|cff44ff88" .. LO["Loaded"] .. "|r"
        end
        return "|cffffcc66" .. LO["Needs Reload"] .. "|r"
    end

    local function ScrollByWheel(scrollFrame, delta, step)
        local range = scrollFrame:GetVerticalScrollRange() or 0
        if range <= 0 then
            return
        end

        local nextValue = scrollFrame:GetVerticalScroll() - (delta * (step or 28))
        if nextValue < 0 then
            nextValue = 0
        elseif nextValue > range then
            nextValue = range
        end

        scrollFrame:SetVerticalScroll(nextValue)
    end

    local function AttachMouseWheel(frame, scrollFrame, step)
        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", function(_, delta)
            ScrollByWheel(scrollFrame, delta, step)
        end)
    end

    local root = CreateFrame("Frame", nil, parent)
    root:SetAllPoints(parent)
    Panel.customContentFrame = root

    local body = CreateFrame("Frame", nil, root)
    body:SetPoint("TOPLEFT", root, "TOPLEFT", 14, -14)
    body:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -14, 14)

    local nav = CreateFrame("Frame", nil, body)
    nav:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
    nav:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 0, 0)
    nav:SetWidth(152)
    nav:SetBackdrop(BD_INNER)
    nav:SetBackdropColor(0.07, 0.07, 0.09, 0.92)
    nav:SetBackdropBorderColor(unpack(T.border))

    local navTitle = nav:CreateFontString(nil, "OVERLAY")
    SetSafeFont(navTitle, 12, "OUTLINE")
    navTitle:SetPoint("TOPLEFT", nav, "TOPLEFT", 12, -12)
    navTitle:SetText(LO["Categories"])
    navTitle:SetTextColor(0.62, 0.76, 0.92, 1)

    local navLine = nav:CreateTexture(nil, "ARTWORK")
    navLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    navLine:SetPoint("TOPLEFT", nav, "TOPLEFT", 12, -32)
    navLine:SetPoint("TOPRIGHT", nav, "TOPRIGHT", -12, -32)
    navLine:SetHeight(1)
    navLine:SetVertexColor(unpack(T.border))

    local navScroll = CreateFrame("ScrollFrame", nil, nav)
    navScroll:SetPoint("TOPLEFT", nav, "TOPLEFT", 10, -42)
    navScroll:SetPoint("BOTTOMRIGHT", nav, "BOTTOMRIGHT", -10, 10)
    AttachMouseWheel(navScroll, navScroll, 32)

    local navChild = CreateFrame("Frame", nil, navScroll)
    navChild:SetPoint("TOPLEFT", navScroll, "TOPLEFT", 0, 0)
    navChild:SetHeight(1)
    navChild:SetWidth(1)
    navScroll:SetScrollChild(navChild)

    local listPane = CreateFrame("Frame", nil, body)
    listPane:SetPoint("TOPLEFT", nav, "TOPRIGHT", 12, 0)
    listPane:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, 0)
    listPane:SetBackdrop(BD_INNER)
    listPane:SetBackdropColor(0.07, 0.07, 0.09, 0.92)
    listPane:SetBackdropBorderColor(unpack(T.border))

    local header = CreateFrame("Frame", nil, listPane)
    header:SetPoint("TOPLEFT", listPane, "TOPLEFT", 8, -8)
    header:SetPoint("TOPRIGHT", listPane, "TOPRIGHT", -8, -8)
    header:SetHeight(28)
    header:SetBackdrop(BD_INNER)
    header:SetBackdropColor(0.11, 0.11, 0.14, 1)
    header:SetBackdropBorderColor(unpack(T.border))

    local headerBottom = header:CreateTexture(nil, "OVERLAY")
    headerBottom:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    headerBottom:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    headerBottom:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    headerBottom:SetHeight(1)
    headerBottom:SetVertexColor(0.22, 0.22, 0.26, 1)

    local function CreateHeaderText(text, point, relativeTo, relativePoint, x, width, justify)
        local fs = header:CreateFontString(nil, "OVERLAY")
        SetSafeFont(fs, 11, "OUTLINE")
        fs:SetPoint(point, relativeTo or header, relativePoint or point, x or 0, 0)
        if width then
            fs:SetWidth(width)
        end
        fs:SetJustifyH(justify or "LEFT")
        fs:SetText(text)
        fs:SetTextColor(0.76, 0.76, 0.82, 1)
        return fs
    end

    CreateHeaderText(LO["Enabled"], "LEFT", header, "LEFT", 10, 56, "CENTER")
    CreateHeaderText(LO["Name"], "LEFT", header, "LEFT", 76, 124, "LEFT")
    CreateHeaderText(LO["Description"], "LEFT", header, "LEFT", 204, nil, "LEFT")
    CreateHeaderText(LO["Action"], "RIGHT", header, "RIGHT", -18, 72, "CENTER")

    local listScroll = CreateFrame("ScrollFrame", nil, listPane)
    listScroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    listScroll:SetPoint("BOTTOMRIGHT", listPane, "BOTTOMRIGHT", -8, 8)
    AttachMouseWheel(listScroll, listScroll, 40)

    local listBody = CreateFrame("Frame", nil, listScroll)
    listBody:SetPoint("TOPLEFT", listScroll, "TOPLEFT", 0, 0)
    listBody:SetHeight(1)
    listBody:SetWidth(1)
    listScroll:SetScrollChild(listBody)

    local emptyText = listPane:CreateFontString(nil, "OVERLAY")
    SetSafeFont(emptyText, 12, "")
    emptyText:SetPoint("CENTER", listScroll, "CENTER", 0, 0)
    emptyText:SetWidth(320)
    emptyText:SetJustifyH("CENTER")
    emptyText:SetText(LO["No integrated addons in this category yet."])
    emptyText:SetTextColor(0.55, 0.55, 0.58, 1)
    emptyText:Hide()

    local function CreateActionButton(parent)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(72, 24)
        btn:SetBackdrop(BD_INNER)
        btn:SetBackdropColor(0.16, 0.16, 0.19, 1)
        btn:SetBackdropBorderColor(0.28, 0.28, 0.32, 1)

        local text = btn:CreateFontString(nil, "OVERLAY")
        SetSafeFont(text, 11, "")
        text:SetPoint("CENTER", 0, 0)
        text:SetText(LO["Settings"])
        text:SetTextColor(0.96, 0.82, 0.24, 1)
        btn.text = text
        btn.isDisabled = false

        btn:SetScript("OnEnter", function(self)
            if self.isDisabled then return end
            self:SetBackdropColor(0.20, 0.20, 0.24, 1)
            self:SetBackdropBorderColor(unpack(T.accent))
            self.text:SetTextColor(1, 0.88, 0.30, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            if self.isDisabled then
                self:SetBackdropColor(0.10, 0.10, 0.12, 1)
                self:SetBackdropBorderColor(0.20, 0.20, 0.24, 1)
                self.text:SetTextColor(0.45, 0.45, 0.48, 1)
            else
                self:SetBackdropColor(0.16, 0.16, 0.19, 1)
                self:SetBackdropBorderColor(0.28, 0.28, 0.32, 1)
                self.text:SetTextColor(0.96, 0.82, 0.24, 1)
            end
        end)

        function btn:SetButtonDisabled(disabled)
            self.isDisabled = disabled and true or false
            self:EnableMouse(not self.isDisabled)

            if self.isDisabled then
                self:SetBackdropColor(0.10, 0.10, 0.12, 1)
                self:SetBackdropBorderColor(0.20, 0.20, 0.24, 1)
                self.text:SetTextColor(0.45, 0.45, 0.48, 1)
            else
                self:SetBackdropColor(0.16, 0.16, 0.19, 1)
                self:SetBackdropBorderColor(0.28, 0.28, 0.32, 1)
                self.text:SetTextColor(0.96, 0.82, 0.24, 1)
            end
        end

        return btn
    end

    local function CreateCategoryButton(parent, label)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetHeight(28)
        btn:SetPoint("LEFT", parent, "LEFT", 0, 0)
        btn:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        bg:SetVertexColor(0.11, 0.11, 0.14, 1)
        btn.bg = bg

        local indicator = btn:CreateTexture(nil, "OVERLAY")
        indicator:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        indicator:SetPoint("LEFT", btn, "LEFT", 0, 0)
        indicator:SetPoint("TOP", btn, "TOP", 0, 0)
        indicator:SetPoint("BOTTOM", btn, "BOTTOM", 0, 0)
        indicator:SetWidth(3)
        indicator:SetVertexColor(unpack(T.accent))
        indicator:Hide()
        btn.indicator = indicator

        local text = btn:CreateFontString(nil, "OVERLAY")
        SetSafeFont(text, 12, "")
        text:SetPoint("LEFT", btn, "LEFT", 10, 0)
        text:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
        text:SetJustifyH("LEFT")
        text:SetText(label)
        text:SetTextColor(0.76, 0.76, 0.80, 1)
        btn.text = text

        btn:SetScript("OnEnter", function(self)
            if self.active then return end
            self.bg:SetVertexColor(0.15, 0.15, 0.19, 1)
            self.text:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            if self.active then return end
            self.bg:SetVertexColor(0.11, 0.11, 0.14, 1)
            self.text:SetTextColor(0.76, 0.76, 0.80, 1)
        end)

        function btn:SetActive(active)
            self.active = active and true or false
            if self.active then
                self.bg:SetVertexColor(0.14, 0.14, 0.18, 1)
                self.text:SetTextColor(1, 1, 1, 1)
                self.indicator:Show()
            else
                self.bg:SetVertexColor(0.11, 0.11, 0.14, 1)
                self.text:SetTextColor(0.76, 0.76, 0.80, 1)
                self.indicator:Hide()
            end
        end

        return btn
    end

    local currentCategory = "all"
    local categoryButtons = {}
    local rows = {}
    local rowHeight = 70

    local function OpenPluginSettings(def)
        if not IsPluginInstalled(def) then
            return
        end

        if not IsPluginEnabled(def) then
            print("|cFFFF0000[DragonUI]|r " .. LO["This plugin is currently disabled. Enable it first and reload the UI."])
            return
        end

        Panel:SendBehindExternalConfig()
        local opened = def.openConfig and def.openConfig()
        if not opened then
            Panel:RestoreFramePriority()
            print("|cFFFF0000[DragonUI]|r " .. LO["This plugin is not loaded yet. Reload the UI first, then try again."])
        end
    end

    local function CreatePluginRow(def, index)
        local row = CreateFrame("Frame", nil, listBody)
        row.def = def
        row:SetHeight(rowHeight)

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        if math.fmod(index, 2) == 0 then
            bg:SetVertexColor(0.09, 0.09, 0.11, 0.85)
        else
            bg:SetVertexColor(0.11, 0.11, 0.13, 0.85)
        end
        row.bg = bg

        local divider = row:CreateTexture(nil, "OVERLAY")
        divider:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        divider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        divider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
        divider:SetHeight(1)
        divider:SetVertexColor(0.18, 0.18, 0.22, 1)

        local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        checkbox:SetSize(22, 22)
        checkbox:SetPoint("LEFT", row, "LEFT", 28, 0)
        if checkbox.text then
            checkbox.text:SetText("")
        end
        AttachMouseWheel(checkbox, listScroll, 40)
        row.checkbox = checkbox

        local name = row:CreateFontString(nil, "OVERLAY")
        SetSafeFont(name, 12, "")
        name:SetPoint("LEFT", row, "LEFT", 76, 0)
        name:SetWidth(118)
        name:SetJustifyH("LEFT")
        name:SetTextColor(0.96, 0.84, 0.16, 1)
        row.name = name

        local action = CreateActionButton(row)
        action:SetPoint("RIGHT", row, "RIGHT", -12, 0)
        AttachMouseWheel(action, listScroll, 40)
        row.action = action

        local desc = row:CreateFontString(nil, "OVERLAY")
        SetSafeFont(desc, 11, "")
        desc:SetPoint("TOPLEFT", row, "TOPLEFT", 204, -14)
        desc:SetPoint("RIGHT", action, "LEFT", -12, 0)
        desc:SetJustifyH("LEFT")
        desc:SetJustifyV("TOP")
        desc:SetTextColor(0.74, 0.74, 0.78, 1)
        row.desc = desc

        checkbox:SetScript("OnClick", function(self)
            SetPluginEnabled(def, self:GetChecked() and true or false)
            if StaticPopup_Show then
                StaticPopup_Show("DRAGONUI_RELOAD_UI")
            end
            if root.RefreshView then
                root:RefreshView()
            end
        end)

        action:SetScript("OnClick", function()
            OpenPluginSettings(def)
            if root.RefreshView then
                root:RefreshView()
            end
        end)

        AttachMouseWheel(row, listScroll, 40)
        return row
    end

    for index, def in ipairs(pluginDefinitions) do
        table.insert(rows, CreatePluginRow(def, index))
    end

    local function UpdateCategoryButtons()
        for _, entry in ipairs(categoryButtons) do
            entry.button:SetActive(entry.key == currentCategory)
        end
    end

    function root:RefreshView()
        UpdateCategoryButtons()

        local shown = 0
        for _, row in ipairs(rows) do
            local def = row.def
            local matchesCategory = currentCategory == "all" or def.category == currentCategory

            if matchesCategory then
                local installed = IsPluginInstalled(def)
                local enabled = installed and IsPluginEnabled(def)
                local loaded = enabled and def.getLoaded and def.getLoaded()

                shown = shown + 1
                row:Show()
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", listBody, "TOPLEFT", 0, -((shown - 1) * rowHeight))
                row:SetPoint("TOPRIGHT", listBody, "TOPRIGHT", 0, -((shown - 1) * rowHeight))
                row.checkbox:SetChecked(enabled)
                row.name:SetText(def.title)
                row.desc:SetText(def.subtitle .. "\n|cff8a8a8a" .. LO["Status"] .. ":|r " .. GetPluginStatusText(def))
                row.action:SetButtonDisabled(not (installed and enabled and loaded))
            else
                row:Hide()
            end
        end

        local bodyHeight = math.max(listScroll:GetHeight() or rowHeight, shown * rowHeight)
        local navHeight = math.max(navScroll:GetHeight() or 1, #categoryDefinitions * 32)

        listBody:SetHeight(bodyHeight)
        navChild:SetHeight(navHeight)

        emptyText:SetShown(shown == 0)
    end

    function root:RefreshLayout()
        local navWidth = math.max(1, navScroll:GetWidth())
        local listWidth = math.max(1, listScroll:GetWidth())

        navChild:SetWidth(navWidth)
        listBody:SetWidth(listWidth)
        self:RefreshView()
    end

    local yOffset = 0
    for _, cat in ipairs(categoryDefinitions) do
        local btn = CreateCategoryButton(navChild, cat.text)
        btn:SetPoint("TOPLEFT", navChild, "TOPLEFT", 0, yOffset)
        btn:SetPoint("TOPRIGHT", navChild, "TOPRIGHT", 0, yOffset)
        btn:SetScript("OnClick", function()
            currentCategory = cat.key
            root:RefreshView()
        end)
        AttachMouseWheel(btn, navScroll, 32)

        table.insert(categoryButtons, {
            key = cat.key,
            button = btn,
        })

        yOffset = yOffset - 32
    end

    root:SetScript("OnSizeChanged", function(self)
        self:RefreshLayout()
    end)

    root:RefreshLayout()
end

local function ScheduleDeferredReskin()
    if not Panel.reskinFrame then
        Panel.reskinFrame = CreateFrame("Frame")
        Panel.reskinFrame:Hide()
        Panel.reskinFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            if self.elapsed >= 0.15 then
                self:Hide()
                local C = addon.PanelControls
                if Panel.scrollWidget and C and C.ReskinAll then
                    C:ReskinAll(Panel.scrollWidget)
                end
            end
        end)
    end

    Panel.reskinFrame.elapsed = 0
    Panel.reskinFrame:Show()
end

-- ============================================================================
-- BUILD TAB BUTTONS (vertical strip)
-- ============================================================================

local function BuildTabButtons()
    -- Clear old
    for _, btn in pairs(Panel.tabButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    wipe(Panel.tabButtons)

    local strip = Panel.frame.tabStrip
    local yOff = -8

    for _, key in ipairs(Panel.tabOrder) do
        local tabInfo = Panel.tabs[key]
        local btn = CreateFrame("Button", nil, strip)
        btn:SetSize(136, 26)
        btn:SetPoint("TOPLEFT", strip, "TOPLEFT", 2, yOff)

        -- Background
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        bg:SetVertexColor(unpack(T.tabNormal))
        btn.bg = bg

        -- Active indicator bar
        local indicator = btn:CreateTexture(nil, "OVERLAY")
        indicator:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        indicator:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        indicator:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        indicator:SetWidth(3)
        indicator:SetVertexColor(unpack(T.accent))
        indicator:Hide()
        btn.indicator = indicator

        -- Text
        local text = btn:CreateFontString(nil, "OVERLAY")
        SetSafeFont(text, 12, "")
        text:SetPoint("LEFT", 10, 0)
        text:SetText(tabInfo.text)
        text:SetTextColor(0.7, 0.7, 0.7, 1)
        btn.text = text

        btn.tabKey = key
        btn:SetScript("OnClick", function()
            Panel:SelectTab(key)
        end)
        btn:SetScript("OnEnter", function(self)
            if Panel.currentTab ~= self.tabKey then
                self.bg:SetVertexColor(unpack(T.tabHover))
                self.text:SetTextColor(1, 1, 1, 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if Panel.currentTab ~= self.tabKey then
                self.bg:SetVertexColor(unpack(T.tabNormal))
                self.text:SetTextColor(0.7, 0.7, 0.7, 1)
            end
        end)

        Panel.tabButtons[key] = btn
        yOff = yOff - 28
    end
end

-- ============================================================================
-- UPDATE TAB VISUALS
-- ============================================================================

local function UpdateTabVisuals()
    for key, btn in pairs(Panel.tabButtons) do
        if key == Panel.currentTab then
            btn.bg:SetVertexColor(0.12, 0.12, 0.16, 1)
            btn.text:SetTextColor(1, 1, 1, 1)
            btn.indicator:Show()
        else
            btn.bg:SetVertexColor(unpack(T.tabNormal))
            btn.text:SetTextColor(0.7, 0.7, 0.7, 1)
            btn.indicator:Hide()
        end
    end
end

-- ============================================================================
-- SELECT TAB
-- ============================================================================

function Panel:SelectTab(key)
    if not self.tabs[key] then return end
    if self.currentMainSection ~= "ui" then
        self.currentMainSection = "ui"
        UpdateMainSectionVisuals()
        UpdateSectionLayout()
    end
    self.currentTab = key
    UpdateTabVisuals()

    -- Release old scroll widget if any
    ReleaseScrollWidget()

    -- Create AceGUI scroll inside the content frame
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")

    -- Attach the AceGUI scroll frame to our content area
    local sf = scroll.frame
    sf:SetParent(self.frame.content)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT", self.frame.content, "TOPLEFT", 6, -6)
    sf:SetPoint("BOTTOMRIGHT", self.frame.content, "BOTTOMRIGHT", -6, 6)
    sf:SetFrameStrata("DIALOG")
    sf:Show()

    -- Fix content area sizing
    scroll.content:SetWidth(self.frame.content:GetWidth() - 32)

    self.scrollWidget = scroll

    -- Call the tab builder
    local tabInfo = self.tabs[key]
    if tabInfo and tabInfo.builder then
        local ok, err = pcall(tabInfo.builder, scroll)
        if not ok then
            local errLabel = AceGUI:Create("Label")
            errLabel:SetText("|cFFFF0000" .. LO["Error:"] .. "|r " .. tostring(err))
            errLabel:SetFullWidth(true)
            scroll:AddChild(errLabel)
        end
    end

    -- Trigger layout
    scroll:DoLayout()

    -- Deferred re-skin pass to fix vanilla texture bleed-through.
    ScheduleDeferredReskin()
end

function Panel:SelectMainSection(sectionKey, selectTab)
    local targetSection = (sectionKey == "plugins") and "plugins" or "ui"
    self.currentMainSection = targetSection
    UpdateMainSectionVisuals()
    UpdateSectionLayout()

    if targetSection == "plugins" then
        ReleaseScrollWidget()
        BuildPluginManagementPlaceholder(self.frame.content)
        return
    end

    local targetTab = selectTab
    if not targetTab or not self.tabs[targetTab] then
        targetTab = self.currentTab or (self.tabOrder[1] or nil)
    end

    if targetTab then
        self:SelectTab(targetTab)
    end
end

-- ============================================================================
-- OPEN / CLOSE / TOGGLE
-- ============================================================================

function Panel:Open(selectTab)
    if InCombatLockdown() then
        print("|cFFFF0000[DragonUI]|r " .. LO["Cannot open options during combat."])
        return
    end

    if not self.frame then
        self.frame = CreatePanel()
        BuildTabButtons()
        BuildMainSectionButtons()
    end

    self.frame:Show()
    self:RestoreFramePriority()

    if selectTab == "plugins" or selectTab == "pluginmanager" then
        self:SelectMainSection("plugins")
        return
    end

    local tab = selectTab
    if tab and not self.tabs[tab] then
        tab = nil
    end
    if not tab then
        tab = self.currentTab or (self.tabOrder[1] or nil)
    end

    if tab then
        self:SelectMainSection("ui", tab)
    end
end

function Panel:Close()
    if self.frame then
        -- Release the scroll widget properly
        ReleaseScrollWidget()
        self.frame:Hide()
    end
end

function Panel:Toggle(selectTab)
    if self.frame and self.frame:IsShown() then
        self:Close()
    else
        self:Open(selectTab)
    end
end

function Panel:IsOpen()
    return self.frame and self.frame:IsShown()
end
