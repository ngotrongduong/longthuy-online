"""Moves byte-identical copies out of the library (run with: python -I dedupe_library.py [--apply]).

Files are grouped by size, then by SHA-1. In each group the oldest file stays; the others go to _dupes/library/
(kept, not deleted), their catalog rows are dropped and placed.json points their task ids at the kept file.
Without --apply it only counts. Stop the sorter while applying: it appends to the catalog and writes placed.json.
"""
import csv
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))   # -I leaves the script's folder out
from sorter import CATALOG, FIELDS, MODELS, ROOT, STATE, save_json, unique_path

APPLY = "--apply" in sys.argv
sys.stdout.reconfigure(encoding="utf-8")


def sha1(p):
    h = hashlib.sha1()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


by_size = {}
for p in MODELS.rglob("*.glb"):
    by_size.setdefault(p.stat().st_size, []).append(p)
groups = {}
for size, ps in by_size.items():
    if len(ps) > 1:
        for p in ps:
            groups.setdefault((size, sha1(p)), []).append(p)

moved = {}   # relative path of a copy -> relative path of the file kept
for ps in groups.values():
    if len(ps) < 2:
        continue
    ps.sort(key=lambda p: p.stat().st_mtime)
    keep = str(ps[0].relative_to(MODELS))
    for p in ps[1:]:
        moved[str(p.relative_to(MODELS))] = keep
print("library files", sum(len(v) for v in by_size.values()), "copies", len(moved))

if APPLY and moved:
    out = ROOT / "_dupes" / "library"
    out.mkdir(parents=True, exist_ok=True)
    for rel in moved:
        p = MODELS / rel
        p.replace(unique_path(out, p.stem))
        png = p.with_suffix(".png")
        if png.exists():
            png.replace(out / f"{p.stem}.png")
    placed = json.loads((STATE / "placed.json").read_text(encoding="utf-8"))
    for r, rel in placed.items():
        if rel in moved:
            placed[r] = moved[rel]
    save_json(STATE / "placed.json", placed)
    with open(CATALOG, encoding="utf-8", newline="") as f:
        rows = [r for r in csv.DictReader(f) if r["file"] not in moved]
    with open(CATALOG, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, FIELDS)
        w.writeheader()
        w.writerows(rows)
    print("moved", len(moved), "catalog rows", len(rows))
