local scenario = ...
local Plugin, Boot, Store, ctx = addon.Portal, addon.PortalBoot, addon.PortalStore, addon.PortalContext
local function Check(condition, message)
    assert(condition, message)
end
local originalStore = OrbitPortalDB
addon.PortalScanner.GetOrderedList = function()
    return { { type = "spell", spellID = 123, name = "Fixture Portal", category = "CLASS", icon = 134400 } }
end
if scenario == "loaderror" or scenario == "movementerror" then
    allowedErrors = 1
    if scenario == "loaderror" then
        local onLoad = Plugin.OnLoad
        Plugin.OnLoad = function(self)
            onLoad(self)
            error("injected constructor failure")
        end
    else
        local create = addon.LibOrbitUI.Movement.Create
        addon.LibOrbitUI.Movement.Create = function(self, ...)
            create(self, ...)
            error("injected movement failure")
        end
    end
end
Emit("ADDON_LOADED", "Orbit_Portal")
Emit("PLAYER_LOGIN")
Check(settingsCategory ~= nil, "direct settings registration")
if scenario == "loaderror" or scenario == "movementerror" then
    Check(#errors == 1 and frameCreations == 1 and not Plugin._portalActive, "constructor failure reported once")
    local initialCount = #frames
    for _ = 1, 3 do
        Boot.Apply()
        Emit("PLAYER_REGEN_ENABLED")
        FlushTimers()
    end
    Check(
        #errors == 1 and frameCreations == 1 and #frames == initialCount,
        "failed initialization never reconstructs partial graph"
    )
    Boot.ShowSettings()
    Boot.ResetPosition()
    Check(messages[#messages]:find(addon.L.MSG_PORTAL_NOT_READY, 1, true), "failed feature reports inactive state")
    return
end
if scenario == "future" then
    Check(OrbitPortalDB == originalStore and OrbitPortalDB.marker == "untouched", "future DB untouched")
    Check(not Plugin._portalConstructed and not OrbitPortalFrame, "unsupported store constructs no secure frame")
    SlashCmdList.ORBITPORTAL("status")
    Check(messages[#messages]:find(addon.L.MSG_PORTAL_UNSUPPORTED_STORE, 1, true), "status reports unsupported store")
    return
end
if scenario == "disabled" then
    Check(not Plugin._portalConstructed and frameCreations == 0 and mapRequests == 0, "disabled first boot stays inert")
    Boot.ShowSettings()
    Check(OrbitPortalSettings:IsShown(), "disabled product has usable settings")
    Store:Set("Enabled", true)
    Boot.Apply()
elseif scenario == "blocked" then
    Check(not Plugin._portalConstructed and frameCreations == 0, "blocked startup defers construction")
    SetCombat(false)
elseif scenario == "legacy" then
    Check(OrbitPortalDB == nil and addon.PortalOrbit ~= nil, "legacy mode never hydrates standalone DB")
    Check(not Plugin._portalConstructed, "host lifecycle owns legacy construction")
    Plugin:OnLoad()
    Plugin:OnEnable()
end
FlushTimers()
FlushTimers()
Check(Plugin._portalActive and Plugin.frame and #ctx.state.visibleIcons == 1, "initial frame painted")
Check(frameCreations == 1 and mapRequests == 1, "one constructor")
local firstIcon = ctx.state.visibleIcons[1]
if scenario == "standalone" or scenario == "legacy" then
    local scan = addon.PortalScanner.GetOrderedList
    addon.PortalScanner.GetOrderedList = function()
        return {
            { type = "spell", spellID = 123, name = "First Portal", category = "CLASS", icon = 134400 },
            { type = "spell", spellID = 456, name = "Second Portal", category = "CLASS", icon = 134400 },
        }
    end
    ctx.Refresh()
    Check(#ctx.state.visibleIcons == 2, "refresh paints both portals")
    ctx.HandleWheel(ctx.frame, -1)
    Check(
        ctx.state.visibleIcons[1] == firstIcon and firstIcon:GetAttribute("spell") == 456,
        "wheel repaints pooled icons"
    )
    addon.PortalScanner.GetOrderedList = function()
        return {
            { type = "spell", spellID = 810, name = "Sunken Vault", category = "CLASS", icon = 134400 },
            { type = "spell", spellID = 811, name = "Vault", short = "VLT", category = "CLASS", icon = 134400 },
            { type = "spell", spellID = 812, name = "Gate", short = "V", category = "CLASS", icon = 134400 },
            { type = "spell", spellID = 813, name = "Valley", short = "GV", category = "CLASS", icon = 134400 },
            { type = "spell", spellID = 814, name = "Shrine", short = "SV", category = "CLASS", icon = 134400 },
        }
    end
    ctx.Refresh()
    ctx.state.scrollOffset = 2
    ctx.state.isMouseOver = true
    addon.PortalNavigation.ShowSearch()
    local search
    for _, candidate in ipairs(frames) do
        if candidate.scripts.OnChar and candidate.scripts.OnKeyDown and candidate:IsShown() then
            search = candidate
            break
        end
    end
    Check(search, "hover shows the search keyboard frame")
    search.scripts.OnKeyDown(search, "V")
    Check(not search.propagate, "search consumes a typing key")
    search.scripts.OnChar(search, "V")
    local ranked = {}
    for index, item in ipairs(ctx.state.searchFilter) do
        ranked[index] = item.spellID
    end
    Check(table.concat(ranked, ",") == "812,811,813,814,810", "search ranks matches and preserves ties")
    search.scripts.OnKeyDown(search, "TAB")
    Check(not search.propagate and ctx.state.scrollOffset == 1, "tab pages the active filter")
    ctx.HandleWheel(ctx.frame, -1)
    Check(ctx.state.scrollOffset == 2, "wheel pages the active filter")
    search.scripts.OnChar(search, "!")
    Check(not ctx.state.searchFilter and ctx.state.scrollOffset == 2, "no match restores the unfiltered scroll")
    ctx.HoverExit()
    Check(not search:IsShown() and search.propagate, "hover exit releases search and restores propagation")
    addon.PortalScanner.GetOrderedList = scan
    ctx.state.scrollOffset = 0
    ctx.Refresh()
end
Check(firstIcon:GetAttribute("type1") == "spell" and firstIcon:GetAttribute("spell") == 123, "secure spell configured")
firstIcon.scripts.PreClick(firstIcon, "RightButton", true)
firstIcon.scripts.PreClick(firstIcon, "RightButton", false)
Check(
    Plugin:GetSetting(1, "Favorites")["123"] == true and firstIcon:GetAttribute("type1") == "spell",
    "right-click down/up toggles once and preserves left action"
)
if scenario == "corrupt" then
    Check(OrbitPortalDB.profiles.default.settings.Position == "bad", "bad raw position retained")
    Check(
        Plugin:GetSetting(1, "Position").point == "LEFT" and Plugin:GetSetting(1, "MaxVisible") == 9,
        "invalid reads resolve defaults"
    )
end
if scenario ~= "legacy" then
    Check(addon.PortalOrbit == nil, "plain controller selected without compatible host")
    Store:Set("EnableKeyboardSearch", false)
    Store:Set("Spacing", 0)
    Check(Store:Get("EnableKeyboardSearch") == false and Store:Get("Spacing") == 0, "false and zero preserved")
    local favorites = Store:Get("Favorites")
    favorites.test = true
    Check(Store:Get("Favorites").test == nil, "table reads are defensive copies")
    Store:Set("Favorites", favorites)
    favorites.test = false
    Check(Store:Get("Favorites").test == true, "table writes are defensive copies")
    for _, case in ipairs({
        { "Position", "bad" },
        { "IconSize", 0 },
        { "MaxVisible", 4 },
        { "Spacing", 0 / 0 },
        { "Favorites", { bad = 1 } },
        { "Enabled", 1 },
        { "DisabledComponents", { {} } },
    }) do
        Check(not pcall(Store.Set, Store, case[1], case[2]), "invalid write rejected: " .. case[1])
    end
end
local tabs = addon.PortalSchema.Tabs(Plugin, ctx)
Check(tabs[1].id == "layout" and tabs[2].id == "appearance" and tabs[3].id == "behaviours", "canonical tab order")
for _, tab in ipairs(tabs) do
    Check(tab.scopeText == addon.L.CFG_SETTINGS_SCOPE_LAYOUT, "tab scope visible in standalone settings")
end
Check(tabs[2].controls[5].type == "dropdown" and #tabs[2].controls[5].options == 3, "animation uses named choices")
Plugin:SetSetting(1, "DisabledComponents", { "Timer", "Unrelated" })
tabs[2].controls[4].onReset()
Check(
    #Plugin:GetSetting(1, "DisabledComponents") == 1 and Plugin:GetSetting(1, "DisabledComponents")[1] == "Unrelated",
    "component reset preserves unowned components"
)
Plugin:SetSetting(1, "EnabledCategories", { CLASS = false, UNSUPPORTED = false })
tabs[4].controls()[1].onReset()
Check(
    Plugin:GetSetting(1, "EnabledCategories").CLASS == nil
        and Plugin:GetSetting(1, "EnabledCategories").UNSUPPORTED == false,
    "category reset preserves unavailable categories"
)
Plugin:SetSetting(1, "HideLongCooldowns", true)
Check(not tabs[3].controls[1].getValue(), "positive cooldown label reads inverse stored preference")
tabs[3].controls[1].onChange(true)
Check(not Plugin:GetSetting(1, "HideLongCooldowns"), "positive cooldown label writes inverse stored preference")
Boot.ShowSettings()
Check(OrbitPortalSettings:IsShown(), "direct standalone dialog rendered")
Check(
    OrbitPortalSettings.layout.Stack == addon.LibOrbitUI.Layout.Methods.Stack,
    "Portal dialog uses the shared layout implementation"
)
Check(
    OrbitPortalSettings.OrbitPanel.configPanelOwner == OrbitPortalSettings.renderer,
    "Portal dialog uses the shared panel owner"
)
local setting = OrbitPortalSettings.controls[1]
local help = setting._tooltipHover
Check(
    help and help.mouse and help.propagateMouseClicks and help.relative == setting.Label,
    "settings label help propagates clicks to the control"
)
Check(
    help._tooltip():find(addon.L.CFG_SETTINGS_SCOPE_LAYOUT, 1, true),
    "settings scope remains available in hover help"
)
Check(
    #OrbitPortalSettings.layout.containerControls[setting:GetParent()] == #OrbitPortalSettings.controls,
    "settings scope does not create a visible explanatory row"
)
local background = OrbitPortalSettings.Chrome.Background
if scenario == "noatlas" then
    local backdrop = addon.LibOrbitUI.Config.Defaults.DialogBackdrop
    Check(
        background.atlas == nil
            and background.color[1] == backdrop.r
            and background.color[2] == backdrop.g
            and background.color[3] == backdrop.b
            and background.color[4] == backdrop.a,
        "missing shell atlas falls back to the shared backdrop colour"
    )
else
    Check(
        background.atlas == "housing-basic-container" and background.color == nil,
        "Portal uses Orbit settings shell art when the atlas resolves"
    )
end
Check(
    OrbitPortalSettings:GetWidth() == addon.LibOrbitUI.Config.Defaults.Panel.DialogWidth,
    "Portal uses the shared dialog width"
)
local footer = OrbitPortalSettings.OrbitPanel.Footer
Check(
    #OrbitPortalSettings.layout.containerControls[footer] == 4 and footer:GetHeight() == 70,
    "Portal layout actions and close share the two-column footer"
)
OrbitPortalSettings:SelectTab("behaviours")
OrbitPortalSettings:SelectTab("categories")
Check(
    #OrbitPortalSettings.layout.containerControls[footer] == 1 and footer:GetHeight() == 44,
    "conditional footer rebuild removes layout actions"
)
Check(
    OrbitPortalSettings.controls[1].Label:GetJustifyH() == "LEFT",
    "Portal category checkbox uses native left-aligned label"
)
OrbitPortalSettings:SelectTab("layout")
local settingsInput
for _, frame in ipairs(frames) do
    if frame.template == "InsecureKeyboardInputPropagatorTemplate" then
        Check(settingsInput == nil, "settings retain one Escape input proxy")
        settingsInput = frame
    end
end
Check(
    settingsInput and settingsInput:GetParent() == UIParent and settingsInput.point == nil,
    "settings Escape input stays outside the window ancestry"
)
Check(
    settingsInput:IsVisible() and settingsInput.keyboard and settingsInput.propagate,
    "shown settings arm a propagating keyboard proxy"
)
Check(not OrbitPortalSettings.keyboard and #UISpecialFrames == 0, "settings leave native keyboard ownership intact")
local function SettingsKey(key)
    if not settingsInput:IsVisible() or not settingsInput.keyboard then
        return true
    end
    settingsInput:GetScript("OnKeyDown")(settingsInput, key)
    return settingsInput.propagate
end
Check(SettingsKey("K") and OrbitPortalSettings:IsShown(), "ordinary settings keys propagate")
local settingsLevel, settingsStrata = OrbitPortalSettings:GetFrameLevel(), OrbitPortalSettings:GetFrameStrata()
OrbitPortalSettings:Raise()
OrbitPortalSettings:SetFrameLevel(settingsLevel + 10)
OrbitPortalSettings:SetFrameStrata("HIGH")
Check(
    settingsInput:GetFrameLevel() == OrbitPortalSettings:GetFrameLevel() + 1
        and settingsInput:GetFrameStrata() == "HIGH",
    "settings input follows window depth changes"
)
OrbitPortalSettings:Lower()
OrbitPortalSettings:SetFrameLevel(settingsLevel)
OrbitPortalSettings:SetFrameStrata(settingsStrata)
Check(not SettingsKey("ESCAPE"), "settings consume Escape")
Check(
    not OrbitPortalSettings:IsShown() and not settingsInput:IsShown() and #OrbitPortalSettings.controls == 0,
    "Escape closes settings and releases their controls and input"
)
FlushTimers()
Check(not settingsInput:IsShown() and SettingsKey("ESCAPE"), "deferred restoration cannot reopen closed settings")
Boot.ShowSettings()
Check(
    OrbitPortalSettings:IsShown() and settingsInput:IsVisible() and settingsInput.propagate,
    "reopening settings restores input propagation"
)
local control = OrbitPortalSettings.spec.tabs[1].controls[1]
addon.LibOrbitUI.Config.CommitValue(OrbitPortalSettings.spec, control, false)
Check(not Plugin._portalActive, "dialog enablement disables product")
addon.LibOrbitUI.Config.CommitValue(OrbitPortalSettings.spec, control, true)
FlushTimers()
local frameCount = #frames
for _ = 1, 20 do
    addon.LibOrbitUI.Config.CommitValue(OrbitPortalSettings.spec, control, false)
    addon.LibOrbitUI.Config.CommitValue(OrbitPortalSettings.spec, control, true)
    FlushTimers()
end
Check(
    #frames == frameCount and frameCreations == 1 and mapRequests == 1,
    "toggle cycles retain singleton and pooled objects"
)
Check(ctx.state.visibleIcons[1] == firstIcon, "icons reused across toggle cycles")
local activeTicker
for _, timer in ipairs(timers) do
    if timer.ticker and not timer.cancelled then
        Check(not activeTicker, "duplicate feature ticker after repeated toggles")
        activeTicker = timer
    end
end
Check(activeTicker and activeTicker.delay == 15, "only one live feature ticker at the original cadence")

local readSpellCooldown, repaint = C_Spell.GetSpellCooldown, addon.PortalIconWindow.Repaint
local cooldownStart = now - 5
local reads, paints = 0, 0
C_Spell.GetSpellCooldown = function(spellID)
    Check(spellID == 123, "ticker reads the displayed spell")
    reads = reads + 1
    return { startTime = cooldownStart, duration = 20 }
end
addon.PortalIconWindow.Repaint = function(context)
    paints = paints + 1
    repaint(context)
end
local entry = ctx.state.portalList[1]
activeTicker.callback()
Check(
    ctx.state.portalList[1] == entry and entry.cooldown == 15 and entry.cooldownDuration == 20,
    "tick updates in place"
)
Check(reads == 1 and paints == 1, "one read and repaint for the active cooldown")
cooldownStart = "SECRET"
activeTicker.callback()
Check(entry.cooldown == 0 and entry.cooldownDuration == 0 and paints == 2, "restricted data clears the cooldown once")
activeTicker.callback()
Check(reads == 3 and paints == 2, "idle ticks leave the display alone")
combat = true
activeTicker.callback()
Check(reads == 3 and paints == 2, "combat blocks cooldown reads and repaints")
combat = false
C_Spell.GetSpellCooldown, addon.PortalIconWindow.Repaint = readSpellCooldown, repaint

if scenario == "legacy" then
    Check(
        addon.PortalServices.GetSearchFontPath() == "Fixture\\Orbit UI Chat"
            and addon.PortalServices.GetFontPath() == STANDARD_TEXT_FONT,
        "hosted fonts resolve through Orbit media, with an unset theme font falling back to the standard font"
    )
    Check(fadeRegistrations == 22 and hostCallbacks ~= nil, "legacy fade and edit lifecycle restored on each enable")
    local settingsDialog = { orbitCurrentTab = "Previous frame" }
    Plugin:AddSettings(settingsDialog, {})
    Check(hostSettings.controls[1].type == "tabs", "hosted settings retain their tab selector")
    local settingsTabs = hostSettings.controls[1].tabs
    Check(settingsDialog.orbitCurrentTab == settingsTabs[1], "hosted settings discard another frame's selected tab")
    for _, label in ipairs(settingsTabs) do
        settingsDialog.orbitCurrentTab = label
        Plugin:AddSettings(settingsDialog, {})
        Check(hostSettings.controls[1].activeTab == label, "hosted tabs retain the active selection")
        Check(#hostSettings.controls > 1, "every hosted tab includes its controls after the selector")
    end
    hostSuppressed = true
    Plugin:UpdateVisibility()
    Check(Plugin._portalHidden and Plugin.frame.driver == "hide", "host profile suppression retains hidden driver")
    hostSuppressed = false
    Plugin:UpdateVisibility()
    hostCallbacks.Enter()
    Check(ctx.state.isEditModeActive and firstIcon:GetAttribute("type1") == nil, "legacy edit enters disarmed")
    hostCallbacks.Exit()
    FlushTimers()
    Boot.EnterEditMode()
    Check(hostEntry, "legacy entry routes through host gate")
else
    Boot.EnterEditMode()
    Check(ctx.state.isEditModeActive and firstIcon:GetAttribute("type1") == nil, "native edit enters disarmed")
    EditModeManagerFrame.active = false
    EventRegistry:TriggerEvent("EditMode.Exit")
    FlushTimers()
end
FlushTimers()
Check(firstIcon:GetAttribute("type1") == "spell", "edit exit restores action")
local paint = { iconSize = 32, maxVisible = 9, fadeAmount = 0 }
addon.PortalIcon.Configure(ctx, firstIcon, {
    type = "housing",
    category = "HOUSING",
    houseInfo = {
        neighborhoodGUID = "n",
        houseGUID = "h",
        plotID = 1,
    },
}, 0, paint)
Check(firstIcon:GetAttribute("type1") == "teleporthome", "complete housing action")
addon.PortalIcon.Configure(ctx, firstIcon, { type = "spell", spellID = 456, category = "CLASS" }, 0, paint)
Check(
    firstIcon:GetAttribute("house-guid") == nil and firstIcon:GetAttribute("spell") == 456,
    "pooled housing fields cleared"
)
addon.PortalIcon.Configure(ctx, firstIcon, { type = "housing", category = "HOUSING", houseInfo = {} }, 0, paint)
Check(
    firstIcon:GetAttribute("type1") == nil and firstIcon:GetAttribute("spell") == nil,
    "pending housing remains inert"
)
local paintedColors = {}
for _, key in ipairs({ "DungeonScore", "DungeonShort" }) do
    firstIcon[key].SetTextColor = function(_, r, g, b)
        paintedColors[key] = { r, g, b }
    end
end
local scoreOverrides = { CustomColorCurve = { pins = {} } }
addon.PortalCanvas.ApplyIconComponents(
    firstIcon,
    { category = "SEASONAL_DUNGEON", challengeModeID = 501, short = "AA" },
    {},
    true,
    {
        fontPath = STANDARD_TEXT_FONT,
        disabled = {},
        positions = {
            DungeonScore = {
                anchorX = "CENTER",
                anchorY = "BOTTOM",
                offsetX = 0,
                offsetY = -2,
                overrides = scoreOverrides,
            },
            DungeonShort = { anchorX = "CENTER", anchorY = "TOP", offsetX = 0, offsetY = 2 },
            FavouriteStar = { anchorX = "RIGHT", anchorY = "TOP", offsetX = 1, offsetY = 1, overrides = { Scale = 2 } },
        },
    }
)
local pixelScale = firstIcon:GetEffectiveScale()
Check(
    firstIcon.FavouriteStar:GetWidth()
            == addon.PortalServices.pixel:Snap(firstIcon.favouriteStarBaseSize * 2, pixelScale)
        and firstIcon.FavouriteStarShadow:GetWidth()
            == addon.PortalServices.pixel:Snap(firstIcon.favouriteStarShadowBaseSize * 2, pixelScale),
    "favourite star Scale override resizes the star and its shadow"
)
Check(paintedColors.DungeonShort and paintedColors.DungeonShort[1] == 1, "DungeonShort stays white without a colour")
if scenario == "legacy" then
    Check(
        firstIcon.DungeonScore.hostTextColorOverrides == scoreOverrides and paintedColors.DungeonScore == nil,
        "hosted score colour override replaces the tier colour"
    )
    Check(
        firstIcon.hostCanvasBorderInset == 0 and firstIcon.DungeonScoreOverlay.hostCanvasBorderInset == 0,
        "hosted text parents publish the zero inset the Canvas preview uses"
    )
    hostDraftPositions, hostDraftDisabled = { Timer = { anchorX = "LEFT", anchorY = "TOP" } }, { "FavouriteStar" }
    Check(
        addon.PortalServices.GetComponentPositions(Plugin) == hostDraftPositions
            and addon.PortalCanvas.BuildDisabledSet(Plugin).FavouriteStar,
        "hosted paint reads the open Canvas draft"
    )
    hostDraftPositions, hostDraftDisabled = nil, nil
else
    local r, g, b = addon.PortalCanvas.GetDungeonScoreColor(123)
    local painted = paintedColors.DungeonScore
    Check(painted[1] == r and painted[2] == g and painted[3] == b, "standalone score keeps its tier colour")
end
SetCombat(true)
Check(not OrbitPortalSettings:IsShown() and not settingsInput:IsShown(), "combat releases settings keyboard input")
Check(not Plugin.frame.shown, "native combat driver hides root")
addon.LibOrbitUI.Config.CommitValue(OrbitPortalSettings.spec, control, false)
Check(not Plugin._portalActive and Plugin.frame:GetAlpha() == 0, "combat disable releases product immediately")
SetCombat(false)
Check(not settingsInput:IsShown(), "combat exit does not reopen settings input")
Check(Plugin.frame.driver == "hide" and not Plugin.frame.shown, "deferred hide completes after combat")
addon.LibOrbitUI.Config.CommitValue(OrbitPortalSettings.spec, control, true)
FlushTimers()
Check(
    Plugin._portalActive and Plugin.frame.shown and frameCreations == 1,
    "post-combat enable reuses frame: "
        .. tostring(Plugin._portalActive)
        .. ":"
        .. tostring(Plugin.frame.shown)
        .. ":"
        .. tostring(Plugin.frame.driver)
        .. ":"
        .. tostring(Plugin._portalHidden)
)
Check(#errors == 0, errors[1])
