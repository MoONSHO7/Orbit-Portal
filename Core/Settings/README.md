# Portal settings

## Description
Defaults, the standalone `OrbitPortalDB` store, the shared settings schema and the `scan` command handler.

## Purpose
Keep one declaration of every Portal setting and one validation rule per key, whichever provider stores it.

## Implementation
`PortalDefaults.lua` declares every key, including `Position`, `Anchor`, `ComponentPositions` and the default-disabled
`DungeonShort` component; the Orbit bridge copies it into Orbit's plugin defaults and the standalone store reads it
directly. `PortalStore.lua` owns `OrbitPortalDB` (`version` 1, `profiles.default.settings`): `Initialize` returns false,
leaving the data untouched, for any store whose `version` is not 1 or whose `profiles.default.settings` shape is
missing; `Get` returns the default when the stored value fails `IsValid`, copying tables; `Set` asserts validity and
stores a copy; `Reset` wipes the profile. `PortalSchema.lua` returns the layout, behaviours and categories tabs for both
renderers: Orbit's `Bridge.RenderSettings` feeds them to `SchemaBuilder` and `Engine.Config`, and
`PortalBoot.ShowSettings` feeds them to `UI.Config.CreateDialog` after inserting the Enabled control. Component
checkboxes rewrite the `DisabledComponents` list; the categories tab is built lazily from
`PortalScanner:GetOrderedList()` counts and omits `FAVORITE` and empty categories. `PortalCommands.lua` handles `scan`:
it clears `state.mythicPlusCache`, refreshes when interaction is allowed and prints the localized result.

## Gotchas
- `NUMBER_RULES` (range and step) in `PortalStore.lua` must match the sliders in `PortalSchema.lua`; a stored value off
  the step, such as an even `MaxVisible`, reads back as the default. `Anchor` is valid only as `false` standalone:
  Orbit's anchor graph owns anchors when hosted.
- `Store:Get` and `Store:Set` assert on unknown keys and `Set` throws on invalid values. Reads are defensive copies, so
  callers copy, mutate and write the whole table back through `SetSetting`.
- `EnabledCategories` is an opt-out map (`nil` means enabled) that favorites bypass; `Favorites` keys are strings.
- `PortalLayout.ResolveFadeAmount` still accepts a legacy boolean `FadeEffect` (`true` reads as 20) from Orbit-hosted
  profiles; the standalone store rejects a boolean because its type differs from the numeric default.

## References
`../README.md`, `../../README.md`, `../Integrations/README.md` (hosted rendering),
`../../Libs/LibOrbitUI-1.0/Config/README.md` (the shared dialog and widgets), `/orbit-settings`.
