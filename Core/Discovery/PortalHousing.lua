local _, addon = ...
local L = addon.L
local MIN_LEVEL_FOR_HOUSING = 80
local Housing = {}
addon.PortalHousing = Housing

local cachedHouseList

function Housing:Scan()
    local results = {}

    if not C_Housing or not C_Housing.TeleportHome then
        return results
    end

    local hasHouse = false
    local houseInfo = nil
    local displayName = L.PLU_PORTAL_HOUSING_TELEPORT
    local neighborhoodName = nil

    if cachedHouseList and #cachedHouseList > 0 then
        hasHouse = true
        houseInfo = cachedHouseList[1]
        displayName = houseInfo.houseName or houseInfo.neighborhoodName or L.PLU_PORTAL_HOUSING_MY_PLOT
        neighborhoodName = houseInfo.neighborhoodName
    end

    if not hasHouse and C_Housing.GetTrackedHouseGuid then
        local trackedGuid = C_Housing.GetTrackedHouseGuid()
        if trackedGuid then
            hasHouse = true
            displayName = L.PLU_PORTAL_HOUSING_MY_PLOT
        end
    end

    if not hasHouse then
        local level = UnitLevel("player")
        if level and level >= MIN_LEVEL_FOR_HOUSING then
            hasHouse = true
            displayName = L.PLU_PORTAL_HOUSING_TELEPORT
        end
    end

    if not hasHouse then
        return results
    end

    local cooldown, cooldownDuration = 0, 0
    local cdInfo = C_Housing.GetVisitCooldownInfo and C_Housing.GetVisitCooldownInfo()
    if cdInfo and cdInfo.startTime and cdInfo.duration then
        cooldown = math.max(0, (cdInfo.startTime + cdInfo.duration) - GetTime())
        cooldownDuration = cdInfo.duration
    end

    table.insert(results, {
        type = "housing",
        name = displayName,
        instanceName = neighborhoodName,
        short = L.PLU_PORTAL_HOUSING_SHORT,
        iconAtlas = "dashboard-panel-homestone-teleport-button",
        cooldown = cooldown,
        cooldownDuration = cooldownDuration,
        category = "HOUSING",
        houseInfo = houseInfo,
    })

    return results
end

function Housing:SetOwnedHouses(houseInfos)
    cachedHouseList = houseInfos
end

function Housing:RequestOwnedHouses()
    if C_Housing and C_Housing.GetPlayerOwnedHouses then
        C_Housing.GetPlayerOwnedHouses()
    end
end
