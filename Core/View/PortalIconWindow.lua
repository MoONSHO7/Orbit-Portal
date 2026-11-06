local _, addon = ...
local Services = addon.PortalServices
local Pixel = Services.pixel
local CLAMP_VISIBLE_MARGIN = 30
local FRAME_THICKNESS_PAD = 2
local math_max, math_min, math_floor = math.max, math.min, math.floor
local wipe = wipe
local ipairs = ipairs

local IconWindow = {}
addon.PortalIconWindow = IconWindow

local iconPool

local function PositionIconForOrientation(icon, portalFrame, arcOffset, centerPos, iconSize, orientation)
    icon:ClearAllPoints()
    local halfIcon = iconSize / 2
    local scale = icon:GetEffectiveScale()
    local w, h = icon:GetSize()
    if orientation == "LEFT" then
        local x, y = Pixel:SnapPosition(halfIcon + arcOffset, -centerPos, "CENTER", w, h, scale)
        icon:SetPoint("CENTER", portalFrame, "TOPLEFT", x, y)
    elseif orientation == "RIGHT" then
        local x, y = Pixel:SnapPosition(-halfIcon - arcOffset, -centerPos, "CENTER", w, h, scale)
        icon:SetPoint("CENTER", portalFrame, "TOPRIGHT", x, y)
    elseif orientation == "TOP" then
        local x, y = Pixel:SnapPosition(centerPos, -halfIcon - arcOffset, "CENTER", w, h, scale)
        icon:SetPoint("CENTER", portalFrame, "TOPLEFT", x, y)
    else
        local x, y = Pixel:SnapPosition(centerPos, halfIcon + arcOffset, "CENTER", w, h, scale)
        icon:SetPoint("CENTER", portalFrame, "BOTTOMLEFT", x, y)
    end
end

function IconWindow.Repaint(ctx)
    local frame, plugin, state = ctx.frame, ctx.plugin, ctx.state
    local Combat = addon.PortalCombat
    if not frame or not plugin._portalActive or not Combat.CanInteract() then
        return
    end

    local Layout = addon.PortalLayout
    local IconModule = addon.PortalIcon
    local Canvas = addon.PortalCanvas

    for _, icon in ipairs(state.visibleIcons) do
        icon:Hide()
        icon:ClearAllPoints()
    end
    wipe(state.visibleIcons)

    local totalItems = state.portalList and #state.portalList or 0
    if totalItems == 0 then
        frame:Hide()
        return
    end

    local authoredIconSize = plugin:GetSetting(1, "IconSize")
    local authoredSpacing = plugin:GetSetting(1, "Spacing")
    local maxVisible = plugin:GetSetting(1, "MaxVisible")
    local frameScale = frame:GetEffectiveScale()
    local iconSize = Pixel:Snap(authoredIconSize, frameScale)
    local spacing = authoredSpacing == 0 and 0 or Pixel:Multiple(authoredSpacing, frameScale)

    local orientation = Services.DetectOrientation(frame)
    maxVisible = Layout.NormalizeMaxVisible(maxVisible, totalItems)
    local compactness = plugin:GetSetting(1, "Compactness") / 100
    local iconPoolIndex = 0

    local paint = {
        iconSize = iconSize,
        maxVisible = maxVisible,
        fadeAmount = Layout.ResolveFadeAmount(plugin:GetSetting(1, "FadeEffect")),
        fontPath = Canvas.GetGlobalFontPath(),
        positions = Services.GetComponentPositions(plugin),
        disabled = Canvas.BuildDisabledSet(plugin),
    }

    local animate = state.animatePaint
    state.animatePaint = nil

    local renderList = (state.searchFilter and #state.searchFilter > 0) and state.searchFilter or state.portalList
    local renderCount = #renderList
    local shown = math_min(renderCount, maxVisible)
    local startSlot = math_floor((maxVisible - shown) / 2)
    local windowStart = state.scrollOffset % renderCount

    for k = 0, shown - 1 do
        iconPoolIndex = iconPoolIndex + 1

        local displayIndex = startSlot + k
        local actualIndex = ((windowStart + k) % renderCount) + 1
        local data = renderList[actualIndex]

        if data then
            if not iconPool then
                iconPool = {}
            end
            local icon = iconPool[iconPoolIndex]
            if not icon then
                icon = IconModule.Create(ctx)
                table.insert(iconPool, icon)
            end

            IconModule.Configure(ctx, icon, data, displayIndex, paint)
            Canvas.ApplyIconComponents(icon, data, state.mythicPlusCache, data.displayGroup == "FAVORITE", paint)

            local axialPos, arcOffset =
                Layout.CalculatePosition(displayIndex, maxVisible, iconSize, spacing, compactness)
            icon.stableCenterPos = axialPos
            PositionIconForOrientation(icon, frame.content, arcOffset, axialPos, iconSize, orientation)

            if animate then
                IconModule.PlayAppear(icon)
            end
            table.insert(state.visibleIcons, icon)
        end
    end

    local frameLength = math_max(Layout.CalculateAxialExtent(maxVisible, iconSize, spacing, compactness), iconSize)
    local perpExtent = Layout.CalculatePerpExtent(maxVisible, iconSize, spacing, compactness)
    local frameThickness = iconSize + perpExtent + Pixel:Multiple(FRAME_THICKNESS_PAD, frameScale)

    if orientation == "TOP" or orientation == "BOTTOM" then
        frame:SetWidth(frameLength)
        frame:SetHeight(frameThickness)
    else
        frame:SetWidth(frameThickness)
        frame:SetHeight(frameLength)
    end

    local marginX = math_max(0, frame:GetWidth() - CLAMP_VISIBLE_MARGIN)
    local marginY = math_max(0, frame:GetHeight() - CLAMP_VISIBLE_MARGIN)
    frame:SetClampRectInsets(marginX, -marginX, -marginY, marginY)

    if not plugin._portalHidden then
        frame:Show()
    end
    addon.PortalReveal.OnRepaint(ctx)
end
