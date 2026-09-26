# Portal assets

## Description
Private interface fonts bundled for Portal's standalone runtime.

## Purpose
Keep Portal typography identical with or without Orbit installed.

## Implementation
`Fonts/` contains Orbit UI for portal labels and Orbit UI Chat for keyboard search. Each face has Western/Cyrillic, Korean, Simplified Chinese and Traditional Chinese binaries; `Core/PortalFonts.lua` selects one at load time. The `licenses/` folder carries the OFL notices for every combined source family.

## Gotchas
These fonts remain private and are never registered with LibSharedMedia. Newly installed loose font files can require a full client restart before WoW will load them.

## References
`../Core/PortalFonts.lua`, `../Core/PortalServices.lua`, `../Core/Input/PortalNavigation.lua`.
