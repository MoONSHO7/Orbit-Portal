# Orbit integration

## Description
The optional bridge that lets an installed Orbit host own Portal's settings, enablement, movement, visibility and
Canvas.

## Purpose
Keep every Orbit reference in two files behind one frozen host contract, so the rest of Portal is provider-neutral.

## Implementation
`Orbit.lua` returns at file scope unless `Orbit.Engine` exists and `Orbit.ExternalUIHost.legacyPluginVersion == 1`; when
it stays, `addon.PortalOrbit` exists and every later file selects the hosted path. `CreatePlugin` registers
`Orbit-Portal` (system `Orbit_Portal`) with copied defaults, live toggle and declared Canvas components, and the file
replaces `PortalServices`' font, override, text-position and orientation owners with Orbit's. It borrows `Orbit.Tooltip`
without changing Portal's native anchors, retaining the host's current tooltip appearance. `AttachFrame` marks the
frame `orbitNoSnap`, attaches `FramePersistence` and the orientation callback (refresh, and re-anchor while dragging),
then restores the saved position. `Enable` applies OOC fade, registers standard and visibility events and Edit Mode
callbacks (enter marks Edit Mode only when interaction is allowed, hides search and refreshes only when marked; exit
requests a refresh); `Disable` unregisters the Edit Mode callbacks. `UpdateVisibility` adds profile suppression and
mounted-hidden state through `OOCFadeService:SetLifecycleHidden`. `RenderSettings` feeds `PortalSchema` tabs to
`SchemaBuilder` and `Engine.Config:Render`. `OrbitCanvas.lua` adds `frame:CreateCanvasPreview`, a fixed-size circular
icon preview with Timer, DungeonScore and DungeonShort text components and a draggable FavouriteStar, reading
`ComponentPositions` and `IconSize`.

## Gotchas
- The bridge is chosen at load, before `PLAYER_LOGIN`: `## OptionalDeps: Orbit` guarantees order, and an Orbit without
  the marker (or with another version) leaves Portal standalone. Hosted Portal never hydrates `OrbitPortalDB`.
- Orbit's lifecycle owner is the plugin: Edit Mode callbacks register with it, and `Orbit:LiveTogglePlugin` drives
  `OnEnable`/`OnDisable`.
- The Canvas preview duplicates the icon's mask, texcoords and border geometry; change `../View/PortalIcon.lua` and
  this preview together.
- The host contract is legacy plugin v1: Orbit keeps the settings, and no external store transaction or export exists.

## References
`../README.md`, Orbit `Core/Plugin/README.md` (`ExternalUIHost`), `/canvas-mode`, `/orbit-settings`.
