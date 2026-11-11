# Portal input

## Description
Mouse-wheel scrolling, category jumps and the transient keyboard search over the painted portal list.

## Purpose
Capture keyboard input only while the cursor is over the frame, and release it on every path that can strand a hover.

## Implementation
`PortalNavigation.lua` owns keyboard capture, the query buffer and the transition between filtered and full lists.
`PortalSearchRanking.lua` matches indexed names, instances and categories in stable score order. It buckets matches
in one pass and preserves display order among equal scores. `PortalSearchDisplay.lua` presents the query and owns
its fade. `PortalWheel.lua` binds the frame and icon wheel handler: it pages matches and jumps between groups with
Shift on the full list. Keyboard Tab and wheel scrolling renew the active search. Filter changes repaint through
`PortalIconWindow` and restore the previous unfiltered scroll position on exit.

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
