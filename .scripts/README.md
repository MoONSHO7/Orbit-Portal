# Portal validation

## Description
Source and package checks for the Portal addon.

## Purpose
Prevent invalid runtime bundles from reaching automatic tagging or publishing.

## Implementation
`check-package.py` walks the TOC/XML closure, compiles Lua 5.1 without executing it, checks distinct positive Interface versions including 120100 and the standalone SavedVariables declaration, then validates required art, audio, font/license assets and the LibOrbitUI content manifest. Run with Python 3.12 and `lupa==2.8`; `--root` checks a materialized package and `--release` rejects local library links. Version-list acceptance does not certify support for another client. `test-portal.py` loads the real runtime closure against explicit Lua 5.1 doubles; its scanner cases cover identity, ownership and native toy usability without claiming to reproduce protected game execution. Pass `--scanner-only` to isolate those focused cases from the broader standalone integration and localization checks.

The reusable `.github/workflows/validate.yml` fetches the pinned library before checking the package for tag creation and publishing. `fetch-libs.py` reads the URL, full commit SHA and runtime subdirectory directly from `.pkgmeta`, fetches that commit using Git credentials, and materializes ordinary files with `git archive`. Run `python .scripts/fetch-libs.py` from a checkout; `--root` targets a separate clean checkout and `--force` refreshes only ordinary dependency directories. Development symlinks and junctions are always preserved.

## Gotchas
- Runtime compilation does not prove WoW protection, taint, rendering or hardware-click behavior. Human `/reload` verification remains separate.
- Scanner fixtures deliberately use the public category scanners and real Portal data. Keep native eligibility doubles fail-closed so a new candidate cannot pass merely because a mock omitted its restriction.
- Orbit-Libs is public. CI retains `ORBIT_PAT` through `gh auth setup-git`; local fetches use the configured Git credential helper. The existing credential policy skips full package validation for fork/Dependabot pull requests; trusted validation remains required before publication.
- The content manifest includes the embedded library license as an asset, separately from executable TOC/XML entries. Pin updates must refresh the manifest through the workspace's `Orbit/.scripts/package-orbit-ui.py` against matching canonical source.
- Subdirectory archives do not inherit repository-root attributes. The fetcher disables Git's host newline conversion so Windows and Linux materialize the same committed bytes.

## References
`../README.md`, `../.github/workflows/README.md`, `../Orbit_Portal.toc`.
