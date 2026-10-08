local _, addon = ...
local L = addon.L
local Schema = {}
addon.PortalSchema = Schema

local function Slider(key, label, minimum, maximum, step, formatter)
    return {
        type = "slider",
        key = key,
        label = label,
        min = minimum,
        max = maximum,
        step = step,
        default = addon.PortalDefaults[key],
        formatter = formatter,
    }
end

local function ComponentControl(plugin, ctx, key, label)
    local function SetShown(shown)
        local values = {}
        for _, disabled in ipairs(plugin:GetSetting(1, "DisabledComponents")) do
            if disabled ~= key then
                values[#values + 1] = disabled
            end
        end
        if not shown then
            values[#values + 1] = key
        end
        plugin:SetSetting(1, "DisabledComponents", values)
    end
    return {
        type = "checkbox",
        label = label,
        default = key ~= "DungeonShort",
        onReset = function()
            SetShown(key ~= "DungeonShort")
        end,
        getValue = function()
            for _, disabled in ipairs(plugin:GetSetting(1, "DisabledComponents")) do
                if disabled == key then
                    return false
                end
            end
            return true
        end,
        onChange = function(shown)
            SetShown(shown)
            ctx.RequestRefresh()
        end,
    }
end

function Schema.Tabs(plugin, ctx)
    return {
        {
            id = "layout",
            label = L.CFG_SETTINGS_TAB_LAYOUT,
            scopeText = L.CFG_SETTINGS_SCOPE_LAYOUT,
            controls = {
                Slider("IconSize", L.CMN_ICON_SIZE, 24, 40, 2),
                Slider("Spacing", L.PLU_PORTAL_ICON_PADDING, 0, 50, 1, function(v)
                    return v .. "px"
                end),
                Slider("MaxVisible", L.PLU_PORTAL_MAX_VISIBLE, 3, 21, 2),
                Slider("Compactness", L.PLU_PORTAL_CURVE, 0, 100, 1),
            },
        },
        {
            id = "appearance",
            label = L.CFG_SETTINGS_TAB_APPEARANCE,
            scopeText = L.CFG_SETTINGS_SCOPE_LAYOUT,
            controls = {
                ComponentControl(plugin, ctx, "DungeonScore", L.PLU_PORTAL_RATING),
                ComponentControl(plugin, ctx, "DungeonShort", L.PLU_PORTAL_SHORT_LABEL),
                ComponentControl(plugin, ctx, "FavouriteStar", L.PLU_PORTAL_FAVORITE_MARKER),
                ComponentControl(plugin, ctx, "Timer", L.PLU_PORTAL_TIMER),
                {
                    type = "dropdown",
                    key = "Animation",
                    label = L.PLU_PORTAL_ANIMATION,
                    default = addon.PortalDefaults.Animation,
                    options = {
                        { text = L.PLU_PORTAL_FADE_OFF, value = 0 },
                        { text = L.PLU_PORTAL_ANIM_SLIDE, value = 1 },
                        { text = L.PLU_PORTAL_ANIM_FADE, value = 2 },
                    },
                },
            },
        },
        {
            id = "behaviours",
            label = L.CFG_SETTINGS_TAB_BEHAVIOUR,
            scopeText = L.CFG_SETTINGS_SCOPE_LAYOUT,
            controls = {
                {
                    type = "checkbox",
                    key = "HideLongCooldowns",
                    label = L.PLU_PORTAL_SHOW_LONG_CD,
                    getValue = function()
                        return not plugin:GetSetting(1, "HideLongCooldowns")
                    end,
                    onChange = function(value)
                        plugin:SetSetting(1, "HideLongCooldowns", not value)
                        ctx.RequestRefresh()
                    end,
                },
                Slider("FadeEffect", L.PLU_PORTAL_FADE_EFFECT, 0, 100, 5, function(v)
                    return v == 0 and L.PLU_PORTAL_FADE_OFF or L.PLU_PORTAL_FADE_PCT_F:format(v)
                end),
                {
                    type = "checkbox",
                    key = "EnableKeyboardSearch",
                    label = L.PLU_PORTAL_ENABLE_KEYBOARD_SEARCH,
                    default = addon.PortalDefaults.EnableKeyboardSearch,
                },
            },
        },
        {
            id = "categories",
            label = L.PLU_PORTAL_TAB_CATEGORIES,
            scopeText = L.CFG_SETTINGS_SCOPE_LAYOUT,
            controls = function()
                local controls, counts = {}, {}
                for _, item in ipairs(addon.PortalScanner:GetOrderedList()) do
                    counts[item.category] = (counts[item.category] or 0) + 1
                end
                for _, category in ipairs(addon.PortalData.CategoryOrder) do
                    local key, count = category, counts[category] or 0
                    if key ~= "FAVORITE" and count > 0 then
                        controls[#controls + 1] = {
                            type = "checkbox",
                            label = addon.PortalData.CategoryNames[key],
                            default = true,
                            valueText = tostring(count),
                            onReset = function()
                                local enabled = CopyTable(plugin:GetSetting(1, "EnabledCategories"))
                                enabled[key] = nil
                                plugin:SetSetting(1, "EnabledCategories", enabled)
                            end,
                            getValue = function()
                                return plugin:GetSetting(1, "EnabledCategories")[key] ~= false
                            end,
                            onChange = function(value)
                                local enabled = CopyTable(plugin:GetSetting(1, "EnabledCategories"))
                                enabled[key] = value
                                plugin:SetSetting(1, "EnabledCategories", enabled)
                                ctx.RequestRefresh()
                            end,
                        }
                    end
                end
                return controls
            end,
        },
    }
end
