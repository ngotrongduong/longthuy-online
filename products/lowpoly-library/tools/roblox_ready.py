"""Makes library models ready for Roblox, as copies (the library files stay as they are).

Run in Blender: blender -b --factory-startup -P roblox_ready.py -- <out dir> <model.glb> [<model.glb> ...]
Each model is written to <out dir>/<Theme>/<Sub>/<file>.glb with:
- its textures cut to at most 1024 px (Roblox shows no more; a 4K Meshy file can pass the 20 MB upload limit),
- a real size in studs for its kind (Meshy makes everything about 2 units tall; Roblox reads 1 unit as 1 stud),
- its pivot at the bottom centre,
- its colour map only (Roblox then uses it as the MeshPart's texture). With Meshy's normal and metal-roughness
  maps Roblox builds a SurfaceAppearance that shows some models grey from most angles.
build_pack.py uses prepare() to put many models in one file.
"""
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

TEX = 1024
# studs: ("h", n) = height, ("l", n) = longest side; by Sub folder, else by Theme
SIZE = {"Characters": ("h", 5.5), "Monsters": ("h", 7), "Animals": ("l", 4), "Vehicles": ("l", 14),
        "Weapons": ("l", 4), "Props": ("l", 3),
        "Swords": ("l", 4.5), "Daggers_Knives": ("l", 2), "Guns": ("l", 3), "Axes": ("l", 4),
        "Hammers_Maces": ("l", 4), "Spears_Polearms": ("l", 7), "Bows_Crossbows": ("l", 4), "Explosives": ("l", 1.5),
        "Staffs_Wands": ("l", 5), "Shields": ("l", 3.5), "Armor_Helmets": ("l", 1.5), "Heavy_Artillery": ("l", 10),
        "Furniture": ("l", 4), "Containers": ("l", 3), "Nature": ("l", 6), "Buildings_Structures": ("l", 30),
        "Lights_Fire": ("l", 6), "Decor": ("l", 2), "Treasure_Loot": ("l", 2), "Tools_Items": ("l", 2.5),
        "Food": ("l", 1.5), "Eggs": ("h", 2.5), "SciFi_Tech": ("l", 4),
        "Dragons": ("l", 16), "Golems_Elementals": ("h", 9), "Slimes_Blobs": ("h", 4), "Spiders_Insects": ("l", 5)}


def size_of(path):
    """Size rule from the library path models/<Theme>/<Sub>/<file>."""
    sub, theme = path.parent.name, path.parent.parent.name
    return SIZE.get(sub) or SIZE.get(theme) or ("l", 3)


def prepare(path):
    """Imports one model into the open scene and returns it as one object, sized, grounded, colour map only."""
    before = set(bpy.data.objects)
    old_mats, old_imgs = set(bpy.data.materials), set(bpy.data.images)
    bpy.ops.import_scene.gltf(filepath=str(path))
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    for e in new:
        if e.name in bpy.data.objects and e != o and e.type != "MESH":
            bpy.data.objects.remove(e)
    co = np.empty(len(o.data.vertices) * 3)
    o.data.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    lo, hi = co.min(0), co.max(0)
    dims = hi - lo   # Blender is Z up
    how, studs = size_of(path)
    k = studs / (dims[2] if how == "h" else dims.max())
    o.data.transform(Matrix.Scale(k, 4) @ Matrix.Translation(-Vector(((lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2]))))
    o.location = (0, 0, 0)
    for mat in set(bpy.data.materials) - old_mats:
        for node in (mat.node_tree.nodes if mat.node_tree else []):
            if node.type == "BSDF_PRINCIPLED":
                for name in ("Emission Color", "Normal", "Metallic", "Roughness"):
                    for link in list(node.inputs[name].links):
                        mat.node_tree.links.remove(link)
                node.inputs["Emission Strength"].default_value = 0
                node.inputs["Metallic"].default_value = 0
                node.inputs["Roughness"].default_value = 0.8
    for img in set(bpy.data.images) - old_imgs:
        w, h = img.size
        if max(w, h) > TEX:
            img.scale(max(1, w * TEX // max(w, h)), max(1, h * TEX // max(w, h)))
            img.pack()
    return o, dims, k


def export(objs, dest):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    dest.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(dest), export_format="GLB", use_selection=True,
                              export_image_format="JPEG", export_jpeg_quality=90)


if __name__ == "__main__":
    ARGS = sys.argv[sys.argv.index("--") + 1:]
    OUT = Path(ARGS[0])
    for path in map(Path, ARGS[1:]):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        o, dims, k = prepare(path)
        dest = OUT / path.parent.parent.name / path.parent.name / path.name
        export([o], dest)
        print("READY", path.name, "was", [round(float(d), 2) for d in dims], "x", round(float(k), 2),
              f"{dest.stat().st_size / 1e6:.1f} MB", flush=True)
