local _, addon = ...
local Services = addon.PortalServices
local Pixel = Services.pixel

-- [ CONSTANTS ] -------------------------------------------------------------------------------------------------------
local COMPONENT_KEYS = { "DungeonScore", "DungeonShort", "FavouriteStar", "Timer" }
local DEFAULT_FONT_SIZE = 10
local DEFAULT_COOLDOWN_SIZE = 12
local DUNGEON_SCORE_DEFAULT_OY = -2
local DUNGEON_SHORT_DEFAULT_OY = 2
local STAR_DEFAULT_OX = 1
local STAR_DEFAULT_OY = 1
local STAR_SHADOW_Y_OFFSET = -2

local SCORE_COLOR_LEGENDARY = { 1.00, 0.50, 0.00 }
local SCORE_COLOR_EPIC = { 0.64, 0.21, 0.93 }
local SCORE_COLOR_RARE = { 0.00, 0.44, 0.87 }
local SCORE_COLOR_UNCOMMON = { 0.12, 1.00, 0.00 }
local SCORE_COLOR_COMMON = { 1.00, 1.00, 1.00 }

local SCORE_TIER_LEGENDARY = 300
local SCORE_TIER_EPIC = 250
local SCORE_TIER_RARE = 200
local SCORE_TIER_UNCOMMON = 100

local math_floor = math.floor
local ipairs = ipairs

local Canvas = {}
addon.PortalCanvas = Canvas

-- [ HELPERS ] ---------------------------------------------------------------------------------------------------------
local function GetDungeonScoreColor(score)
    local c
    if score >= SCORE_TIER_LEGENDARY then
        c = SCORE_COLOR_LEGENDARY
    elseif score >= SCORE_TIER_EPIC then
        c = SCORE_COLOR_EPIC
    elseif score >= SCORE_TIER_RARE then
        c = SCORE_COLOR_RARE
    elseif score >= SCORE_TIER_UNCOMMON then
        c = SCORE_COLOR_UNCOMMON
    else
        c = SCORE_COLOR_COMMON
    end
    return c[1], c[2], c[3]
end

local function GetGlobalFontPath()
    return Services.GetFontPath()
end

-- Cache only non-secret scores; a cached secret would throw at math.floor() time in combat.
local function EnsureDungeonScoreCached(challengeModeID, mythicPlusCache)
    if not C_MythicPlus or not challengeModeID then
        return
    end
    local entry = mythicPlusCache[challengeModeID]
    if entry and entry.dungeonScore then
        return
    end
    local _, score = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(challengeModeID)
    if score and not issecretvalue(score) then
        mythicPlusCache[challengeModeID] = mythicPlusCache[challengeModeID] or {}
        mythicPlusCache[challengeModeID].dungeonScore = score
    end
end

local function BuildDisabledSet(plugin)
    local disabled = {}
    for _, key in ipairs(COMPONENT_KEYS) do
        disabled[key] = Services.IsComponentDisabled(plugin, key)
    end
    return disabled
end

local function ResolveScale(pos)
    local scale = pos and pos.overrides and pos.overrides.Scale
    if type(scale) == "number" and scale > 0 then
        return scale
    end
    return 1
end

-- [ PER-COMPONENT APPLIERS ] ------------------------------------------------------------------------------------------
local function ApplyDungeonScore(icon, data, pos, disabled, cache, fontPath)
    local ApplyTextPosition = Services.ApplyTextPosition
    local eligible = not disabled.DungeonScore and data and data.category == "SEASONAL_DUNGEON" and data.challengeModeID
    if eligible then
        EnsureDungeonScoreCached(data.challengeModeID, cache)
    end
    local cacheEntry = eligible and cache[data.challengeModeID]
    if not (eligible and cacheEntry and cacheEntry.dungeonScore) then
        icon.DungeonScore:Hide()
        return
    end
    local score = cacheEntry.dungeonScore
    local overrides = pos and pos.overrides or {}
    Services.ApplyFontOverrides(icon.DungeonScore, overrides, DEFAULT_FONT_SIZE, fontPath)
    icon.DungeonScore:SetText(tostring(math_floor(score)))
    if not Services.ApplyTextColorOverride(icon.DungeonScore, overrides) then
        icon.DungeonScore:SetTextColor(GetDungeonScoreColor(score))
    end
    ApplyTextPosition(icon.DungeonScore, icon.DungeonScoreOverlay, pos, "CENTER", 0, DUNGEON_SCORE_DEFAULT_OY)
    icon.DungeonScore:Show()
