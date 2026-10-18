local _, addon = ...
local UI = addon.LibOrbitUI
assert(UI.VERSION_MAJOR == 1 and UI.VERSION_MINOR >= 11, "Orbit Portal requires LibOrbitUI 1.11")
local Services = UI.CreateContext({
    owner = addon,
    name = "OrbitPortal",
    onDisplayChanged = function()
        if addon.PortalBoot then
            addon.PortalBoot.Apply()
        end
    end,
})
addon.PortalServices = Services

local lastOrientation = "LEFT"
local SHADOW_OFFSET = 1

function Services.DetectOrientation(frame)
    lastOrientation = addon.LibOrbitUI.Geometry:DetectOrientation(frame, lastOrientation)
    return lastOrientation
end

Services.SetFont =
    addon.LibOrbitUI.Text.CreateFontSetter(Services.pixel, "OrbitPortalFont", SHADOW_OFFSET, -SHADOW_OFFSET)

function Services.GetFontPath()
    return addon.PortalFonts.Path.UI
end

function Services.GetSearchFontPath()
    return addon.PortalFonts.Path.Chat
end

function Services.ApplyFontOverrides(region, overrides, size, path)
    Services.SetFont(region, path, size, "OUTLINE")
end

Services.ApplyTimerOverrides = Services.ApplyFontOverrides

Services.ApplyTextPosition = addon.LibOrbitUI.TextPosition.CreateSetter(Services.pixel)

function Services.ApplyTextColorOverride()
    return false
end

function Services.GetComponentPositions(plugin)
    return plugin:GetSetting(1, "ComponentPositions") or {}
end

function Services.IsComponentDisabled(plugin, key)
    for _, disabled in ipairs(plugin:GetSetting(1, "DisabledComponents") or {}) do
        if disabled == key then
            return true
        end
    end
    return false
end

function Services.Message(message)
    print("|cff80bfffOrbit Portal:|r " .. message)
end
