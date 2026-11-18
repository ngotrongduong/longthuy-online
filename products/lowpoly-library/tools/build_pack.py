"""Builds one sellable pack: many library models, Roblox-ready, in one GLB laid out on a display grid.

Run in Blender: blender -b --factory-startup -P build_pack.py -- <pack id>
Reads packs/<pack id>.txt (one models/-relative file per line) and models/catalog.csv. Writes
_ready/packs/<pack id>.glb (one object per model, named after it; Roblox's importer makes one MeshPart each) and
_ready/packs/<pack id>_credits.txt (name, author, Meshy link of each model; all CC0).
Upload limit is 20 MB a file: the build stops if the GLB is bigger.
"""
import csv
import re
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from roblox_ready import export, prepare

ROOT = Path(__file__).resolve().parent.parent
PACK = sys.argv[sys.argv.index("--") + 1]
PER_ROW, GAP = 10, 2.0
# a line is "<file>" or "<file><TAB><display name given by eye>"
lines = [l.strip().split("\t") for l in (ROOT / "packs" / f"{PACK}.txt").read_text(encoding="utf-8").splitlines() if l.strip()]
files, given = [l[0] for l in lines], {l[0]: l[1] for l in lines if len(l) > 1}
with open(ROOT / "models" / "catalog.csv", encoding="utf-8", newline="") as f:
    row_of = {r["file"].replace("\\", "/"): r for r in csv.DictReader(f)}
bpy.ops.wm.read_factory_settings(use_empty=True)
objs, credits, seen = [], [], {}
x = y = row_depth = 0.0
for n, rel in enumerate(files):
    r = row_of[rel.replace("\\", "/")]
    o, dims, k = prepare(ROOT / "models" / rel)
    name = given.get(rel) or re.sub(r"\s+", " ", r["name"].replace("_", " ")).strip().title()
    seen[name] = seen.get(name, 0) + 1
    if seen[name] > 1:
        name = f"{name} {seen[name]}"
    o.name = o.data.name = name
    w, d = o.dimensions.x, o.dimensions.y
    if n and n % PER_ROW == 0:
        x, y, row_depth = 0.0, y - row_depth - GAP, 0.0
    o.location = (x + w / 2, y - d / 2, 0)
    x += w + GAP
    row_depth = max(row_depth, d)
    objs.append(o)
    credits.append(f"{name}\tby {r['author'] or 'unknown'}\t{r['meshy_post']}\tCC0")
    print("PACK +", name, flush=True)
dest = ROOT / "_ready" / "packs" / f"{PACK}.glb"
export(objs, dest)
(dest.parent / f"{PACK}_credits.txt").write_text("\n".join(credits) + "\n", encoding="utf-8")
mb = dest.stat().st_size / 1e6
print(f"PACK DONE {PACK}: {len(objs)} models, {mb:.1f} MB")
if mb > 19.5:
    raise SystemExit(f"PACK TOO BIG {mb:.1f} MB: take models out of packs/{PACK}.txt")
