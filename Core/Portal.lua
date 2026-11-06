local _, addon = ...

local Services = addon.PortalServices
local Pixel = Services.pixel
local Bridge = addon.PortalOrbit
local Housing = addon.PortalHousing
local Cooldowns = addon.PortalCooldowns
local ViewList = addon.PortalViewList
local IconWindow = addon.PortalIconWindow

local ipairs = ipairs
local InCombatLockdown = InCombatLockdown

-- [ PLUGIN REGISTRATION ] ---------------------------------------------------------------------------------------------
local SYSTEM_ID = "Orbit_Portal"

local Plugin
if Bridge then
    Plugin = Bridge.CreatePlugin()
else
    Plugin = {
        name = "Orbit-Portal",
        displayName = addon.L.PLU_VE_PORTAL,
        system = SYSTEM_ID,
        defaults = addon.PortalDefaults,
    }
    function Plugin:GetSetting(_, key)
        return addon.PortalStore:Get(key)
    end
    function Plugin:SetSetting(_, key, value)
        addon.PortalStore:Set(key, value)
    end
end
addon.Portal = Plugin

-- [ CONSTANTS ] -------------------------------------------------------------------------------------------------------
local RESTING_ALPHA = 1.0

local INITIAL_FRAME_WIDTH = 44
local INITIAL_FRAME_HEIGHT = 200
local INITIAL_FRAME_X_OFFSET = 10
local HOVER_HIT_INSET = 10
local FRAME_LEVEL = 100
local FRAME_STRATA = "MEDIUM"
local INITIAL_SCAN_DELAY = 2

local COOLDOWN_REFRESH_INTERVAL = 15
local REFRESH_DEBOUNCE = 0.1
local EVENTS = {
    "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED",
    "ENCOUNTER_START",
    "ENCOUNTER_END",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_LEVEL_UP",
    "PLAYER_EQUIPMENT_CHANGED",
    "SPELLS_CHANGED",
    "SKILL_LINES_CHANGED",
    "BAG_UPDATE_DELAYED",
    "TOYS_UPDATED",
    "PLAYER_HOUSE_LIST_UPDATED",
    "PET_BATTLE_OPENING_START",
    "PET_BATTLE_CLOSE",
    "UNIT_ENTERED_VEHICLE",
    "UNIT_EXITED_VEHICLE",
}
local VISIBILITY_DRIVER = "[combat][petbattle][vehicleui] hide; show"

-- [ STATE ] -----------------------------------------------------------------------------------------------------------
local frame
local runtimeStartPending, refreshPending = false, false
local hadActiveCooldowns = false

-- Keep the native gameplay owner in Portal's load context before Orbit invokes the hosted lifecycle.
Plugin.eventFrame = CreateFrame("Frame")

local state = {
    portalList = {},
    visibleIcons = {},
    scrollOffset = 0,
    isMouseOver = false,
    isEditModeActive = false,
    pendingRefresh = false,
    mythicPlusCache = {},
}

local ctx = { plugin = Plugin, state = state }
addon.PortalContext = ctx

local function Refresh()
    local Combat = addon.PortalCombat
    if not frame or not Plugin._portalActive or not Combat.CanInteract() then
        return
    end

    state.searchFilter = nil

    local rawList = addon.PortalScanner:GetOrderedList()
    state.portalList, state.firstIndexOfCategory = ViewList.Build(Plugin, rawList)

    IconWindow.Repaint(ctx)
end

local function RefreshWhenReady()
    if not Plugin._portalActive then
        return
    end
    if addon.PortalCombat.CanInteract() then
        Refresh()
    else
        state.pendingRefresh = true
    end
end

local function RefreshCooldowns()
    if not Plugin._portalActive or not addon.PortalCombat.CanInteract() then
        return
    end
    local list = state.portalList
    if #list == 0 then
        return
    end
    Cooldowns.Refresh(list)
    local anyActive = false
    for _, item in ipairs(list) do
        if item.cooldown and item.cooldown > 0 then
            anyActive = true
            break
        end
    end
    if anyActive or hadActiveCooldowns then
        IconWindow.Repaint(ctx)
    end
    hadActiveCooldowns = anyActive
