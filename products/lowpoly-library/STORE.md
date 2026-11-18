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
3. In Roblox Studio (a new unsaved place, never the Slime game): `tools/studio_pack.py` writes
   `_ready/packs/<id>_studio.luau`; run it in Studio (it loads the uploaded GLB, makes one Model of anchored
   MeshParts named after the pack with the Credits StringValue, sits it on the ground). Then Explorer > right-click
   the Model > Save / Export > Save to Roblox, title and description, Submit. Only a Model saved this way can be
   sold: a GLB or an rbxm sent through the Assets API becomes a Package (rbxm seen 2026-11-19 on 7 packs), and the Configure page answers "User is not authorized
   to distribute packages" (seen 2026-11-18 on asset 85476012659902).
   Studio pitfalls: hover before each Explorer click; if Explorer stops answering clicks, File > Exit > Don't Save
   and start Studio again. Never start Studio from the launcher while it is open: the launcher closes the open places.
4. create.roblox.com > the model > Configure: cover image, Distribute on Creator Store, USD 2.99, AI training off,
   Save Changes, then "Publish anyway" on the "N Open Use dependencies" box (the textures are Open Use; fine).
   Stay on the page until the save ends (it first waits for the cover upload, ~10-20 s); leaving early drops the
   save without a word. Reload: the page reads Distribute on / $2.99 only after it finishes loading (~5 s).
   Then Roblox checks the listing (minutes to an hour); `toolbox-service/v1/items/details?assetIds=<id>` gives
   `fiatProduct.purchasable: true` when it is for sale.

## The packs

| Pack | Title | Models | GLB | Asset id | On sale |
|---|---|---|---|---|---|
| swords_1 | Low Poly Swords Pack (30) | 30 | 11.0 MB | 93849427085099 | 2026-11-18 |
| axes_1 | Low Poly Axes Pack (26) | 26 | 9.3 MB | 126975866262517 | 2026-11-18 |
| hammers_1 | Low Poly Hammers & Maces Pack (30) | 30 | 11.1 MB | 136867296819046 | 2026-11-18 |
| polearms_1 | Low Poly Spears & Scythes Pack (30) | 30 | 12.7 MB | 104645121123859 | 2026-11-18 |
| bows_1 | Low Poly Bows & Crossbows Pack (30) | 30 | 11.3 MB | 133315051274678 | 2026-11-18 |
| daggers_1 | Low Poly Daggers & Knives Pack (29) | 29 | 10.6 MB | 136987197708808 | 2026-11-18 |
| staffs_1 | Low Poly Magic Staffs Pack (27) | 27 | 12.5 MB | 85859846393388 | 2026-11-18 |
| guns_1 | Low Poly Guns Pack (27) | 27 | 12.5 MB | 123870503302156 | 2026-11-18 |
| shields_1 | Low Poly Shields Pack (22) | 22 | 8.5 MB | 131582416760062 | 2026-11-18 |
| explosives_1 | Low Poly Bombs & Grenades Pack (29) | 29 | 10.2 MB | 112319583066666 | 2026-11-18 |
| artillery_1 | Low Poly Cannons & Tanks Pack (30) | 30 | 14.1 MB | 122521676678778 | 2026-11-18 |
| treasure_1 | Low Poly Crystals & Treasure Pack (30) | 30 | | 107421638970566 | 2026-11-19 |
| furniture_1 | Low Poly Furniture Pack (30) | 30 | | 101252418437593 | 2026-11-19 |
| nature_1 | Low Poly Nature Pack (30) | 30 | | 106798225417842 | 2026-11-19 |
| containers_1 | Low Poly Chests, Barrels & Crates Pack (30) | 30 | | 106682062072435 | 2026-11-19 |
| food_1 | Low Poly Food Pack (30) | 30 | | 116810615721355 | 2026-11-19 |
| lights_1 | Low Poly Lamps, Lanterns & Torches Pack (30) | 30 | | 73589797096276 | 2026-11-19 |
| buildings_1 | Low Poly Buildings Pack (30) | 30 | | 86548793461578 | 2026-11-19 |
| decor_1 | Low Poly Decor & Signs Pack (29) | 29 | | 134837643119232 | 2026-11-19 |
| tools_1 | Low Poly Tools & Items Pack (30) | 30 | | 123424450278281 | 2026-11-19 |
| undead_1 | Low Poly Skeletons & Undead Pack (30) | 30 | | 105517597310018 | 2026-11-19 |
| orcs_1 | Low Poly Orcs, Goblins & Trolls Pack (30) | 30 | | 114488186401227 | 2026-11-19 |
| aliens_1 | Low Poly Aliens & Mutants Pack (30) | 30 | | 86271682084824 | 2026-11-19 |
| demons_1 | Low Poly Demons Pack (26) | 26 | | 106170603931497 | 2026-11-19 |
| golems_1 | Low Poly Golems & Elementals Pack (30) | 30 | | 137937751018112 | 2026-11-19 |
| bugs_1 | Low Poly Spiders & Insects Pack (30) | 30 | | 120188657793667 | 2026-11-19 |
| beasts_1 | Low Poly Mythic Beasts Pack (30) | 30 | | 101781927262444 | 2026-11-19 |
| monsters_1 | Low Poly Monsters Pack (30) | 30 | | 100550471847203 | 2026-11-19 |
| eggs_1 | Low Poly Eggs Pack (19) | 19 | | 107992324543389 | 2026-11-19 |
| tech_1 | Low Poly Tech & Machines Pack (29) | 29 | | 107125335729888 | 2026-11-19 |
| dragons_1 | Low Poly Dragons Pack (28) | 28 | | 108505712138986 | 2026-11-19 |
| animals_1 | Low Poly Animals Pack (29) | 29 | | 110737594910346 | 2026-11-19 |
| vehicles_1 | Low Poly Vehicles Pack (15) | 15 | | 95376449656677 | 2026-11-19 |
| slimes_1 | Low Poly Slimes Pack (29) | 29 | | 123532267912299 | 2026-11-19 |
| characters_1 | Low Poly Characters Pack (26) | 26 | | 100023624535168 | 2026-11-19 |

