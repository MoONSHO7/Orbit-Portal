local _, addon = ...

local PLAYER_CLASS = select(2, UnitClass("player"))
local PLAYER_FACTION = UnitFactionGroup("player")
local PLAYER_RACE = select(2, UnitRace("player"))

local Eligibility = { class = PLAYER_CLASS }
addon.PortalEligibility = Eligibility

function Eligibility.MatchesFaction(data)
    return not data.faction or data.faction == PLAYER_FACTION
end

function Eligibility.MatchesClass(data)
    return not data.class or data.class == PLAYER_CLASS
end

function Eligibility.MatchesItem(data)
    return Eligibility.MatchesFaction(data)
        and Eligibility.MatchesClass(data)
        and (not data.races or data.races[PLAYER_RACE] == true)
end

table.freeze(Eligibility)