end

local RequestRefresh
local function StartRuntimeWork(frame)
    frame:SetScript("OnUpdate", nil)
    if not Plugin._portalActive then
        return
    end
    if refreshPending then
        refreshPending = false
        Services.runtime:Debounce("refresh", RefreshWhenReady, REFRESH_DEBOUNCE)
    end
    if runtimeStartPending then
        runtimeStartPending = false
        Services.runtime:After("initialScan", INITIAL_SCAN_DELAY, function()
            if not Plugin._portalActive then
                return
            end
            Housing:RequestOwnedHouses()
            RequestRefresh()
        end)
        Services.runtime:Ticker("cooldowns", COOLDOWN_REFRESH_INTERVAL, RefreshCooldowns)
    end
end

RequestRefresh = function()
    if not Plugin._portalActive then
        return
    end
    Services.runtime:Cancel("refresh")
    refreshPending = true
    Plugin.eventFrame:SetScript("OnUpdate", StartRuntimeWork)
end

ctx.Refresh = Refresh
ctx.RequestRefresh = RequestRefresh

-- [ FRAME CREATION ] --------------------------------------------------------------------------------------------------
local function CreatePortalFrame()
    frame = CreateFrame("Frame", "OrbitPortalFrame", UIParent, "SecureHandlerStateTemplate")
    frame:Hide()
    frame:SetSize(INITIAL_FRAME_WIDTH, INITIAL_FRAME_HEIGHT)
    frame:SetPoint("LEFT", UIParent, "LEFT", INITIAL_FRAME_X_OFFSET, 0)

    Pixel:Enforce(frame)

    frame:SetFrameStrata(FRAME_STRATA)
    frame:SetFrameLevel(FRAME_LEVEL)
    frame:SetClampedToScreen(true)
    local sw, sh = GetScreenWidth(), GetScreenHeight()
    frame:SetClampRectInsets(sw, -sw, -sh, sh)
    frame:EnableMouse(true)
    frame:SetHitRectInsets(-HOVER_HIT_INSET, -HOVER_HIT_INSET, -HOVER_HIT_INSET, -HOVER_HIT_INSET)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    ctx.frame = frame

    -- IsMouseOver ignores hit-rect insets, so re-expand the test rect by the same pad to match the enlarged trigger.
    local function IsCursorOverFrame()
        return frame:IsMouseOver(HOVER_HIT_INSET, -HOVER_HIT_INSET, -HOVER_HIT_INSET, HOVER_HIT_INSET)
    end
    ctx.IsCursorOverFrame = IsCursorOverFrame

    local content = CreateFrame("Frame", nil, frame)
    content:SetAllPoints(frame)
    frame.content = content
    ctx.content = content

    local function HoverEnter()
        state.isMouseOver = true
        addon.PortalNavigation.ShowSearch()
        addon.PortalReveal.Reveal(ctx)
    end
    ctx.HoverEnter = HoverEnter

    local function HoverExit()
        if IsCursorOverFrame() then
            return
        end
        state.isMouseOver = false
        addon.PortalNavigation.HideSearch()
        addon.PortalNavigation.ClearSearchBuffer()
        addon.PortalReveal.Conceal(ctx)
    end
    ctx.HoverExit = HoverExit

    addon.PortalNavigation.Install(ctx)

    frame:SetScript("OnEnter", HoverEnter)
    frame:SetScript("OnLeave", HoverExit)

    frame:SetAlpha(RESTING_ALPHA)
    frame.orbitAutoOrient = true

    function frame:GetCanvasBorderInset()
        return 0
    end

    if Bridge then
        Bridge.AttachCanvas(ctx)
    end

    return frame
end

