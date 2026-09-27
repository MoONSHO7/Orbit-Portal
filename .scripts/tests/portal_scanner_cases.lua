local scenario = ...
local PD = addon.PortalData
local Scanner = addon.PortalScanner
local state = portalScannerTest

local function Check(condition, message)
    assert(condition, message)
end

local function FindByItemID(list, itemID)
    for _, data in ipairs(list or {}) do
        if data.itemID == itemID then
            return data
        end
    end
end

local function FindBySpellID(list, spellID)
    for _, data in ipairs(list or {}) do
        if data.spellID == spellID then
            return data
        end
    end
end

local function ResultsContain(results, itemID)
    return FindByItemID(results, itemID) ~= nil
end

local function HearthstonePoolContains(results, itemID)
    for _, result in ipairs(results) do
        if FindByItemID(result.availableHearthstones, itemID) then
            return true
        end
    end
    return false
end

local function CheckDataContracts()
    local hologem = FindByItemID(PD.HEARTHSTONE_SHARED, 210455)
    Check(hologem and hologem.type == "toy", "Draenic Hologem remains a toy")
    Check(
        hologem.races and hologem.races.Draenei and hologem.races.LightforgedDraenei,
        "Draenic Hologem retains both allowed races"
    )

    local nature = FindByItemID(PD.TOY, 136849)
    local ravenholdt = FindByItemID(PD.TOY, 139590)
    local gear = FindByItemID(PD.TOY, 168862)
    Check(nature and nature.class == "DRUID", "Nature's Beacon remains Druid-only")
    Check(ravenholdt and ravenholdt.type == "item" and ravenholdt.class == "ROGUE", "Ravenholdt remains a Rogue item")
    Check(gear and gear.type == "item" and gear.races and gear.races.Gnome, "G.E.A.R. remains a Gnome item")

    for _, itemID in ipairs({ 141605, 18986, 18984, 30544, 30542 }) do
        local list = itemID == 141605 and PD.HEARTHSTONE_UNIQUE or PD.ENGINEER
        local data = FindByItemID(list, itemID)
        Check(data and data.type == "toy", "corrected toy type: " .. itemID)
    end

    for _, itemID in ipairs({ 103678, 128353, 129276, 118662, 118663, 119183, 139590, 140493, 168862, 180817, 202046 }) do
        local data = FindByItemID(PD.TOY, itemID)
        Check(data and data.type == "item", "corrected item type: " .. itemID)
    end
    Check(not FindByItemID(PD.TOY, 152964), "Krokul Flute is not scanned as a portal")
    Check(not FindBySpellID(PD.TWW_DUNGEON, 467546), "unreleased Waterworks spell is not scanned")

    local boots = FindByItemID(PD.TOY, 50287)
    Check(boots and not boots.reqSkillLine and not boots.reqSkill, "Boots of the Bay has no stale Fishing gate")

    for _, data in ipairs(PD.ENGINEER) do
        Check(
            not data.reqSkillLine and not data.reqSkill and not data.reqSpellID,
            "Engineering eligibility stays with native item and toy APIs: " .. data.itemID
        )
    end

    local kulTiras = FindByItemID(PD.ENGINEER, 168807)
    local zandalar = FindByItemID(PD.ENGINEER, 168808)
    Check(kulTiras and zandalar and not kulTiras.faction and not zandalar.faction, "BfA wormholes have no faction gate")

    local mechagon = FindByItemID(PD.ENGINEER, 167075)
    Check(mechagon and mechagon.type == "item", "Mechagon transporter remains an item")
    Check(not mechagon.faction, "Mechagon transporter has no faction requirement")
end

local function MakeRestrictedItemsAvailable()
    state.ownedToys[210455] = true
    state.usableToys[210455] = true
    state.ownedToys[136849] = true
    state.usableToys[136849] = true
    state.itemCounts[139590] = 1
    state.itemCounts[168862] = 1
end

