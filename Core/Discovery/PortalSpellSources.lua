local _, addon = ...

local Data = addon.PortalData
local Eligibility = addon.PortalEligibility
local Cooldowns = addon.PortalCooldowns

local Spells = {}
addon.PortalSpellSources = Spells

local function KnownSpellEntry(spellID, category)
    if not C_SpellBook.IsSpellKnown(spellID) then
        return
    end
    local info = C_Spell.GetSpellInfo(spellID)
    if not info then
        return
    end
    local name, icon = info.name, info.iconID
    if not name then
        return
    end
    local cooldown, cooldownDuration = Cooldowns.Read(true, spellID)
    return {
        type = "spell",
        spellID = spellID,
        name = name,
        icon = icon,
        cooldown = cooldown,
        cooldownDuration = cooldownDuration,
        category = category,
    }
end

local function AppendDungeon(results, data, category)
    local entry = KnownSpellEntry(data.spellID, category)
    if entry then
        entry.instanceName, entry.short, entry.challengeModeID = data.name, data.short, data.challengeModeID
        results[#results + 1] = entry
    end
end

function Spells.ScanDungeonCategory(categoryData, category)
    local results = {}
    for _, data in ipairs(categoryData or {}) do
        if Eligibility.MatchesFaction(data) then
            AppendDungeon(results, data, category)
        end
    end
    return results
end

function Spells.ScanSeasonalDungeons()
    local results, seasonalSpells = {}, {}
    for _, spellID in ipairs(Data.CURRENT_SEASON_DUNGEONS) do
        seasonalSpells[spellID] = true
    end
    local dungeonCategories = {
        Data.MIDNIGHT_DUNGEON,
        Data.TWW_DUNGEON,
        Data.DF_DUNGEON,
        Data.SL_DUNGEON,
        Data.BFA_DUNGEON,
        Data.LEGION_DUNGEON,
        Data.WOD_DUNGEON,
        Data.WOTLK_DUNGEON,
        Data.MOP_DUNGEON,
        Data.CATA_DUNGEON,
        Data.CLASSIC_DUNGEON,
    }
    for _, categoryData in ipairs(dungeonCategories) do
        for _, data in ipairs(categoryData or {}) do
            if seasonalSpells[data.spellID] and Eligibility.MatchesFaction(data) then
                AppendDungeon(results, data, "SEASONAL_DUNGEON")
            end
        end
    end
    return results
end

function Spells.ScanSeasonalRaids()
    local results, seasonalSpells = {}, {}
    for _, spellID in ipairs(Data.CURRENT_SEASON_RAIDS) do
        seasonalSpells[spellID] = true
    end
    local raidCategories = { Data.MIDNIGHT_RAID, Data.TWW_RAID, Data.DF_RAID, Data.SL_RAID }
    for _, categoryData in ipairs(raidCategories) do
        for _, data in ipairs(categoryData or {}) do
            if seasonalSpells[data.spellID] then
                local entry = KnownSpellEntry(data.spellID, "SEASONAL_RAID")
                if entry then
                    entry.instanceName, entry.short = data.name, data.short
                    results[#results + 1] = entry
                end
            end
        end
    end
    return results
end

function Spells.ScanClassSpells()
    local results = {}
    for _, data in ipairs(Data.CLASS or {}) do
        if Eligibility.MatchesClass(data) then
            local entry = KnownSpellEntry(data.spellID, "CLASS")
            if entry then
                results[#results + 1] = entry
            end
        end
    end
    return results
end

local function AppendMageSpells(results, categoryData, isPortal)
    for _, data in ipairs(categoryData or {}) do
        if Eligibility.MatchesFaction(data) then
            local entry = KnownSpellEntry(data.spellID, "MAGE_TELEPORT")
            if entry then
                entry.isPortal = isPortal
                results[#results + 1] = entry
            end
        end
    end
end

function Spells.ScanMageTravel()
    local results = {}
    if Eligibility.class == "MAGE" then
        AppendMageSpells(results, Data.MAGE_TELEPORT)
        AppendMageSpells(results, Data.MAGE_PORTAL, true)
    end
    return results
end

table.freeze(Spells)