-- [ LIFECYCLE ] -------------------------------------------------------------------------------------------------------
function Plugin:OnLoad()
    frame = CreatePortalFrame()
    self.frame = frame
    self._portalConstructed = true
    frame.editModeName = addon.L.PLU_VE_PORTAL
    frame.systemIndex = 1
    C_MythicPlus.RequestMapInfo()
    C_MythicPlus.RequestCurrentAffixes()
    if Bridge then
        Bridge.AttachFrame(ctx)
    end
    addon.PortalReveal.Install(ctx)
    self.eventFrame:SetScript("OnEvent", function(_, event, ...)
        if not self._portalActive then
            return
        end
        local Combat = addon.PortalCombat
        if event == "PLAYER_HOUSE_LIST_UPDATED" then
            Housing:SetOwnedHouses(...)
        elseif event == "PLAYER_ENTERING_WORLD" then
            Housing:RequestOwnedHouses()
        end
        if
            event == "PLAYER_REGEN_ENABLED"
            or event == "PLAYER_REGEN_DISABLED"
            or event == "ENCOUNTER_START"
            or event == "ENCOUNTER_END"
            or event == "PET_BATTLE_OPENING_START"
            or event == "PET_BATTLE_CLOSE"
            or event == "UNIT_ENTERED_VEHICLE"
            or event == "UNIT_EXITED_VEHICLE"
        then
            Combat.UpdateState(ctx)
        end
        RequestRefresh()
        self:UpdateVisibility()
    end)
end

local function ReconcileVisibility()
    if not frame then
        return
    end
    local shown = Plugin._portalActive and not Plugin._portalHidden
    RegisterStateDriver(frame, "visibility", shown and VISIBILITY_DRIVER or "hide")
    frame:EnableMouse(shown)
    if shown then
        if #state.portalList == 0 and not state.isEditModeActive then
            frame:Hide()
        end
    else
        frame:Hide()
    end
end
local visibilityHandle = Services.runtime:RegisterReconciler("visibility", ReconcileVisibility)

function Plugin:OnEnable()
    self._portalActive = true
    runtimeStartPending, hadActiveCooldowns = true, false
    for _, event in ipairs(EVENTS) do
        self.eventFrame:RegisterEvent(event)
    end
    if Bridge then
        Bridge.Enable(ctx)
    end
    self:UpdateVisibility()
    RequestRefresh()
end

function Plugin:OnDisable()
    self._portalActive = false
    self.eventFrame:SetScript("OnUpdate", nil)
    runtimeStartPending, refreshPending = false, false
    self.eventFrame:UnregisterAllEvents()
    Services.runtime:CancelAll()
    if Bridge then
        Bridge.Disable()
    end
    addon.PortalNavigation.HideSearch()
    addon.PortalNavigation.ClearSearchBuffer()
    addon.PortalReveal.Stop()
    state.isMouseOver, state.isEditModeActive = false, false
    state.pendingRefresh = false
    Services.tooltipHide()
    frame:SetAlpha(0)
    Services.runtime:Invalidate(visibilityHandle)
end

function Plugin:UpdateVisibility()
    if not frame then
        return
    end
    local hidden = not self._portalActive
        or (C_PetBattles and C_PetBattles.IsInBattle())
        or (UnitHasVehicleUI and UnitHasVehicleUI("player"))
        or not addon.PortalCombat.CanInteract()
    if Bridge then
        hidden = Bridge.UpdateVisibility(ctx, hidden)
    end
    self._portalHidden = hidden and true or false
    if not Bridge then
        frame:SetAlpha(hidden and 0 or RESTING_ALPHA)
    end
    Services.runtime:Invalidate(visibilityHandle)
end

function Plugin:ApplySettings()
    if not frame or not self._portalActive then
        return
    end
    addon.PortalNavigation.ApplySettings()
    RequestRefresh()
    addon.PortalReveal.Apply(ctx)
    self:UpdateVisibility()
end

function Plugin:AddSettings(dialog, systemFrame)
    Bridge.RenderSettings(self, dialog, systemFrame, ctx)
end

function Plugin:HandleCommand(cmd)
    addon.PortalCommands.Handle(ctx, cmd)
end
