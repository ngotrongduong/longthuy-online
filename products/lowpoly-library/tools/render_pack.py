"""Renders the 1:1 cover of a built pack for its Creator Store page.

Run in Blender: blender -b --factory-startup -P render_pack.py -- <pack id>
Reads _ready/packs/<pack id>.glb (made by build_pack.py), stands long thin models up, sets them out as a square wall
seen slightly from the side, writes _ready/packs/<pack id>_cover.png (1024 x 1024) and prints which model is in which cell, so a
model whose file is not what its Meshy cover showed can be found by eye and taken out of the pack.
"""
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Quaternion, Vector

ROOT = Path(__file__).resolve().parent.parent
PACK = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT / "_ready" / "packs" / f"{PACK}.glb"))
objs = sorted((o for o in bpy.data.objects if o.type == "MESH"), key=lambda o: o.name)
bpy.context.view_layer.update()


def box(o):
    pts = [o.matrix_world @ Vector(c) for c in o.bound_box]
    return Vector([min(p[i] for p in pts) for i in range(3)]), Vector([max(p[i] for p in pts) for i in range(3)])


for o in objs:
    co = np.empty(len(o.data.vertices) * 3)
    o.data.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    val, vec = np.linalg.eigh(np.cov((co - co.mean(0)).T))
    axis = Vector(vec[:, 2])
    if val[2] > 6 * val[1]:   # long and thin: a blade or a staff stands up, a gun lies along X
        up = Vector((0, 0, 1 if axis.z >= 0 else -1))
        if PACK.split("_")[0] in ("guns", "explosives", "artillery"):
            up = Vector((1 if axis.x >= 0 else -1, 0, 0))
        o.rotation_mode = "QUATERNION"
        o.rotation_quaternion = axis.rotation_difference(up)
    bpy.context.view_layer.update()
    # turn it about Z so its thinnest side faces the camera (a shield shows its face, a tank its side)
    m = np.array(o.matrix_world.to_3x3())
    xy = (co @ m.T)[:, :2]
    val2, vec2 = np.linalg.eigh(np.cov((xy - xy.mean(0)).T))
    thin = vec2[:, 0]
    o.rotation_mode = "QUATERNION"
    turn = (math.pi / 2 - math.atan2(thin[1], thin[0]) + math.pi / 2) % math.pi - math.pi / 2   # the smaller turn keeps its front
    o.rotation_quaternion = Quaternion((0, 0, 1), turn) @ o.rotation_quaternion
bpy.context.view_layer.update()
cw = float(np.percentile([box(o)[1].x - box(o)[0].x for o in objs], 80)) * 1.3   # one wide item may overlap a little
ch = max(box(o)[1].z - box(o)[0].z for o in objs) * 1.05
cols = max(1, round(math.sqrt(len(objs) * ch / cw)))   # as many columns as make the wall square
rows = math.ceil(len(objs) / cols)
for n, o in enumerate(objs):
    lo, hi = box(o)
    centre = (lo + hi) / 2
    # wall on X (columns) and Z (rows), all at y = 0
    target = Vector(((n % cols) * cw, 0, (rows - 1 - n // cols) * ch))
    o.location += target - centre
    print(f"CELL {n} row {n // cols} col {n % cols}\t{o.name}")
bpy.context.view_layer.update()
lo = Vector([min(box(o)[0][i] for o in objs) for i in range(3)])
hi = Vector([max(box(o)[1][i] for o in objs) for i in range(3)])
mid = (lo + hi) / 2

scene = bpy.context.scene
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
scene.collection.objects.link(cam)
cam.data.type = "ORTHO"
cam.data.ortho_scale = max(hi.x - lo.x, hi.z - lo.z) * 1.08
yaw, pitch = math.radians(20), math.radians(12)
cam.location = mid + Vector((math.sin(yaw), -math.cos(yaw), math.tan(pitch))) * 200
cam.rotation_euler = (math.radians(90) - pitch, 0, yaw)
cam.data.clip_end = 1000
scene.camera = cam
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
scene.collection.objects.link(sun)
sun.data.energy = 2.5
sun.rotation_euler = (math.radians(50), math.radians(-20), math.radians(30))
world = bpy.data.worlds.new("w")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.33, 0.38, 0.48, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.7
try:
    scene.render.engine = "BLENDER_EEVEE"
except TypeError:
    scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.view_settings.view_transform = "Standard"
scene.render.resolution_x = scene.render.resolution_y = 1024
scene.render.filepath = str(ROOT / "_ready" / "packs" / f"{PACK}_cover.png")
bpy.ops.render.render(write_still=True)
print("COVER", scene.render.filepath, len(objs))
