"""Sorts Meshy community downloads into the low-poly library.

The browser pane saves every download into ~/Downloads as <guid>.tmp. Two kinds arrive:
- a manifest (JSON starting with {"llManifest") that the in-page downloader saves now and then: the list of
  models it clicked Download on, with name, theme, folder and triangle count;
- a GLB model. Its triangle count, read from the file, picks its manifest entry (same count, clicked just before).

A matched GLB goes to models/<Theme>/<Sub>/<Name>_<tris>t.glb with its preview picture (.png) beside it and one
row in models/catalog.csv. Runs forever; run with: python -I sorter.py
"""
import csv
import json
import os
import struct
import sys
import time
import urllib.request
from pathlib import Path

DOWNLOADS = Path.home() / "Downloads"
ROOT = Path(__file__).resolve().parent.parent
MODELS = ROOT / "models"
STATE = ROOT / "_state"
CATALOG = MODELS / "catalog.csv"
START = time.mktime(time.strptime("2026-11-15 15:44", "%Y-%m-%d %H:%M"))
FIELDS = ["file", "theme", "folder", "name", "triangles", "license", "author", "likes", "downloads",
          "meshy_post", "task_id", "downloaded_at"]


def glb_triangles(path):
    with open(path, "rb") as f:
        head = f.read(12)
        if len(head) < 12 or head[:4] != b"glTF":
            return None
        total = struct.unpack("<I", head[8:12])[0]
        if total != os.path.getsize(path):
            return None  # still downloading
        clen, ctype = struct.unpack("<II", f.read(8))
        doc = json.loads(f.read(clen))
    acc = doc.get("accessors", [])
    tris = 0
    for mesh in doc.get("meshes", []):
        for prim in mesh.get("primitives", []):
            if prim.get("mode", 4) != 4:
                continue
            if "indices" in prim:
                tris += acc[prim["indices"]]["count"] // 3
            else:
                tris += acc[prim["attributes"]["POSITION"]]["count"] // 3
    return tris


def load_json(p, default):
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return default


def save_json(p, v):
    tmp = p.with_suffix(".part")
    tmp.write_text(json.dumps(v), encoding="utf-8")
    tmp.replace(p)


def unique_path(folder, stem):
    p = folder / f"{stem}.glb"
    i = 2
    while p.exists():
        p = folder / f"{stem}_{i}.glb"
        i += 1
    return p


def main():
    STATE.mkdir(parents=True, exist_ok=True)
    MODELS.mkdir(parents=True, exist_ok=True)
    entries = load_json(STATE / "entries.json", {})   # task id -> entry from manifests
    placed = load_json(STATE / "placed.json", {})     # task id -> library file
    bad = set(load_json(STATE / "bad.json", []))      # tmp names that are neither GLB nor manifest
    new_catalog = not CATALOG.exists()
    while True:
        found = []
        for p in DOWNLOADS.iterdir():
            if p.suffix.lower() not in (".tmp", ".glb", ".json") or p.name in bad:
                continue
            try:
                mtime = p.stat().st_mtime  # a browser temp file can vanish between listing and stat
            except OSError:
                continue
            if mtime >= START:
                found.append((mtime, p))
        files = [p for _, p in sorted(found)]
        changed = False
        for p in files:
            try:
                with open(p, "rb") as f:
                    head = f.read(16)
            except OSError:
                continue
            if head.startswith(b'{"llManifest'):
                try:
                    man = json.loads(p.read_text(encoding="utf-8"))
                except Exception:
                    continue  # still writing
                for e in man.get("items", []):
                    entries[e["r"]] = e
                save_json(STATE / "entries.json", entries)
                p.replace(STATE / f"manifest_{int(time.time() * 1000)}.json")
                changed = True
                continue
            if not head.startswith(b"glTF"):
                if time.time() - p.stat().st_mtime > 120:
                    bad.add(p.name)
                    save_json(STATE / "bad.json", sorted(bad))
                continue
            tris = glb_triangles(p)
            if tris is None:
                continue
            mt = p.stat().st_mtime * 1000
            match = None
            for e in entries.values():
                t = e.get("t", 0)
                # quads become 2 triangles; for some quad models t already counts triangles
                fits = tris == t or (e.get("tp") == "quad" and 0.8 * t <= tris <= 2 * t)
                if e["r"] in placed or not fits:
                    continue
                if e.get("ts", 0) - 20000 <= mt and (match is None or e["ts"] > match["ts"]):
                    match = e
            if match is None:
                continue  # its manifest has not arrived yet
            folder = MODELS / match["th"] / match["sb"]
            folder.mkdir(parents=True, exist_ok=True)
            dest = unique_path(folder, f'{match["n"]}_{tris}t')
            p.replace(dest)
            if match.get("img"):
                try:
                    urllib.request.urlretrieve(match["img"], dest.with_suffix(".png"))
                except Exception as ex:
                    print("thumb failed", dest.name, ex, flush=True)
            placed[match["r"]] = str(dest.relative_to(MODELS))
            save_json(STATE / "placed.json", placed)
            with open(CATALOG, "a", newline="", encoding="utf-8") as f:
                w = csv.DictWriter(f, FIELDS)
                if new_catalog:
                    w.writeheader()
                    new_catalog = False
                w.writerow({"file": str(dest.relative_to(MODELS)), "theme": match["th"], "folder": match["sb"],
                            "name": match["n"], "triangles": tris, "license": match.get("lic", ""),
                            "author": match.get("a", ""), "likes": match.get("l", 0),
                            "downloads": match.get("d", 0),
                            "meshy_post": "https://www.meshy.ai/posts/" + match["p"], "task_id": match["r"],
                            "downloaded_at": time.strftime("%Y-%m-%d %H:%M")})
            print("placed", dest.relative_to(MODELS), flush=True)
            changed = True
        if not changed:
            time.sleep(15)


if __name__ == "__main__":
    while True:  # a file the browser moves or deletes mid-read must not stop the sorter
        try:
            main()
        except OSError as ex:
            print("retry after", ex, flush=True)
            time.sleep(5)