local function CheckIdentityRestrictions()
    MakeRestrictedItemsAvailable()
    local hearthstones = Scanner:ScanHearthstones()
    local toys = Scanner:ScanToys()

    if scenario == "scanner_human_mage" then
        Check(not HearthstonePoolContains(hearthstones, 210455), "Human cannot use Draenic Hologem")
        Check(not ResultsContain(toys, 136849), "Mage cannot use Nature's Beacon")
        Check(not ResultsContain(toys, 139590), "Mage cannot use Ravenholdt scroll")
        Check(not ResultsContain(toys, 168862), "Human cannot use G.E.A.R. beacon")
    elseif scenario == "scanner_draenei_mage" then
        Check(HearthstonePoolContains(hearthstones, 210455), "Draenei can use Draenic Hologem")
        Check(not ResultsContain(toys, 136849), "Draenei Mage cannot use Nature's Beacon")
        Check(not ResultsContain(toys, 139590), "Draenei Mage cannot use Ravenholdt scroll")
        Check(not ResultsContain(toys, 168862), "Draenei cannot use G.E.A.R. beacon")
    elseif scenario == "scanner_lightforged_draenei" then
        Check(HearthstonePoolContains(hearthstones, 210455), "Lightforged Draenei can use Draenic Hologem")
        Check(not ResultsContain(toys, 136849), "Paladin cannot use Nature's Beacon")
        Check(not ResultsContain(toys, 139590), "Paladin cannot use Ravenholdt scroll")
        Check(not ResultsContain(toys, 168862), "Lightforged Draenei cannot use G.E.A.R. beacon")
    elseif scenario == "scanner_nightelf_druid" then
        Check(not HearthstonePoolContains(hearthstones, 210455), "Night Elf cannot use Draenic Hologem")
        Check(ResultsContain(toys, 136849), "Druid can use Nature's Beacon")
        Check(not ResultsContain(toys, 139590), "Druid cannot use Ravenholdt scroll")
        Check(not ResultsContain(toys, 168862), "Night Elf cannot use G.E.A.R. beacon")
    elseif scenario == "scanner_gnome_rogue" then
        Check(not HearthstonePoolContains(hearthstones, 210455), "Gnome cannot use Draenic Hologem")
        Check(not ResultsContain(toys, 136849), "Rogue cannot use Nature's Beacon")
        Check(ResultsContain(toys, 139590), "Rogue can use Ravenholdt scroll")
        Check(ResultsContain(toys, 168862), "Gnome can use G.E.A.R. beacon")

        state.itemCounts[139590] = 0
        toys = Scanner:ScanToys()
        Check(not ResultsContain(toys, 139590), "missing Ravenholdt scroll is excluded")
        Check(ResultsContain(toys, 168862), "one missing item does not suppress another")

        state.itemCounts[139590] = 1
        state.itemCounts[168862] = 0
        state.equippedItems[50287] = true
        toys = Scanner:ScanToys()
        Check(ResultsContain(toys, 139590), "owned Ravenholdt scroll returns")
        Check(not ResultsContain(toys, 168862), "missing G.E.A.R. beacon is excluded")
        Check(ResultsContain(toys, 50287), "equipped teleport gear remains available")
    end
end

local function CheckEngineeringRequirements()
    state.itemCounts[167075] = 1
    local results = Scanner:ScanEngineeringSpells()
    Check(ResultsContain(results, 167075), "Mechagon transporter works without Engineering")

    state.itemCounts[167075] = 0
    results = Scanner:ScanEngineeringSpells()
    Check(not ResultsContain(results, 167075), "Mechagon transporter still requires ownership")

    local engineeringToys = {
        18986,
        18984,
        30544,
        30542,
        48933,
        87215,
        112059,
        151652,
        168807,
        168808,
        172924,
        198156,
        221966,
        248485,
    }
    for _, itemID in ipairs(engineeringToys) do
        state.ownedToys[itemID] = true
        results = Scanner:ScanEngineeringSpells()
        Check(not ResultsContain(results, itemID), "native-unusable Engineering toy is excluded: " .. itemID)
        state.usableToys[itemID] = true
        results = Scanner:ScanEngineeringSpells()
        Check(ResultsContain(results, itemID), "native-usable Engineering toy is included: " .. itemID)
        state.usableToys[itemID] = false
    end
end

if scenario == "scanner_human_mage" then
    CheckDataContracts()
end
if scenario == "scanner_engineer" then
    CheckEngineeringRequirements()
else
    CheckIdentityRestrictions()
end
