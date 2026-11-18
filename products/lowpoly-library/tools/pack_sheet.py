"""A contact sheet of a folder's best-liked models, to pick a pack by eye.

Run in Blender: blender -b --factory-startup -P pack_sheet.py -- <Theme/Sub> <count> [<skip>]
Writes _ready/sheets/<Sub>_<skip>.png (8 columns of Meshy covers, cell 0 at the top left, row by row) and
_ready/sheets/<Sub>_<skip>.txt (cell number, file, likes, triangles).
"""
import csv
import sys
from pathlib import Path

import bpy
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
ARGS = sys.argv[sys.argv.index("--") + 1:]
FOLDER, COUNT = ARGS[0].replace("\\", "/"), int(ARGS[1])
SKIP = int(ARGS[2]) if len(ARGS) > 2 else 0
CELL, COLS = 256, 8
theme, sub = FOLDER.split("/")
with open(ROOT / "models" / "catalog.csv", encoding="utf-8", newline="") as f:
    rows = [r for r in csv.DictReader(f) if r["theme"] == theme and r["folder"] == sub]
rows.sort(key=lambda r: -int(r["likes"] or 0))
rows = [r for r in rows if (ROOT / "models" / r["file"]).with_suffix(".png").exists()][SKIP:SKIP + COUNT]
lines = (len(rows) + COLS - 1) // COLS
sheet = np.ones((lines * CELL, COLS * CELL, 4), dtype=np.float32)
for k, r in enumerate(rows):
    img = bpy.data.images.load(str((ROOT / "models" / r["file"]).with_suffix(".png")))
    w, h = img.size
    s = CELL / max(w, h)
    img.scale(max(1, int(w * s)), max(1, int(h * s)))
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    rgb = px[:, :, :3] * px[:, :, 3:] + (1 - px[:, :, 3:]) * 0.92   # transparent -> light grey
    y0 = (lines - 1 - k // COLS) * CELL + (CELL - h) // 2   # Blender images start at the bottom row
    x0 = (k % COLS) * CELL + (CELL - w) // 2
    sheet[y0:y0 + h, x0:x0 + w, :3] = rgb
    sheet[(lines - 1 - k // COLS) * CELL:(lines - k // COLS) * CELL, (k % COLS) * CELL, :3] = 0.5   # cell borders
    bpy.data.images.remove(img)
out = ROOT / "_ready" / "sheets"
out.mkdir(parents=True, exist_ok=True)
img = bpy.data.images.new("sheet", COLS * CELL, lines * CELL, alpha=False)
img.pixels[:] = sheet.ravel()
img.filepath_raw = str(out / f"{sub}_{SKIP}.png")
img.file_format = "PNG"
img.save()
(out / f"{sub}_{SKIP}.txt").write_text(
    "\n".join(f"{k}\t{r['file']}\t{r['likes']}\t{r['triangles']}" for k, r in enumerate(rows)), encoding="utf-8")
print("SHEET", out / f"{sub}_{SKIP}.png", len(rows))
