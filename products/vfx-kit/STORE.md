# Hatch & Hit FX Kit (10 Effects, Mobile Ready): Creator Store

Live since 2026-11-07: Model **117863653160979**, USD 6.99, Distribute on Creator Store on, Roblox AI training off,
3 thumbnails (in moderation). Store page: create.roblox.com/store/asset/117863653160979. VFX pack 1 of
`products/vfx-packs/PLAN.md`.

Check on the next round: about 10 minutes after the save, the Toolbox API (`toolbox-service/v1/items/details?assetIds=`)
still said published true, purchasable false, visibilityStatus 3 (the two other kits: 1, purchasable), so Roblox was
probably still reviewing it. If it stays so for a day, open the Configure page and look for a message.

## What it is

- `FXKit`: the owner's VfxLib runtime (`C:\roblox-vfx-library\src\VfxLib`: init, Anchors, Budget, Builder, Lod,
  Palette, Quality, Schema) with a Textures of its own that lists only the 23 pictures these effects wear, and no
  `PackTextures` (no other creator's art or id ships).
- `FXKit/Effects`: `reveal.hatch_secret`, `reveal.hatch_dual`, `reveal.hatch_material`, `reveal.area_upgrade`,
  `buff.stat_set`, `hit.shock`, `hit.slash_arc`, `hit.holy`, `hit.acid_splat`, `hit.claw_spores` (copied unchanged
  from the library).
- `Demo`: 10 stands and `FXDemo` (client script) that loops every effect and variant; the kit attribute
  `ShowcaseDemo` turns it on or off.
- `README`: how to use it, what it does not do, the licence.

## Rights (checked 2026-11-07)

All 21 Roblox-hosted pictures are the owner's Goo Lineage battle art and stat icons (`owner = true` in the library's
Textures), plus 2 engine textures. A check script compared every texture key the 10 effects use with the kit's
Textures: none is missing, none is a pack key.

## How it was built (repeat this for a new version)

1. `products/vfx-kit/work/build_kit.ps1` (Lune, run from the library folder) writes `dist/HatchHitFXKit.rbxm` from
   the library and `work/` (Textures, FXDemo, README). Both folders are git-ignored.
2. Upload it through the Creator Hub's user-auth Assets API (it becomes a private Package, asset 122120393205381: a
   build source only), `InsertService:LoadAsset` it into Studio.
3. Test: Play, stand near the kit, every effect id must appear in `workspace.VfxLib` and the log must be free of
   `[HatchHitFX]` warnings. Done 2026-11-07: 10 of 10 play, no warnings (the first build missed `burstAcid` and
   `ring`; Schema refused `hit.acid_splat`, fixed).
4. Right-click > Save / Export > Save to Roblox (a plain Model), then the Configure page.
5. Thumbnails: `work/thumbs/t*.html` from the library's `previews/*.jpg`, rendered by headless Edge
   (`work/thumbs/render.ps1`) into `media/`.

## Description on the store (889 of 1000 characters)

10 polished effects for pet, simulator and RPG games, drawn on art made for them and kept light for phones. [...]
Not included: sounds, camera shake, server code. Made with an AI assistant's help, tested in Roblox Studio.
