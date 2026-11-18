"""Splits the library's Sets (run inside Blender:
blender -b --factory-startup -P split_sets.py -- [--apply] [--only <name part>]).

Each file in models/Sets/ is imported with its vertices merged, cut into its loose islands, and islands whose
boxes touch are grouped into items (a gun's scope stays with its gun). Items smaller than 1% of the triangles are
crumbs, not items. Without --apply it writes _state/sets_analysis.json: per file the triangle count, islands,
items and the share of the biggest item.
With --apply: a file whose biggest item holds 80% or more is one big model and is reduced to the library's limit
(10,000 triangles for weapons and props, 20,000 for the rest); a real set gives one file per item (<Name>_Part<N>),
each reduced when over the limit and given a rendered preview. Every result is grounded (pivot at its bottom
centre), placed by its name (rules.py) with a catalog row copied from the set's, and the set itself moves to
_originals/sets/ (kept). _state/sets_split.json lists what each set became. Stop the sorter while applying.
"""
import csv
import json
import re
import shutil
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from rules import IP, LIMIT, MAX, classify
from sorter import CATALOG, FIELDS, MODELS, ROOT, STATE, save_json, unique_path

SETS = MODELS / "Sets"
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ONLY = ARGS[ARGS.index("--only") + 1] if "--only" in ARGS else ""
APPLY = "--apply" in ARGS
FALLBACK = {"Weapons": ("Weapons", "Other_Weapons"), "Monsters": ("Monsters", "Other_Monsters"),
            "Props": ("Props", "Decor"), "Characters": ("Characters", "Characters"),
            "Animals": ("Animals", "Animals"), "Vehicles": ("Vehicles", "Vehicles")}


