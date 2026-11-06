local _, addon = ...

local Cooldowns = {}
addon.PortalCooldowns = Cooldowns

function Cooldowns.Read(isSpell, id)
    if not id then
        return 0, 0
    end

    local startTime, duration
    if isSpell then
        local info = C_Spell.GetSpellCooldown(id)
        if info then
            startTime, duration = info.startTime, info.duration
        end
    else
        startTime, duration = C_Container.GetItemCooldown(id)
    end

    if not startTime or not duration then
        return 0, 0
    end
    if issecretvalue(startTime) or issecretvalue(duration) then
        return 0, 0
    end
    if startTime <= 0 then
        return 0, 0
    end
    local remaining = (startTime + duration) - GetTime()
    if remaining < 0 then
        remaining = 0
    end
    return remaining, duration
end

function Cooldowns.Refresh(portalList)
    for _, item in ipairs(portalList) do
        if item.type == "random_hearthstone" then
            if item.availableHearthstones and #item.availableHearthstones > 0 then
                item.cooldown, item.cooldownDuration = Cooldowns.Read(false, item.availableHearthstones[1].itemID)
            end
        else
            local isSpell = item.type == "spell"
            local id = isSpell and item.spellID or item.itemID
            if id then
                item.cooldown, item.cooldownDuration = Cooldowns.Read(isSpell, id)
            end
        end
    end
end

table.freeze(Cooldowns)
