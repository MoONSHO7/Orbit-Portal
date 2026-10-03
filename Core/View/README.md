# Portal view

## Description
Secure icon buttons, the hover reveal tween and the private tooltip.

## Purpose
Keep secure attribute ownership, animation and tooltip content separate from the controller's refresh pipeline.

## Implementation
`PortalIcon.lua` owns the secure buttons and is the only writer of their action attributes. `Create(ctx)` builds one
`SecureActionButtonTemplate` button under `ctx.content` for the controller's icon pool, with its masked art, cooldown,
decoration regions and appear animation, and routes `OnEnter`/`OnLeave` to `ctx.HoverEnter`/`HoverExit` and
`PortalTooltip`. `Configure(ctx, icon, data, index, paint)` applies one entry with the controller's paint values: it
clears every action attribute, sets those of the entry's type (`spell`, `toy`, `item`, a random hearthstone pick or
`teleporthome`) and applies border, cooldown and fade; `../PortalCanvas.lua` then paints the text components. `PreClick`
toggles a favorite on right-button down and re-rolls the random hearthstone on left-button down; `PostClick` plays the
click feedback. `PortalReveal.lua` owns the one tween driver over `ctx.content`: `Reveal`/`Conceal` follow hover,
`Apply` resets to rest on settings, `OnRepaint` re-asserts after a paint and `Stop` runs on disable; slide offsets
`content` along the detected orientation while fading it, fade changes alpha only. `PortalTooltip.lua` fills the
context's private tooltip from the entry, its bind location, Mythic+ data and remaining cooldown.

## Gotchas
- Attributes are cleared before every configure and never set in Edit Mode. `Configure` runs only from `RepaintIcons`,
  which is combat-gated, so the only in-combat path is `PreClick`, which skips its re-roll under lockdown.
- The `SetCooldown` override on each cooldown instance exists because `SetCooldown` materializes new texture regions
  that need the circular mask; a `MaskTexture` region must never receive `AddMaskTexture`.
- The reveal tween never moves `content` under lockdown (it parents secure buttons): the driver stops and `OnRepaint`
  re-asserts the resting state after combat. `Reveal.Apply` reads `Animation` only when called.
- The appear animation is alpha only because `SetScale` is protected on secure buttons in combat.
- `Services.tooltip` is the context's private tooltip, not `GameTooltip`; `OnLeave` hides it through the same owner.

## Secrets
Season best, score, level and duration reads are guarded with `issecretvalue` before arithmetic or caching; the
tooltip falls back to `state.mythicPlusCache`. Cooldown remaining values reach the tooltip already filtered by the
scanner.

## References
`../README.md`, `../State/README.md`, `../Integrations/README.md` (the Canvas preview mirrors this layout),
`/wow-secrets`, `/wow-frames`.