All 35 checked purchasable at USD 2.99 with the toolbox API on 2026-11-19. Eggs, tech, dragons, animals, vehicles,
slimes and characters were first sent as rbxm through the Assets API (they became Packages: 113921748476880,
124284053225444, 86596441013999, 107521231391593, 79050150385129, 90589093269124, 83338660814648, private, not
for sale); the ids above are the Studio re-saves.

## Description (same for each pack; the owner's order 2026-11-19)

The owner's order: a listing says only what is in the pack. Never write that it was made with AI, collected, or
where it came from (no "AI", "Meshy", "CC0", "picked", "shared by"). The scratchpad script that wrote them all
took the names from `_ready/packs/<id>_credits.txt` (tidied: "Ranger S Bow" -> "Ranger's Bow", brand-like names
changed: Iron Golem -> Iron Guardian, Hobbit Hole -> Grass Hill House).

    <N> low poly <kind> for your Roblox game. Each one is a single textured MeshPart, sized for Roblox; the pack
    comes laid out on a display grid.

    In the pack: <name>, <name>, ...

    Not included: <one of the lines below>

- Weapons: tools or scripts to equip or swing them, animations, sounds, effects.
- Props: scripts, sounds, effects.
- Creatures and characters: rigs, animations, scripts, sounds, effects (they are static models).
- Vehicles: seats, moving wheels, driving scripts, sounds, effects.

The Credits StringValue inside each Model still names the makers and the source (kept for the licence record; a
buyer sees it only after inserting the pack).

## Tags

low poly, <kind>, weapon, stylized, rpg, fantasy, simulator, pack (props: low poly, <kind>, props, stylized,
simulator, map, pack; creatures: low poly, <kind>, creature, monster, stylized, rpg, simulator, pack)
