# Orbit: Portal

## Description
A portal launcher for Retail with arc layout, hover reveal, favorites, category navigation and keyboard search. It
runs independently or attaches to an installed Orbit host; `Orbit_Portal` embeds LibOrbitUI and owns `OrbitPortalDB`.

## Purpose
Prove that the shared movement and settings UI can serve both Orbit and standalone products while retaining Portal's
travel behavior. This is the standalone library pilot, not the completed migration/export release.

## Implementation
`Orbit_Portal.toc` loads the embedded library and `Localization/` first, then `Core/` in dependency order: settings
defaults and store, fonts and the private LibOrbitUI context, the optional Orbit bridge, data, pure layout and
decoration helpers, the scanner, state, view, input, schema and commands, and last the Canvas bridge, the controller
and standalone boot. `Core/README.md` maps the controller, refresh pipeline, scanner and boot; `Core/Settings`,
`Core/State`, `Core/View`, `Core/Input` and `Core/Integrations` carry their own READMEs. `Assets/` holds the private
fonts, `Localization/` the nine-locale registry, `.scripts/` the source checks that `.github/workflows/` run.

Two providers satisfy one plugin contract. With a compatible Orbit host, `Core/Integrations/Orbit.lua` registers Portal
as an Orbit plugin and Orbit owns settings, enablement, advanced movement, Canvas and visibility. Without one,
`Core/Settings/PortalStore.lua` owns `OrbitPortalDB`, `Core/PortalBoot.lua` owns lifecycle through the private
context's reconcilers, and the shared LibOrbitUI Edit Mode overlay moves the frame and commits its position at
successful drag stop. Both bind `Core/Settings/PortalSchema.lua` to the same LibOrbitUI window, panel, tab strip,
scrollbar and widgets; Boot also registers an AddOns Settings entry.

`/orbitportal` opens settings; `/orbitportal move` enters native Edit Mode, `reset` restores placement, `scan` rescans
and `status` names the active settings provider.

## Gotchas
- This preview deliberately preserves the existing Orbit settings path when integrated. Standalone settings are a
  separate store. Automatic migration, independent preset management, full external-profile export and the negotiated
  generic host provider remain pending; disabling Orbit does not yet transfer its profile configuration.
- The workspace-root `Orbit-Libs/LibOrbitUI/LibOrbitUI-1.0` runtime owns the shared library; consumers link directly
  to it during development. `Orbit/.scripts/package-orbit-ui.py` verifies the link, generates localization and records
  content hashes; staged packages contain regular files. Never hand-edit `Localization/Generated.lua`.
- `.pkgmeta` pins the verified full commit SHA of
  [LibOrbitUI 1.10](https://github.com/MoONSHO7/Orbit-Libs/releases/tag/LibOrbitUI-1.10), which provides API 1.14,
  and selects `LibOrbitUI/LibOrbitUI-1.0`. `python .scripts/fetch-libs.py` materializes that runtime for clean-checkout
  validation while preserving development junctions, including with `--force`. GitHub packaging reads the same pin.
  Settings require API 1.11; verify the published release, exact repin and matching manifest before delivery.
  The automatic latest-published-release resolver is not implemented. Portal embeds no ColorPicker dependency.
- Orbit-Libs is public. CI retains its `ORBIT_PAT` Git credential policy and skips the package check and runtime suite
  for fork and Dependabot pull requests and for branch pushes inside a fork or by Dependabot. Trusted validation runs
  before tagging and publishing.
- Blizzard Edit Mode Save/Revert does not govern standalone commits. A forced hidden/combat session aborts an unfinished
  drag; successful drag stop commits to the product store.
- Secure action attributes are cleared during editing and when recycling icons. Left click activates travel;
  right-button down toggles a favorite once and never casts. The frame uses an installed secure combat visibility
  driver; encounter policy is checked separately before protected mutations.
- Reveal moves/fades the icon content, leaving the frame as a fixed summon zone. Search must restore keyboard
  propagation on hover loss, repaint, disable and combat transitions. Icon wheel handlers forward to the same
  navigation owner.
- `IconSize` is logical UI size; `Spacing` is physical pixels. Portal text defaults to Orbit UI and keyboard search to
  Orbit UI Chat. The faces remain private and include locale-specific Korean, Simplified Chinese and Traditional
  Chinese binaries; new loose font files can require a client restart. Advanced Canvas rendering stays in the Orbit
  bridge.
- Future unsupported standalone stores stay untouched and inactive. The addon does not claim to import an unavailable
  Orbit SavedVariables file.
- `Orbit-Portal` is the project and host plugin name; `Orbit_Portal` and `OrbitPortalDB` retain the installed addon and
  saved-data identity. Orbit migrates legacy enablement, visibility and frame-anchor names before hydration.

## Secrets
Season scores and cooldown values may be secret. Scanner, tooltip and live decoration guard before
comparisons/arithmetic/caching; native cooldown rendering receives supported values directly. The shared library does
not grant access to restricted data.

## References
`Core/README.md`, `Localization/README.md`, `Assets/README.md`, `.scripts/README.md`, `.github/workflows/README.md`,
`Libs/LibOrbitUI-1.0/README.md`, `Orbit_Portal.toc`. In-game verification uses `/reload`, real secure clicks, native
Edit Mode and BugSack; mocked checks do not certify WoW behavior.
