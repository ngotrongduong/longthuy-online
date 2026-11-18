"""Sorts Meshy community downloads into the low-poly library.

The browser pane saves every download into ~/Downloads as <guid>.tmp. Two kinds arrive:
- a manifest (JSON starting with {"llManifest") that the in-page downloader saves now and then: the list of
  models it clicked Download on, with name, theme, folder and triangle count;
- a GLB model. A named Meshy_AI_*.glb is matched by the Meshy id in Edge's download record of that file; a
  <guid>.tmp has no record and is matched by triangle count to an entry clicked in the 10 minutes before it.

A matched GLB goes to models/<Theme>/<Sub>/<Name>_<tris>t.glb with its preview picture (.png) beside it and one
row in models/catalog.csv. Runs forever; run with: python -I sorter.py
"""
import csv
import json
import os
import re
import shutil
import sqlite3
import struct
import sys
import time
import urllib.request
import zipfile
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
    for i in range(20):  # the watchdog or a virus scan can hold the file open for a moment
        try:
            tmp.replace(p)
            return
        except PermissionError:
            time.sleep(0.5)
    try:  # a held file can often still be written in place
        p.write_text(json.dumps(v), encoding="utf-8")
    except OSError as ex:  # the state stays in memory; the next save writes it
        print("save failed", p.name, ex, flush=True)


def unzip_glb(z):
    """Some Meshy models download as a .zip: put its GLB beside it (same save time) and keep the zip in _zips/."""
    try:
        with zipfile.ZipFile(z) as zf:
            glbs = [i for i in zf.infolist() if i.filename.lower().endswith(".glb")]
            if glbs:
                big = max(glbs, key=lambda i: i.file_size)
                out = DOWNLOADS / f"{z.stem}.glb"   # our own name, never the member's path
                out.write_bytes(zf.read(big))
                os.utime(out, (z.stat().st_mtime, z.stat().st_mtime))
    except (zipfile.BadZipFile, OSError):
        return  # still downloading
    (ROOT / "_zips").mkdir(exist_ok=True)
    dest, i = ROOT / "_zips" / z.name, 2
    while dest.exists():
        dest, i = ROOT / "_zips" / f"{z.stem}_{i}.zip", i + 1
    z.replace(dest)


def unique_path(folder, stem):
    p = folder / f"{stem}.glb"
    i = 2
    while p.exists():
        p = folder / f"{stem}_{i}.glb"
        i += 1
    return p


UUID = re.compile(r"/converted/([0-9a-f-]{36})/")


def edge_tasks():
    """Saved file path -> Meshy id in its download link (uploads/converted/<id>/...), from Edge's download records
    only (not the browsing history). Edge keeps History open, so a copy is read and deleted."""
    out = {}
    for hist in (Path(os.environ["LOCALAPPDATA"]) / "Microsoft" / "Edge" / "User Data").glob("*/History"):
        tmp = STATE / "edge_history_copy"
        try:
            shutil.copyfile(hist, tmp)
            con = sqlite3.connect(tmp)
            rows = con.execute(
                "SELECT d.target_path, (SELECT url FROM downloads_url_chains c WHERE c.id = d.id "
                "ORDER BY chain_index DESC LIMIT 1) FROM downloads d WHERE d.target_path LIKE '%Meshy_AI_%'").fetchall()
            con.close()
        except (OSError, sqlite3.Error):
            continue
        finally:
            tmp.unlink(missing_ok=True)
        for path, url in rows:
            m = UUID.search(url or "")
            if m:
                out[os.path.normcase(path)] = m.group(1)
    return out


def main():
    STATE.mkdir(parents=True, exist_ok=True)
    MODELS.mkdir(parents=True, exist_ok=True)
    entries = load_json(STATE / "entries.json", {})   # task id -> entry from manifests
    placed = load_json(STATE / "placed.json", {})     # task id -> library file
    bad = set(load_json(STATE / "bad.json", []))      # tmp names that are neither GLB nor manifest
    new_catalog = not CATALOG.exists()
    while True:
        found = []
        for z in DOWNLOADS.glob("Meshy_AI_*.zip"):
            try:
                if z.stat().st_mtime >= START and time.time() - z.stat().st_mtime > 10:
                    unzip_glb(z)
            except OSError:
                pass
        for p in DOWNLOADS.iterdir():
            if p.suffix.lower() not in (".tmp", ".glb", ".json") or p.name in bad:
                continue
            if p.suffix.lower() == ".glb" and not p.name.startswith("Meshy_AI_"):
                continue  # the owner's own downloads stay where they are
            try:
                mtime = p.stat().st_mtime  # a browser temp file can vanish between listing and stat
            except OSError:
                continue
            if mtime >= START:
                found.append((mtime, p))
        files = [p for _, p in sorted(found)]
        changed, edge = False, None
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
            if p.suffix.lower() == ".glb":
                # a named download: Edge's record says which model it is; guessing by triangle count put
                # thousands of files under another model's name (2026-11-18)
                if edge is None:
                    edge = edge_tasks()
                # a GLB taken out of a zip: the record is the zip's
                u = edge.get(os.path.normcase(str(p))) or edge.get(os.path.normcase(str(p.with_suffix(".zip"))))
                match = entries.get(u) or next((e for e in entries.values() if e["p"] == u), None)
                if match and match["r"] in placed:
                    match = None
            else:
                # a <guid>.tmp from the browser pane has no record: same triangle count, clicked in the last
                # 10 minutes (an older click is a failed download, not this file)
                for e in entries.values():
                    t = e.get("t", 0)
                    # quads become 2 triangles; for some quad models t already counts triangles
                    fits = tris == t or (e.get("tp") == "quad" and 0.8 * t <= tris <= 2.2 * t)
                    if e["r"] in placed or not fits:
                        continue
                    if mt - 600000 <= e.get("ts", 0) <= mt + 20000 and (match is None or e["ts"] > match["ts"]):
                        match = e
            if match is None:
                continue  # its manifest or its download record has not arrived yet
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
