local _, addon = ...

local PD = addon.PortalData
local Housing = addon.PortalHousing
local Spells = addon.PortalSpellSources
local Items = addon.PortalItemSources

local Scanner = {}
addon.PortalScanner = Scanner

function Scanner:ScanAll()
    local allPortals = {}

    allPortals.SEASONAL_DUNGEON = Spells.ScanSeasonalDungeons()
    allPortals.SEASONAL_RAID = Spells.ScanSeasonalRaids()
    allPortals.HEARTHSTONE = Items.ScanHearthstones()
    allPortals.HOUSING = Housing:Scan()
    allPortals.CLASS = Spells.ScanClassSpells()

    allPortals.MAGE_TELEPORT = Spells.ScanMageTravel()

    local seasonalSpells = {}
    for _, spellID in ipairs(PD.CURRENT_SEASON_DUNGEONS) do
        seasonalSpells[spellID] = true
    end
    for _, spellID in ipairs(PD.CURRENT_SEASON_RAIDS) do
        seasonalSpells[spellID] = true
    end

    local function filterSeasonal(results)
        local filtered = {}
        for _, item in ipairs(results) do
            if not seasonalSpells[item.spellID] then
                table.insert(filtered, item)
            end
        end
        return filtered
    end

    allPortals.MIDNIGHT_DUNGEON = filterSeasonal(Spells.ScanDungeonCategory(PD.MIDNIGHT_DUNGEON, "MIDNIGHT_DUNGEON"))
    allPortals.TWW_DUNGEON = filterSeasonal(Spells.ScanDungeonCategory(PD.TWW_DUNGEON, "TWW_DUNGEON"))
    allPortals.DF_DUNGEON = filterSeasonal(Spells.ScanDungeonCategory(PD.DF_DUNGEON, "DF_DUNGEON"))
    allPortals.SL_DUNGEON = filterSeasonal(Spells.ScanDungeonCategory(PD.SL_DUNGEON, "SL_DUNGEON"))
    allPortals.BFA_DUNGEON = filterSeasonal(Spells.ScanDungeonCategory(PD.BFA_DUNGEON, "BFA_DUNGEON"))

    allPortals.RAID = {}
    local function appendRaids(rawRaids)
        for _, item in ipairs(filterSeasonal(rawRaids)) do
            item.category = "RAID"
            table.insert(allPortals.RAID, item)
        end
    end
    appendRaids(Spells.ScanDungeonCategory(PD.MIDNIGHT_RAID, "RAID"))
    appendRaids(Spells.ScanDungeonCategory(PD.TWW_RAID, "RAID"))
    appendRaids(Spells.ScanDungeonCategory(PD.DF_RAID, "RAID"))
    appendRaids(Spells.ScanDungeonCategory(PD.SL_RAID, "RAID"))
    allPortals.LEGION_DUNGEON = filterSeasonal(Spells.ScanDungeonCategory(PD.LEGION_DUNGEON, "LEGION_DUNGEON"))
    allPortals.WOD_DUNGEON = filterSeasonal(Spells.ScanDungeonCategory(PD.WOD_DUNGEON, "WOD_DUNGEON"))
    allPortals.WOTLK_DUNGEON = filterSeasonal(Spells.ScanDungeonCategory(PD.WOTLK_DUNGEON, "WOTLK_DUNGEON"))
    allPortals.MOP_DUNGEON = filterSeasonal(Spells.ScanDungeonCategory(PD.MOP_DUNGEON, "MOP_DUNGEON"))
    allPortals.CATA_DUNGEON = filterSeasonal(Spells.ScanDungeonCategory(PD.CATA_DUNGEON, "CATA_DUNGEON"))
    allPortals.CLASSIC_DUNGEON = filterSeasonal(Spells.ScanDungeonCategory(PD.CLASSIC_DUNGEON, "CLASSIC_DUNGEON"))

    allPortals.ENGINEER = Items.ScanCategory(PD.ENGINEER, "ENGINEER")
    allPortals.TOY = Items.ScanCategory(PD.TOY, "TOY")

    return allPortals
end

function Scanner:GetOrderedList()
    local allByCategory = self:ScanAll()
    local ordered = {}

    for _, category in ipairs(PD.CategoryOrder) do
        local items = allByCategory[category]
        if items and #items > 0 then
            for _, item in ipairs(items) do
                item.category = category
                table.insert(ordered, item)
            end
        end
    end

    return ordered
end
