# Low-poly library (Meshy community, CC0)

Started 2026-11-15 on the owner's order: download as many good free low-poly models as possible from Meshy's
community, named and sorted by theme, to build Roblox collections and later sell them as big packs.

## What gets in

- Licence **CC0** only (Meshy shows it on each model; CC0 may be resold without credit). Credits are kept anyway in
  `models/catalog.csv` (author, Meshy link).
- **Textured** (has a colour map), not NSFW.
- **Triangles** (read from Meshy's task data, and checked again in the downloaded file):
  weapons and props 120-10,000; monsters, characters, animals, vehicles up to 20,000 (Roblox's limit for one
  MeshPart).
- Must fall into a theme: Weapons, Monsters, Props, Characters, Animals, Vehicles. Everything else is skipped.

## Where things are (on the owner's computer only; `models/` and `_state/` are git-ignored)

```
models/<Theme>/<Sub>/<Name>_<triangles>t.glb   the model (GLB, textures inside)
models/<Theme>/<Sub>/<Name>_<triangles>t.png   Meshy's preview picture
models/catalog.csv                             one row per model: file, theme, folder, name, triangles,
                                               licence, author, likes, downloads, Meshy link, task id, date
```

Sub-folders: Weapons (Swords, Daggers_Knives, Axes, Hammers_Maces, Spears_Polearms, Bows_Crossbows, Guns,
Explosives, Heavy_Artillery, Staffs_Wands, Shields, Armor_Helmets, Other_Weapons); Monsters (Dragons, Undead, Demons,
Slimes_Blobs, Golems_Elementals, Spiders_Insects, Orcs_Goblins_Trolls, Beasts_Mythic, Aliens_Mutants,
Other_Monsters); Props (Eggs, Containers, Treasure_Loot, Furniture, Lights_Fire, Nature, Buildings_Structures, Decor,
Food, Tools_Items, SciFi_Tech); Characters; Animals; Vehicles; Sets/<Theme> (several items in one file, 20k-80k
triangles, to split before selling). `models/_Review/` holds what must not go into a pack as it is: `IP_Risk` (names
of other people's characters or brands: Pokémon, Minecraft, Marvel...), `Over_20k` (over Roblox's limit for one mesh)
and `Unclassified` (no theme found in the name).

Kept outside the library, never deleted: `_dupes/` (byte-identical copies and reposts), `_zips/` (zips already
unpacked).

## Tidying

- `tools/tidy_downloads.py` places the Meshy files left in Downloads.
- `tools/dedupe_library.py` moves byte-identical copies out of the library.
- `tools/resort.py` re-sorts the whole library from the names with harvest.js's RULES (the last word wins, describing
  words such as stone or gold lose, a folder that still fits the name stays), fills the catalog, and writes its moves
  to `_state/resort_moves.csv`. It can be run again any time; a second run moves nothing.
- `tools/split_sets.py` (inside Blender 5.2: `blender -b --factory-startup -P tools/split_sets.py -- [--apply]`)
  empties `models/Sets/`. Most "sets" were one big model (247 of 278): those are reduced to the library's limit
  (10k triangles for weapons and props, 20k for the rest; the look stays the same). Real sets (several items
  apart from each other) give one file per item, `<Name>_Part<N>`, with a rendered preview. Every result has its
  pivot at its bottom centre. The originals stay in `_originals/sets/`.
- All of them: dry run first, `--apply` to do it, with the sorter stopped. `tools/rules.py` holds the naming and
  theme rules they share.

## How it runs

1. `tools/harvest.js` runs inside a www.meshy.ai tab in the owner's Edge (signed in as the owner, automatic
   downloads allowed for the site). It walks the public community list by tag and category, keeps the models
   above, then loads each one in a separate download window and clicks its Download button (glb). The window does
   a full page load per model, so memory is freed; the old way (one tab, site router) froze every 15-30 minutes.
   Every 5 clicks the main tab saves a small manifest file.
   Pop-ups are allowed for www.meshy.ai in Edge, so the script opens the download window itself, and replaces it
   after 3 failures in a row. The code is stored in the page's localStorage (`ll_code`); the big lists live in
   the page's IndexedDB. To (re)start, run
   `window.__ll=0; new Function('return '+localStorage.getItem('ll_code'))()` (a newer start makes the older
   loops quit). Stop it with `localStorage.setItem('ll_stop','true')`.
2. `tools/sorter.py` (`python -I tools/sorter.py`, runs forever) watches `~/Downloads`: the pane saves each file as
   `<guid>.tmp`. A GLB is matched to its manifest entry by its triangle count, moved and renamed into its folder,
   its preview picture fetched, and a catalog row written.

Notes:
- Meshy allows one signed-in session. Signing in elsewhere signs the pane out; the downloader then waits.
- Names come from the Meshy title or prompt (first words, filler removed); some are Spanish or odd and get fixed
  when a pack is curated.
- Nothing here is tested in Roblox Studio yet. Before a pack is sold: import, check scale, facing, pivot and look.
