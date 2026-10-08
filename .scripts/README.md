# Portal validation

## Description
Source, runtime-simulation and package checks for the Portal addon.

## Purpose
Prevent invalid runtime bundles or broken ownership contracts from reaching automatic tagging or publishing.

## Implementation
`check-package.py` walks the TOC/XML closure, compiles Lua 5.1 without executing it, checks distinct positive Interface
versions including 120100 and the standalone SavedVariables declaration, then validates required art, audio,
font/license assets, UI API 1.11, packaged mouse glyphs and the LibOrbitUI content manifest. Run with Python 3.12 and `lupa==2.8`; `--root` checks a
materialized package and `--release` rejects local library links. Version-list acceptance does not certify support
for another client.

`test-portal.py` loads the real TOC closure in Lua 5.1 against `tests/portal_native.lua`, an explicit native/host
double, and runs `tests/portal_cases.lua` once per scenario: standalone, disabled, combat-blocked, future and corrupt
stores, the legacy Orbit host, an unmarked host, injected constructor and movement failures, and `noatlas`, where the
settings shell's `housing-basic-container` lookup fails and the shared backdrop colour must take over.
`tests/portal_scanner_cases.lua` then covers identity, ownership and native toy usability per class/race fixture, and a
final pass proves every `L.` key Core references exists in all nine locales. Pass `--scanner-only` to isolate the
scanner cases. The reusable `.github/workflows/validate.yml` runs the package check and this suite as separate jobs
after fetching the pinned library.

`fetch-libs.py` reads the URL, full commit SHA and runtime subdirectory directly from `.pkgmeta`, fetches that commit
using Git credentials, and materializes ordinary files with `git archive`. Run `python .scripts/fetch-libs.py` from a
checkout; `--root` targets a separate clean checkout and `--force` refreshes only ordinary dependency directories.
Development symlinks and junctions are always preserved.

## Gotchas
- Runtime compilation and the doubles do not prove WoW protection, taint, rendering or hardware-click behavior. Human
  `/reload` verification remains separate.
- Scanner fixtures deliberately use the public category scanners and real Portal data. Keep native eligibility doubles
  fail-closed so a new candidate cannot pass merely because a mock omitted its restriction; the atlas double likewise
  resolves only the one atlas the library asks for.
- The legacy host double must track the Orbit APIs the bridge calls (`Orbit.Media:FetchFont`, `Orbit:GetTheme`,
  `Engine.*`); a bridge change that reaches a new Orbit owner fails the `legacy` scenario until the double learns it.
- Orbit-Libs is public. CI retains `ORBIT_PAT` through `gh auth setup-git`; local fetches use the configured Git
  credential helper. The existing credential policy skips validation for fork/Dependabot pull requests; trusted
  validation remains required before publication.
- The content manifest includes the embedded library license separately from executable TOC/XML entries. The current
  pin and manifest select published UI 1.10/API 1.14 bytes; settings require API 1.11. Refresh the manifest through `Orbit/.scripts/package-orbit-ui.py` in the workspace
  only against that matching released source. The automatic latest-published-release resolver is not implemented.
- Subdirectory archives do not inherit repository-root attributes. The fetcher disables Git's host newline conversion
  so Windows and Linux materialize the same committed bytes.

## References
`../README.md`, `../.github/workflows/README.md`, `../Orbit_Portal.toc` and
`../Libs/LibOrbitUI-1.0/Config/Dialogs/README.md` (the chrome contract the `noatlas` scenario asserts).
