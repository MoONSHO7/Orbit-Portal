# Portal input

## Description
Mouse-wheel scrolling, category jumps and the transient keyboard search over the painted portal list.

## Purpose
Capture keyboard input only while the cursor is over the frame, and release it on every path that can strand a hover.

## Implementation
`PortalNavigation.lua` owns wheel and keyboard input. `Install(ctx)` runs once from frame creation: it binds the frame's
mouse wheel, also exposed as `ctx.HandleWheel` for icons, which scrolls `state.scrollOffset` through the search filter
or the full list; over the full list Shift jumps to the previous or next display group's first entry. A module-level,
`UIParent`-parented `searchFrame` captures typed characters while shown: a short-lived buffer is matched against each
entry's short name, name, instance and category, prefix matches outranking substring matches and the short name
outranking other fields at each level, and `ApplyFilter` installs `state.searchFilter` and repaints through the
controller; `TAB` pages matches. Single-character keys are consumed and everything else propagates; the buffer text
fades out beside the frame, clearing the filter when it ends. `ShowSearch` requires the setting, an active plugin, no
Edit Mode and `PortalCombat.CanInteract()`; `HideSearch` restores propagation before hiding; `ApplySettings` re-reads
`EnableKeyboardSearch`.

## Gotchas
- An icon hidden mid-hover never fires `OnLeave`, so `searchFrame` polls `ctx.IsCursorOverFrame` while shown and calls
  `ctx.HoverExit` itself; without this the frame would eat every key.
- `EnableKeyboard` and `SetPropagateKeyboardInput` are protected in combat; every runtime call is guarded and combat
  transitions hide the search frame through `PortalCombat.UpdateState`. The one-time `EnableKeyboard(true)` in
  `Install` is not: standalone construction waits for the combat-gated `startup` reconciler, while the hosted `OnLoad`
  relies on Orbit's plugin construction timing.
- Search state is module-level, so one Portal frame per session; `Install` must run after the frame exists and before
  the first hover.
- Typing never captures while another frame has keyboard focus (`GetCurrentKeyBoardFocus`).

## References
`../README.md`, `../State/README.md`, `../../Assets/README.md` (search font).
