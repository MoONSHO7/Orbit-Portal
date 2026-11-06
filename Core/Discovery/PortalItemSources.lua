local _, addon = ...

local L = addon.L
local Data = addon.PortalData
local Eligibility = addon.PortalEligibility
local Cooldowns = addon.PortalCooldowns
local HEARTHSTONE_ITEM_ID = 6948
local HEARTHSTONE_ICON_FALLBACK = 134414

local Items = {}
addon.PortalItemSources = Items

local function IsToyUsable(itemID)
    if not PlayerHasToy(itemID) then
        return false
    end
    return C_ToyBox.IsToyUsable(itemID)
end

-- GetItemCount excludes worn gear, so equipped teleport rings, cloaks, and tabards need a separate ownership check.
local function HasItem(itemID)
    return C_Item.GetItemCount(itemID) > 0 or C_Item.IsEquippedItem(itemID)
end

-- GetItemInfo returns nil until the item cache populates; the placeholder resolves on the next refresh.
local function GetItemDetails(itemID)
    local _, _, _, _, icon = C_Item.GetItemInfoInstant(itemID)
    local name = C_Item.GetItemInfo(itemID) or L.PLU_PORTAL_ITEM_FALLBACK_F:format(itemID)
    return name, icon
end

local function ProbeItemAvailability(data)
    if not Eligibility.MatchesItem(data) then
        return false
    end

    local available = false
    local name, icon
    local itemType = data.type or "toy"
    if itemType == "toy" then
        available = IsToyUsable(data.itemID)
        if available then
            name, icon = GetItemDetails(data.itemID)
        end
    elseif itemType == "item" then
        available = HasItem(data.itemID)
        if available then
            name, icon = GetItemDetails(data.itemID)
        end
    end
    return available, name, icon
end

function Items.ScanHearthstones()
    local results = {}
    local allAvailable = {}

    for _, data in ipairs(Data.HEARTHSTONE_SHARED or {}) do
        local available, name, icon = ProbeItemAvailability(data)

        if available and name then
            table.insert(allAvailable, {
                type = data.type == "toy" and "toy" or "item",
                itemID = data.itemID,
                name = name or data.name,
                icon = icon,
            })
        end
    end

    if #allAvailable > 0 then
        local cooldown, cooldownDuration = Cooldowns.Read(false, allAvailable[1].itemID)
        local _, _, _, _, hearthIcon = C_Item.GetItemInfoInstant(HEARTHSTONE_ITEM_ID)
        table.insert(results, {
            type = "random_hearthstone",
            name = L.PLU_PORTAL_HEARTHSTONE,
            short = L.PLU_PORTAL_HEARTHSTONE_SHORT,
            icon = hearthIcon or HEARTHSTONE_ICON_FALLBACK,
            cooldown = cooldown,
            cooldownDuration = cooldownDuration,
            category = "HEARTHSTONE",
            availableHearthstones = allAvailable,
        })
    end

    for _, data in ipairs(Data.HEARTHSTONE_UNIQUE or {}) do
        local available, name, icon = ProbeItemAvailability(data)

        if available then
            local cooldown, cooldownDuration = Cooldowns.Read(false, data.itemID)
            table.insert(results, {
                type = data.type,
                itemID = data.itemID,
                name = name or data.name,
                icon = icon,
                cooldown = cooldown,
                cooldownDuration = cooldownDuration,
                category = "HEARTHSTONE",
            })
        end
    end

    return results
end

-- ToyBox owns Engineering rank and specialization checks before the Professions UI initializes.
function Items.ScanCategory(categoryData, category)
    local results = {}
    for _, data in ipairs(categoryData or {}) do
        local available, name, icon = ProbeItemAvailability(data)
        if available and name then
            local cooldown, cooldownDuration = Cooldowns.Read(false, data.itemID)
            local entry = {
                type = data.type or "toy",
                itemID = data.itemID,
                name = name or data.name,
                icon = icon,
                cooldown = cooldown,
                cooldownDuration = cooldownDuration,
                category = category,
            }
            if category == "TOY" then
                entry.destination = data.destination
            end
            results[#results + 1] = entry
        end
    end
    return results
end

table.freeze(Items)
