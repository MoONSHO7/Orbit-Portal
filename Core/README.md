# Portal Core

## Description
The Portal controller, its refresh pipeline, standalone boot, scanner, data tables and the pure layout and decoration
helpers.

## Purpose
Own the one secure portal frame and the icon window painted onto it, whichever settings provider is active, and keep
every protected write out of combat.

## Implementation
- **Provider and context.** `Portal.lua` builds `addon.Portal` from `Integrations/Orbit.lua`'s bridge when that file
  stayed loaded, otherwise as a plain plugin whose `GetSetting`/`SetSetting` read `Settings/PortalStore.lua`.
  `addon.PortalContext` (`ctx`) is the one surface the View, Input, State and Integrations owners receive: the plugin,
  the shared paint and search `state`, the frame and its `content` child, and the controller's refresh and hover entry
  points; Input and standalone movement attach their handles when installed. `Plugin.eventFrame` is created at file load
  so the gameplay owner exists before Orbit drives the hosted lifecycle.
- **Services.** `PortalServices.lua` requires LibOrbitUI API 1.11 before creating the private context (`pixel`, `runtime`,
  `tooltip`, `tooltipHide`) with the default Orbit tooltip surface and bundled mouse hints, plus the standalone font,
  text-position and orientation owners; `onDisplayChanged` re-applies through
  Boot. The Orbit bridge replaces those owners with Orbit's before `Portal.lua` loads. `PortalFonts.lua` picks the
  locale-specific Orbit UI and Orbit UI Chat binaries at file load.
- **Lifecycle.** `OnLoad` creates `OrbitPortalFrame` (`SecureHandlerStateTemplate`, parented to `UIParent`) with its
  `content` child, installs Input and Reveal, attaches the bridge's frame and Canvas hooks and requests Mythic+ map
  data. `OnEnable` registers the gameplay events and arms the first runtime pass; `OnDisable` unregisters them, cancels
  all runtime work, hides search, reveal and tooltip, zeroes alpha and invalidates the visibility reconciler.
  `Portal.lua`'s runtime reconciler (`visibility`) installs the `[combat][petbattle][vehicleui] hide; show` state driver
  or `hide`, toggles mouse input and hides an empty frame; `UpdateVisibility` computes `_portalHidden` (the bridge adds
  profile suppression and mounted-hidden state through `OOCFadeService`), writes the resting alpha standalone, and
  invalidates the reconciler.
- **Refresh pipeline.** `RequestRefresh` coalesces requests into one debounced `Refresh` on the private runtime; the
  first pass after enable also schedules the delayed `initialScan` (housing request plus refresh) and the `cooldowns`
  ticker. `Refresh` takes `PortalScanner:GetOrderedList()`, marks favorites as display group `FAVORITE`, drops disabled
  categories and, with `HideLongCooldowns`, long cooldowns outside the current season, stable-sorts by
  `PortalData.CategoryOrder` and records each group's first index and the search fields, then calls `RepaintIcons`.
  `RepaintIcons` resolves its paint values from settings and services once per pass, paints the window of `searchFilter`
  or `portalList` around `scrollOffset` through a plain icon pool (`View/PortalIcon.lua` creates and configures,
  `PortalCanvas.lua` decorates), places each icon with `PortalLayout.lua` arc math for the detected orientation, resizes
  and clamps the frame and lets Reveal re-assert. `RefreshCooldowns` repaints only while any cooldown is or was active.
- **Scanner and data.** `PortalData.lua` declares `CategoryOrder`, localized `CategoryNames`, the current-season spell
  lists and the per-expansion dungeon/raid, hearthstone, class, mage, engineering and toy tables with faction, class and
  race requirements. `PortalScanner.lua` captures class, faction and race at file load, probes spells
  (`C_SpellBook.IsSpellKnown`), toys (`PlayerHasToy` plus `C_ToyBox.IsToyUsable`) and items (count or equipped),
  excludes seasonal spells from their expansion categories, folds raids into `RAID` and mage portals into
  `MAGE_TELEPORT`, builds one random hearthstone entry over the owned `HEARTHSTONE_SHARED` items plus individual
  entries for `HEARTHSTONE_UNIQUE`, and emits a housing entry from the cached `PLAYER_HOUSE_LIST_UPDATED` payload, the
  tracked house or level 80. `GetOrderedList` flattens by `CategoryOrder`; `RefreshCooldowns` updates entries in place.
- **Boot.** `PortalBoot.lua` hydrates the store at `ADDON_LOADED` and registers the AddOns category; at `PLAYER_LOGIN`
  the combat-gated `startup` reconciler constructs once, creates the LibOrbitUI movement overlay, then enables or
  disables per `Enabled`. `Boot.ShowSettings` builds `OrbitPortalSettings` once from `Settings/PortalSchema.lua` with an
  Enabled control and layout-tab footer actions; `onChange` routes to `Boot.Apply`. `PortalBoot.lua` also registers
  `/orbitportal` and dispatches `status`, `move` and `reset`, forwards `scan` to `Settings/PortalCommands.lua` through
  `Plugin:HandleCommand` once the store or bridge is ready, and opens settings for anything else. Under the bridge, Boot
  skips the store and the `startup` reconciler; its dialog, slash commands and footer actions route settings to the
  plugin, enablement to `Orbit:LiveTogglePlugin`, movement to Orbit's Edit Mode and reset to `Engine.FramePersistence`.

## Gotchas
- `Refresh`, `RepaintIcons` and the cooldown tick return unless active and `PortalCombat.CanInteract()`; the state
  driver, not Lua, hides the frame in combat. Every gameplay event re-requests a refresh, so the post-combat repaint
  comes from `PLAYER_REGEN_ENABLED`; `state.pendingRefresh` is written but nothing reads it.
- `initializationFailed` latches when `OnLoad` or movement creation throws: Apply, settings and reset refuse and the
  partial graph is never reconstructed. Standalone `Boot.Apply` disables immediately even in combat (alpha and timers
  only); the deferred hide completes through the reconciler after combat.
- Item names come from `C_Item.GetItemInfo`, which is nil until the item cache fills; the scanner emits a localized
  placeholder and the next refresh resolves it. `GetCooldownInfo` returns zeros for secret start or duration.
- The seasonal lists in `PortalData.lua` decide both the `SEASONAL_*` categories and the exclusion from expansion
  categories, so a listed spell never appears twice. Housing needs `C_Housing.TeleportHome`; its icon stays inert
  until a complete `houseInfo` arrives.
- Icon pooling is a plain array indexed by slot; icons are hidden and re-anchored on every repaint, never destroyed.
  Orientation is re-detected per repaint, with the previous value as fallback standalone (the Orbit bridge delegates
  to `Engine.FrameOrientation`), so a drag across the screen centre flips the arc on the next paint.
- `onDisplayChanged` re-enters through `Boot.Apply`, which under the bridge calls `ApplySettings` directly.

## Secrets
Mythic+ season bests and cooldown values may be secret: the scanner returns zero cooldowns for secret values, and
`PortalCanvas.lua` and `View/PortalTooltip.lua` cache only non-secret scores in `state.mythicPlusCache` and fall back
to that cache. Native cooldown frames receive supported values directly.

## References
`../README.md`, `Settings/README.md`, `State/README.md`, `View/README.md`, `Input/README.md`,
`Integrations/README.md`, `../.scripts/README.md` (`test-portal.py` scenarios), `/wow-secrets`. Verify in-game with
`/reload`, real secure clicks and BugSack.
