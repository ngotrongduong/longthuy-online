# Low-poly packs: Creator Store listings

Product: packs of 22 to 30 textured models from the low-poly library (`models/`), each pack one Roblox Model of
MeshParts laid out on a display grid. Every model is CC0 from the Meshy community gallery (AI-generated), resized to a
real Roblox size, textures cut to 1024 px, colour map only (renders the same from every angle). Lists: `packs/*.txt`.
Built files (git-ignored): `_ready/packs/<id>.glb`, `<id>_cover.png` (1:1 cover), `<id>_credits.txt`.

## Price (decided 2026-11-18, the owner's order: below the market, cheap, many)

USD 2.99 a pack, the lowest price the Creator Store takes for a Model. Paid weapon packs there sell at USD 6.99 to
14.99; ours costs nothing to make, so it sells on price and number.

## How a pack gets on the store

1. `pack_sheet.py` (Meshy covers) -> pick by eye -> `pick_pack.py` -> names by eye in `packs/<id>.txt`.
2. `build_pack.py` -> `render_pack.py`. Check the rendered cover by eye: a few library files hold another model than
   their Meshy cover shows (found 2026-11-18: 8 in the weapon folders); take those lines out and build again.
3. In Roblox Studio (test place, never the Slime game): Import 3D the GLB, group the parts as one Model named after
   the pack, put `<id>_credits.txt` in a StringValue named Credits inside it, right-click > Save to Roblox. Only a Model saved this way can be sold: a GLB sent through the Assets API
   becomes a Package, and the Configure page answers "User is not authorized to distribute packages"
   (seen 2026-11-18 on asset 85476012659902).
4. create.roblox.com > the model > Configure: name, description, cover image, Distribute on Creator Store, USD 2.99,
   AI training off. Check `toolbox-service/v1/items/details?assetIds=<id>` says it is for sale.

## The packs

| Pack | Title | Models | GLB | Asset id | On sale |
|---|---|---|---|---|---|
| swords_1 | Low Poly Swords Pack (30) | 30 | 11.0 MB | | |
| axes_1 | Low Poly Axes Pack (26) | 26 | 9.3 MB | | |
| hammers_1 | Low Poly Hammers & Maces Pack (30) | 30 | 11.1 MB | | |
| polearms_1 | Low Poly Spears & Scythes Pack (30) | 30 | 12.7 MB | | |
| bows_1 | Low Poly Bows & Crossbows Pack (30) | 30 | 11.3 MB | | |
| daggers_1 | Low Poly Daggers & Knives Pack (29) | 29 | 10.6 MB | | |
| staffs_1 | Low Poly Magic Staffs Pack (27) | 27 | 12.5 MB | | |
| guns_1 | Low Poly Guns Pack (27) | 27 | 12.5 MB | | |
| shields_1 | Low Poly Shields Pack (22) | 22 | 8.5 MB | | |
| explosives_1 | Low Poly Bombs & Grenades Pack (29) | 29 | 10.2 MB | | |
| artillery_1 | Low Poly Cannons & Tanks Pack (30) | 30 | 14.1 MB | | |

## Description (same for each pack; fill in <N> and <kind>)

<N> stylized <kind> for your Roblox game, ready to drop in. Each one is a single textured MeshPart, already sized
for Roblox, with its pivot at the bottom and a light texture (1024 px or less) that looks the same from every angle.
The pack arrives laid out on a display grid; take the ones you need.

- <N> different models, under 20,000 triangles each (most under 10,000)
- No scripts, nothing hidden, no free models inside
- Good for simulators, RPGs, shops, loot drops, display racks and obby rewards

These models are AI-generated (Meshy) and were shared by their makers as CC0. We picked them by hand, sized them
and prepared them for Roblox. The credits list (model, maker, source) is in the pack's Credits value.

Not included: tools or scripts to equip or swing them, animations, sounds, effects.

## Tags

low poly, <kind>, weapon, stylized, rpg, fantasy, simulator, pack