def load(path):
    """Imports a GLB and returns one joined mesh object with its transforms applied."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path), merge_vertices=True)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    return bpy.context.view_layer.objects.active


def components(edges_a, edges_b, n):
    """Connected components of n nodes joined by the pairs (edges_a[i], edges_b[i])."""
    label = np.arange(n)
    while True:
        m = np.minimum(label[edges_a], label[edges_b])
        new = label.copy()
        np.minimum.at(new, edges_a, m)
        np.minimum.at(new, edges_b, m)
        new = new[new]   # pointer jumping
        if np.array_equal(new, label):
            return np.unique(label, return_inverse=True)[1]
        label = new


def items_of(obj):
    """(face item labels, number of items, triangles per item, islands), crumbs merged into the nearest item."""
    me = obj.data
    me.calc_loop_triangles()
    co = np.empty(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    tri = np.empty(len(me.loop_triangles) * 3, dtype=np.int64)
    me.loop_triangles.foreach_get("vertices", tri)
    tri = tri.reshape(-1, 3)
    vlab = components(np.concatenate([tri[:, 0], tri[:, 1]]), np.concatenate([tri[:, 1], tri[:, 2]]), len(co))
    flab = vlab[tri[:, 0]]
    n_isl = flab.max() + 1
    lo = np.full((n_isl, 3), np.inf)
    hi = np.full((n_isl, 3), -np.inf)
    np.minimum.at(lo, vlab, co)
    np.maximum.at(hi, vlab, co)
    margin = 0.01 * np.linalg.norm(co.max(0) - co.min(0))
    touch = np.all((lo[:, None, :] - margin <= hi[None, :, :]) & (lo[None, :, :] - margin <= hi[:, None, :]), axis=2)
    a, b = np.nonzero(touch)
    ilab = components(a, b, n_isl)
    item = ilab[flab]
    count = np.bincount(item)
    big = np.nonzero(count >= 0.01 * len(item))[0]
    centre = np.array([(co[tri[item == k].ravel()].min(0) + co[tri[item == k].ravel()].max(0)) / 2 for k in range(len(count))])
    for k in np.nonzero(count < 0.01 * len(item))[0]:
        item[item == k] = big[np.argmin(np.linalg.norm(centre[big] - centre[k], axis=1))]
    item = np.unique(item, return_inverse=True)[1]
    return item, item.max() + 1, np.bincount(item), int(n_isl)


def tris_of(o):
    o.data.calc_loop_triangles()
    return len(o.data.loop_triangles)


def split(obj, item, n):
    """One object per item, the biggest first."""
    me = obj.data
    pidx = np.empty(len(me.loop_triangles), dtype=np.int64)
    me.loop_triangles.foreach_get("polygon_index", pidx)
    pitem = np.zeros(len(me.polygons), dtype=np.int64)
    pitem[pidx] = item
    parts = []
    for k in np.argsort(-np.bincount(item, minlength=n)):
        o = obj.copy()
        o.data = me.copy()
        bpy.context.scene.collection.objects.link(o)
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bm.faces.ensure_lookup_table()
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if pitem[f.index] != k], context="FACES")
        bm.to_mesh(o.data)
        bm.free()
        parts.append(o)
    bpy.data.objects.remove(obj)
    return parts


def decimate(o, target):
    """Collapses the mesh to about target triangles (UVs kept)."""
    m = o.modifiers.new("dec", "DECIMATE")
    m.ratio = target * 0.98 / tris_of(o)
    dg = bpy.context.evaluated_depsgraph_get()
    new = bpy.data.meshes.new_from_object(o.evaluated_get(dg))
    o.modifiers.clear()
    o.data = new


def ground(o):
    """Puts the bottom centre of the item at the origin (its pivot in Roblox)."""
    co = np.empty(len(o.data.vertices) * 3)
    o.data.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    lo, hi = co.min(0), co.max(0)
    o.data.transform(Matrix.Translation(-Vector(((lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2]))))
    o.location = (0, 0, 0)


def export(o, dest):
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.export_scene.gltf(filepath=str(dest), export_format="GLB", use_selection=True)


def render(o, png):
    """A 384 px textured preview from the front-left, transparent background."""
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "TEXTURE"
    sc.render.film_transparent = True
    sc.render.resolution_x = sc.render.resolution_y = 384
    for x in sc.objects:
        x.hide_render = x.type == "MESH" and x is not o
    if sc.camera is None:
        cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
        sc.collection.objects.link(cam)
        sc.camera = cam
    corners = [Vector(c) for c in o.bound_box]
    c = sum(corners, Vector()) / 8
    r = max((v - c).length for v in corners)
    sc.camera.location = c + Vector((0.8, -1.5, 0.7)).normalized() * r * 2.8
    sc.camera.rotation_euler = (c - sc.camera.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = str(png)
    bpy.ops.render.render(write_still=True)


report = {}
if APPLY:
    with open(CATALOG, encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    row_of = {r["file"]: r for r in rows}
    placed = json.loads((STATE / "placed.json").read_text(encoding="utf-8"))
    done, new_rows = set(), []
for path in sorted(SETS.rglob("*.glb")):
    if ONLY and ONLY not in path.stem:
        continue
    rel = str(path.relative_to(MODELS))
    obj = load(path)
    item, n, count, n_isl = items_of(obj)
    single = n == 1 or count.max() >= 0.8 * count.sum()
    report[rel] = {"tris": int(count.sum()), "islands": n_isl, "items": int(n),
                   "biggest": round(float(count.max() / count.sum()), 3), "sizes": sorted(count.tolist(), reverse=True)[:12]}
    print("SPLIT", path.stem, report[rel], flush=True)
    if not APPLY:
        continue
    base = re.sub(r"_Set$", "", re.sub(r"_\d+t(_\d+)?$", "", path.stem))
    cl, _ = classify(base)
    if IP.search(base.replace("_", " ").lower()):
        th, sb = "_Review", "IP_Risk"
    else:
        th, sb = cl[:2] if cl else FALLBACK[path.parent.name]
    limit = MAX.get(th, LIMIT)
    parts = [obj] if single else split(obj, item, n)
    row = row_of.get(rel, {})
    out = []
    for k, o in enumerate(parts):
        if tris_of(o) > limit:
            decimate(o, limit)
        ground(o)
        t = tris_of(o)
        name = base if single else f"{base}_Part{k + 1}"
        folder = MODELS / th / sb
        folder.mkdir(parents=True, exist_ok=True)
        dest = unique_path(folder, f"{name}_{t}t")
        export(o, dest)
        if single and path.with_suffix(".png").exists():
            shutil.copyfile(path.with_suffix(".png"), dest.with_suffix(".png"))
        else:
            render(o, dest.with_suffix(".png"))
        new_rel = str(dest.relative_to(MODELS))
        new_rows.append(dict(row, file=new_rel, theme=th, folder=sb, name=name, triangles=t))
        out.append(new_rel)
    keep = ROOT / "_originals" / "sets" / path.parent.name
    keep.mkdir(parents=True, exist_ok=True)
    path.replace(keep / path.name)
    if path.with_suffix(".png").exists():
        path.with_suffix(".png").replace(keep / path.with_suffix(".png").name)
    for r, p in placed.items():
        if p == rel:
            placed[r] = out[0]
    done.add(rel)
    report[rel]["out"] = out
    print("SPLIT ->", out, flush=True)
if APPLY:
    rows = [r for r in rows if r["file"] not in done] + new_rows
    rows.sort(key=lambda r: (r["theme"], r["folder"], r["file"]))
    with open(CATALOG, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, FIELDS)
        w.writeheader()
        w.writerows(rows)
    save_json(STATE / "placed.json", placed)
name = "sets_split.json" if APPLY else "sets_analysis.json"
old = json.loads((ROOT / "_state" / name).read_text(encoding="utf-8")) if APPLY and (ROOT / "_state" / name).exists() else {}
(ROOT / "_state" / name).write_text(json.dumps({**old, **report}, indent=1), encoding="utf-8")
print("SPLIT done", len(report))
