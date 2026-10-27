# Re-import each export into an empty scene and report what came back.
import bpy, os, json
OUT = r"C:\Ai kiem tien\portfolio\rigged-fox"
res = {}
for fn in ("fox.fbx", "fox_idle.fbx", "fox_walk.fbx", "fox.glb"):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    p = os.path.join(OUT, fn)
    if fn.endswith(".fbx"): bpy.ops.import_scene.fbx(filepath=p)
    else: bpy.ops.import_scene.gltf(filepath=p)
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    arms = [o for o in bpy.data.objects if o.type == 'ARMATURE']
    info = {"size_kb": round(os.path.getsize(p) / 1024, 1), "meshes": len(meshes), "armatures": len(arms)}
    if meshes:
        m = meshes[0]
        dg = bpy.context.evaluated_depsgraph_get()
        me = m.data
        info["tris"] = sum(len(pl.vertices) - 2 for pl in me.polygons)
        mx = 0
        for v in me.vertices:
            mx = max(mx, sum(1 for g in v.groups if g.weight > 0))
        info["max_influences"] = mx
        info["images"] = [i.name for i in bpy.data.images]
        bb = [m.matrix_world @ v.co for v in me.vertices]
        info["bbox_world"] = [round(min(c[i] for c in bb), 3) for i in range(3)] + [round(max(c[i] for c in bb), 3) for i in range(3)]
    if arms:
        info["bones"] = len(arms[0].data.bones)
        info["bone_names"] = [b.name for b in arms[0].data.bones][:6]
    info["actions"] = {a.name: [round(x, 1) for x in a.frame_range] for a in bpy.data.actions}
    res[fn] = info
print("VERIFY", json.dumps(res, indent=1))
