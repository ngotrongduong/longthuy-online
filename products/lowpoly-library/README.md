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
Food, Tools_Items, SciFi_Tech); Characters; Animals; Vehicles.

## How it runs

1. `tools/harvest.js` runs inside www.meshy.ai in Claude's browser pane (signed in as the owner). It walks the
   public community list by tag and category, keeps the models above, then opens each one through the site's own
   router and clicks its Download button (glb). Every 20 clicks it saves a small manifest file.
   The code is stored in the page's localStorage (`ll_code`); after a page reload restart it with
   `window.__ll=0; new Function('return '+localStorage.getItem('ll_code'))()`. Stop it with
   `localStorage.setItem('ll_stop','true')`.
2. `tools/sorter.py` (`python -I tools/sorter.py`, runs forever) watches `~/Downloads`: the pane saves each file as
   `<guid>.tmp`. A GLB is matched to its manifest entry by its triangle count, moved and renamed into its folder,
   its preview picture fetched, and a catalog row written.

Notes:
- Meshy allows one signed-in session. Signing in elsewhere signs the pane out; the downloader then waits.
- Names come from the Meshy title or prompt (first words, filler removed); some are Spanish or odd and get fixed
  when a pack is curated.
- Nothing here is tested in Roblox Studio yet. Before a pack is sold: import, check scale, facing, pivot and look.
