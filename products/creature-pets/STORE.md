# Fantasy Creature Pets (64 Rigged, Animated): Creator Store

Live since 2026-11-07: Model **116354459698651**, USD 14.99, Distribute on Creator Store on, Roblox AI training
off, 3 thumbnails (in moderation). Store page: create.roblox.com/store/asset/116354459698651.

## What it is

The 64 pets of the owner's game Egg Heist, each one textured skinned MeshPart with its own Bones, scaled to 4 studs
tall (7 at most on the long side), in an 8 x 8 grid. Plus `CreatureMotion`: the game's own procedural motion
(`RigMotion`, `MotionData`, copied from `C:\roblox 2nd game\src\shared`) and a new client script
`CreatureAnimator` that animates every model tagged `AnimatedCreature`. No animation assets, so no permission
problems for buyers. A README ModuleScript says how to use it and what it does not do.

## Rights (checked 2026-11-07)

- The models came from Meshy (paid plan, receipt 2026-10-07) and Tripo (Pro plan, 2026-10-09/12): paid plans give
  the owner commercial use. The rigs are the owner's, his rigging service's or ours (`tools\rig_model.ps1`).
- None of the 7 free PeppiIy store pets is inside: every file in `assets/Pets` is now the owner's own import
  (`ModelImport` attribute, Bones), checked by a scan of all 64.
- The 361 meshes and textures are "Open Use" on Roblox (made before Asset Privacy existed on the account). Making
  them Restricted needs Asset Privacy turned on for the whole account and a re-import: not done, the same meshes are
  already public in Egg Heist. "Publish anyway" was chosen.

## How it was built (repeat this for a new version)

1. `products/creature-pets/work/build_pack.ps1` (Lune, run from the game folder) writes `dist/CreaturePets.rbxm`
   from `assets/Pets/*.rbxm` and the scripts in `work/`. Both folders are git-ignored: the product stays off the
   public repo.
2. Upload that file through the Creator Hub's user-auth Assets API (it becomes a private Package, asset
   122717219245961: a build source only), `InsertService:LoadAsset` it into Studio, `Model:ScaleTo` each creature to
   4 studs and lay the grid (`execute_luau`).
3. Test: Play, move the camera near (the animator idles creatures further than 220 studs), check that all 64 bones
   move and the showcase stroll runs. Done 2026-11-07: 64 of 64 moving.
4. Right-click > Save / Export > Save to Roblox (a plain Model, sellable), then the Configure page.

## Not in this pack (a possible second pack)

The 8 bosses (`assets/Guardians`) and 6 mounts (`assets/Mounts`): bigger, some untextured (boss_Jungle), and their
best motion is BossMotion and MountLife, not the plain pet walk.

## Description on the store (958 of 1000 characters)

64 rigged low-poly fantasy creatures for pet, simulator and adventure games, each with its own skeleton and a
built-in animator. Press Play and they breathe, look around and flick their tails, and they walk or trot whenever
you move them. No animation assets to upload, no permissions to fix. [...] Not included: AI or follow logic,
attack or jump clips. README inside. Made with an AI assistant's help, tested in Roblox Studio.
