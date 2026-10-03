# Portal workflows

## Description
Validation, automatic version tagging and CurseForge packaging for Portal.

## Purpose
Keep the existing release sequence while stopping incomplete bundles or broken runtime contracts before tagging or
upload.

## Implementation
`validate.yml` fetches LibOrbitUI's immutable `.pkgmeta` pin and checks the triggering checkout with pinned Python/Lua
parser versions in two jobs: `validate` runs `check-package.py --release` and `test` runs `test-portal.py`. It runs on
pull requests to `main` and as the reusable workflow its three callers require: `validate-branches.yml` on pushes to
every other branch of the non-fork repository, `auto-tag.yml` before its existing commit-count tag step on pushes to
`main`, and `release.yml` before the standard packager fetches that same external and packages a pushed tag. A failing
suite therefore blocks tagging and publishing; no release is dispatched by these checks.

All three callers explicitly forward `ORBIT_PAT` to reusable validation. Validation and release checkouts disable
persisted checkout credentials, then configure GitHub CLI's Git helper. Orbit-Libs is public; the existing credential
policy keeps `GH_TOKEN` available during dependency fetching and packaging. Release publishing still uses the addon
repository token and CurseForge credentials.

Packaging uses `-u` to preserve LF text bytes, keeping the final embedded files consistent with the checked content
manifest.

## Gotchas
- Fork and Dependabot pull requests receive an explicit notice instead of the credentialed jobs, and branch pushes
  inside a fork or by Dependabot skip them; none has a library token, and this workflow never uses
  `pull_request_target`. Trusted validation must pass before a version can be tagged or published.
- The ignored local library junction never enters a clean-checkout package. Pin changes and generated content-manifest
  changes must agree before validation passes.
- A source check does not certify protected game execution. In-game acceptance and release ownership remain with the
  human.

## References
`../../.scripts/README.md`, `../../README.md`.
