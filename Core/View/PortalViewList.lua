local _, addon = ...
local Favorites = addon.PortalFavorites
local LONG_COOLDOWN_THRESHOLD = 1800
local UNKNOWN_CATEGORY_PRIORITY = 999

local CAT_PRIORITY = {}
for i, cat in ipairs(addon.PortalData.CategoryOrder) do
    CAT_PRIORITY[cat] = i
end

local ViewList = {}
addon.PortalViewList = ViewList

function ViewList.Build(plugin, rawList)
    for _, item in ipairs(rawList) do
        item.displayGroup = Favorites.IsFavorite(plugin, item) and "FAVORITE" or item.category
    end

    local hideLongCooldowns = plugin:GetSetting(1, "HideLongCooldowns")
    local enabledCategories = plugin:GetSetting(1, "EnabledCategories") or {}
    local portalList = {}
    for _, item in ipairs(rawList) do
        local cooldownRemaining = item.cooldown or 0
        local isCurrentSeason = item.category == "SEASONAL_DUNGEON" or item.category == "SEASONAL_RAID"
        local cooldownPass = not hideLongCooldowns or isCurrentSeason or cooldownRemaining < LONG_COOLDOWN_THRESHOLD
        local categoryPass = item.displayGroup == "FAVORITE" or enabledCategories[item.category] ~= false
        if cooldownPass and categoryPass then
            table.insert(portalList, item)
        end
    end

    local orderIndex = {}
    for i, item in ipairs(portalList) do
        orderIndex[item] = i
    end
    table.sort(portalList, function(a, b)
        local pa = CAT_PRIORITY[a.displayGroup] or UNKNOWN_CATEGORY_PRIORITY
        local pb = CAT_PRIORITY[b.displayGroup] or UNKNOWN_CATEGORY_PRIORITY
        if pa ~= pb then
            return pa < pb
        end
        return orderIndex[a] < orderIndex[b]
    end)

    local categoryNames = addon.PortalData.CategoryNames
    local firstIndexOfCategory = {}
    for i, item in ipairs(portalList) do
        local cat = item.displayGroup
        if firstIndexOfCategory[cat] == nil then
            firstIndexOfCategory[cat] = i
        end
        item.searchShort = item.short and item.short:lower() or nil
        item.searchName = item.name and item.name:lower() or nil
        item.searchInst = item.instanceName and item.instanceName:lower() or nil
        local catName = categoryNames[item.category]
        item.searchCategory = catName and catName:lower() or nil
    end
    return portalList, firstIndexOfCategory
end
