"""Tidies the Meshy downloads the sorter left in ~/Downloads (run with: python -I tidy_downloads.py [--apply]).

Only files the downloader saved (Meshy_AI_*.glb / .zip, saved after the sorter's START) are touched; the owner's
own downloads stay where they are. A zip first gives up its GLB (see sorter.unzip_glb). Each GLB is then:
- a duplicate: the same bytes as a library file -> _dupes/ (kept, not deleted);
- placed: its triangle count fits a clicked model that is not in the library yet, clicked within 3 minutes of
  the file's save time -> models/<Theme>/<Sub>/ with its catalog row, as the sorter does;
- unsorted: none of the above (its click record was lost) -> _unsorted/ for the final re-sort.
Without --apply it only counts. Stop the sorter while applying: both write placed.json.
"""
import csv
import hashlib
import json
import sys
import time
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))   # -I leaves the script's folder out
from sorter import CATALOG, DOWNLOADS, FIELDS, MODELS, ROOT, START, STATE, glb_triangles, save_json, unique_path, unzip_glb

APPLY = "--apply" in sys.argv
sys.stdout.reconfigure(encoding="utf-8")


def sha1(p):
    h = hashlib.sha1()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def fits(tris, e):
    t = e.get("t", 0)
    return tris == t or (e.get("tp") == "quad" and 0.8 * t <= tris <= 2.2 * t)


cutoff = time.time() - 600   # files the sorter may still be handling are left alone
zips = [z for z in DOWNLOADS.glob("Meshy_AI_*.zip") if START <= z.stat().st_mtime < cutoff]
print("zips", len(zips))
if APPLY:
    for z in zips:
        unzip_glb(z)

entries = json.loads((STATE / "entries.json").read_text(encoding="utf-8"))
placed = json.loads((STATE / "placed.json").read_text(encoding="utf-8"))
by_size = {}
for p in MODELS.rglob("*.glb"):
    by_size.setdefault(p.stat().st_size, []).append(p)
hashes = {}

files = sorted((p for p in DOWNLOADS.glob("Meshy_AI_*.glb") if START <= p.stat().st_mtime < cutoff),
               key=lambda p: p.stat().st_mtime)
count = {"duplicate": 0, "placed": 0, "unsorted": 0, "unreadable": 0}
rows = []
for p in files:
    tris = glb_triangles(p)
    if tris is None:
        count["unreadable"] += 1
        continue
    size, mt = p.stat().st_size, p.stat().st_mtime
    same = [q for q in by_size.get(size, []) if q.exists()]
    if same:
        h = sha1(p)
        if any(hashes.setdefault(q, sha1(q)) == h for q in same):
            count["duplicate"] += 1
            if APPLY:
                (ROOT / "_dupes").mkdir(exist_ok=True)
                p.replace(unique_path(ROOT / "_dupes", p.stem))
            continue
    cands = [e for e in entries.values() if e["r"] not in placed and fits(tris, e) and abs(e.get("ts", 0) / 1000 - mt) <= 180]
    if cands:
        e = min(cands, key=lambda e: abs(e["ts"] / 1000 - mt))
        count["placed"] += 1
        if APPLY:
            folder = MODELS / e["th"] / e["sb"]
            folder.mkdir(parents=True, exist_ok=True)
            dest = unique_path(folder, f'{e["n"]}_{tris}t')
            p.replace(dest)
            if e.get("img"):
                try:
                    urllib.request.urlretrieve(e["img"], dest.with_suffix(".png"))
                except Exception as ex:
                    print("thumb failed", dest.name, ex)
            rel = str(dest.relative_to(MODELS))
            placed[e["r"]] = rel
            by_size.setdefault(size, []).append(dest)
            rows.append({"file": rel, "theme": e["th"], "folder": e["sb"], "name": e["n"], "triangles": tris,
                         "license": e.get("lic", ""), "author": e.get("a", ""), "likes": e.get("l", 0),
                         "downloads": e.get("d", 0), "meshy_post": "https://www.meshy.ai/posts/" + e["p"],
                         "task_id": e["r"], "downloaded_at": time.strftime("%Y-%m-%d %H:%M", time.localtime(mt))})
        continue
    count["unsorted"] += 1
    if APPLY:
        (ROOT / "_unsorted").mkdir(exist_ok=True)
        dest = unique_path(ROOT / "_unsorted", f"{p.stem}_{tris}t")
        p.replace(dest)
        by_size.setdefault(size, []).append(dest)

if APPLY:
    save_json(STATE / "placed.json", placed)
    with open(CATALOG, "a", newline="", encoding="utf-8") as f:
        csv.DictWriter(f, FIELDS).writerows(rows)
print("files", len(files), count, "applied" if APPLY else "dry run")