end

local function ApplyDungeonShort(icon, data, pos, disabled, fontPath)
    local ApplyTextPosition = Services.ApplyTextPosition
    if disabled.DungeonShort or not (data and data.short) then
        icon.DungeonShort:Hide()
        return
    end
    local overrides = pos and pos.overrides or {}
    Services.ApplyFontOverrides(icon.DungeonShort, overrides, DEFAULT_FONT_SIZE, fontPath)
    icon.DungeonShort:SetText(data.short)
    if not Services.ApplyTextColorOverride(icon.DungeonShort, overrides) then
        icon.DungeonShort:SetTextColor(1, 1, 1)
    end
    ApplyTextPosition(icon.DungeonShort, icon.DungeonScoreOverlay, pos, "CENTER", 0, DUNGEON_SHORT_DEFAULT_OY)
    icon.DungeonShort:Show()
end

-- Disabling the timer uses SetHideCountdownNumbers so the CooldownFrameTemplate won't re-show it each tick.
local function ApplyTimer(icon, pos, disabled, fontPath)
    local ApplyTextPosition = Services.ApplyTextPosition
    if icon.cooldown and icon.cooldown.SetHideCountdownNumbers then
        icon.cooldown:SetHideCountdownNumbers(disabled.Timer == true)
    end
    if icon.cooldownText and not disabled.Timer then
        local overrides = pos and pos.overrides or {}
        local baseSize = icon.cooldownTextBaseSize or DEFAULT_COOLDOWN_SIZE
        Services.ApplyTimerOverrides(icon.cooldownText, overrides, baseSize, fontPath)
        local f, sz, flags = icon.cooldownText:GetFont()
        if f then
            icon.cooldownTextFont = f
        end
        if sz then
            icon.cooldownTextBaseSize = sz
        end
        if flags then
            icon.cooldownTextFlags = flags
        end
        ApplyTextPosition(icon.cooldownText, icon, pos, "CENTER", 0, 0)
    end
end

local function ApplyFavouriteStar(icon, pos, disabled, isFavourite)
    local ApplyTextPosition = Services.ApplyTextPosition
    if disabled.FavouriteStar or not isFavourite then
        icon.FavouriteStar:Hide()
        icon.FavouriteStarShadow:Hide()
        return
    end
    local scale = ResolveScale(pos)
    local pixelScale = icon:GetEffectiveScale()
    local starSize = Pixel:Snap(icon.favouriteStarBaseSize * scale, pixelScale)
    local shadowSize = Pixel:Snap(icon.favouriteStarShadowBaseSize * scale, pixelScale)
    icon.FavouriteStar:SetSize(starSize, starSize)
    icon.FavouriteStarShadow:SetSize(shadowSize, shadowSize)
    ApplyTextPosition(icon.FavouriteStar, icon, pos, "TOPRIGHT", STAR_DEFAULT_OX, STAR_DEFAULT_OY)
    icon.FavouriteStarShadow:ClearAllPoints()
    icon.FavouriteStarShadow:SetPoint("CENTER", icon.FavouriteStar, "CENTER", 0, STAR_SHADOW_Y_OFFSET * scale)
    icon.FavouriteStar:Show()
    icon.FavouriteStarShadow:Show()
end

-- [ PUBLIC API ] ------------------------------------------------------------------------------------------------------
function Canvas.ApplyIconComponents(icon, data, mythicPlusCache, isFavourite, paint)
    local positions = paint.positions
    local disabled = paint.disabled
    local fontPath = paint.fontPath

    ApplyDungeonScore(icon, data, positions.DungeonScore, disabled, mythicPlusCache, fontPath)
    ApplyDungeonShort(icon, data, positions.DungeonShort, disabled, fontPath)
    ApplyTimer(icon, positions.Timer, disabled, fontPath)
    ApplyFavouriteStar(icon, positions.FavouriteStar, disabled, isFavourite)
end

Canvas.DEFAULT_FONT_SIZE = DEFAULT_FONT_SIZE
Canvas.BuildDisabledSet = BuildDisabledSet
Canvas.GetGlobalFontPath = GetGlobalFontPath
Canvas.GetDungeonScoreColor = GetDungeonScoreColor
