# Portal discovery

## Description
Destination discovery and the cooldown data used by Portal's display list.

## Purpose
Keep eligibility and native reads separate from display filtering, secure actions and refresh scheduling.

## Implementation
`Discovery.xml` loads player eligibility and cooldown readers before the sources. `PortalSpellSources.lua` projects
known spells. `PortalItemSources.lua` projects usable toys and owned or equipped items. `PortalHousing.lua` owns
housing requests and the last owned-house payload. `PortalScanner.lua` composes them in catalogue order for the icon
list and category settings. `../Portal.lua` owns the event-driven rebuild and the cooldown ticker, which calls
`PortalCooldowns.Refresh` on the existing display entries.

## Gotchas
- Seasonal entries take precedence over expansion entries. Keep the source-specific faction requirements and scan order.
- The random hearthstone uses the first eligible shared hearthstone for cooldown reads. Housing cooldown comes from
  the housing source on a full scan. The item and spell refresh leaves housing entries alone.
- Toy usability is Blizzard's proof for Engineering rank and specialization. Item names can arrive after discovery.

## Secrets
`PortalCooldowns.lua` checks spell and item cooldown fields before arithmetic. Restricted or missing reads return zero.

## References
`../README.md`, `../PortalData.lua`, `../View/README.md`, `../../.scripts/README.md`.
