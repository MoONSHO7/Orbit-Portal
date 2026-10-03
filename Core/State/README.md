# Portal state

## Description
Combat and encounter interaction policy, and favorite persistence.

## Purpose
Keep the interaction gate and the favorite key format in one place for the controller, view and input owners.

## Implementation
`PortalCombat.CanInteract()` is false during combat lockdown or an in-progress encounter. It gates scans, repaints (and
with them `Configure`'s attribute writes), cooldown refreshes, wheel and search input, showing search and the reveal
tween driver, and `UpdateVisibility` treats the frame as hidden while it is false. The `PreClick` hearthstone re-roll,
keyboard propagation and the reveal `Apply`/`OnRepaint` resets check only `InCombatLockdown()`, so they may still run
during an encounter out of combat. `Combat.UpdateState(ctx)` runs on regen, encounter, pet battle and vehicle events:
entering a restricted state clears edit and hover state and releases the search frame, hiding the root only for
encounter-only restrictions because the secure driver owns combat hiding; leaving it re-runs `UpdateVisibility`,
restores keyboard propagation and re-shows search when the cursor is still over the frame. `PortalFavorites` keys an
entry by `spellID`, `itemID` or `name`, stores keys as strings in the `Favorites` map, and `Toggle` writes a copy
through `plugin:SetSetting`; `Refresh` turns a favorite into display group `FAVORITE`.

## Gotchas
- Entries without a spell or item id, the random hearthstone and housing, are keyed by their localized or house name,
  so those favorites do not survive a locale or house change.
- `UpdateState` hides the frame directly only when `InCombatLockdown()` is false; in combat it must leave the secure
  frame to its state driver.

## References
`../README.md`, `../View/README.md` (right-click toggle), `../Input/README.md` (search release).
