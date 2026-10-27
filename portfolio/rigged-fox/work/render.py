# Render shots / stills of fox.blend.
# blender --background --factory-startup --python render.py -- <shot> [frames|all] [samples]
import bpy, math, os, sys, json
from mathutils import Vector, Matrix

OUT = r"C:\Ai kiem tien\portfolio\rigged-fox"
WORK = os.path.join(OUT, "work")
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SHOT = argv[0] if argv else "S2"
FRAMES = argv[1] if len(argv) > 1 else "all"
SAMPLES = int(argv[2]) if len(argv) > 2 else 48

bpy.ops.wm.open_mainfile(filepath=os.path.join(OUT, "fox.blend"))
scene = bpy.context.scene
for _n in ("Cube", "Light", "Camera"):
    if _n in bpy.data.objects: bpy.data.objects.remove(bpy.data.objects[_n], do_unlink=True)
arm =bpy.data.objects["FoxRig"]
fox = bpy.data.objects["Fox"]
build = json.load(open(os.path.join(WORK, "build_report.json")))
WALK_T, IDLE_T = build["walk_frames"], build["idle_frames"]
WALK_V = build["walk_stride_m"] / WALK_T

# ----------------------------------------------------------------------------------------------
# render settings
r = scene.render
r.engine = 'BLENDER_EEVEE'
r.resolution_x, r.resolution_y, r.resolution_percentage = 1280, 720, 100
r.fps = 30
r.image_settings.file_format = 'PNG'
r.image_settings.color_mode = 'RGB'
r.film_transparent = False
ee = scene.eevee
ee.taa_render_samples = SAMPLES
try: ee.use_raytracing = True
except Exception: pass
try: ee.use_shadows = True
except Exception: pass
try: ee.shadow_resolution_scale = 1.0
except Exception: pass
for _k, _v in (("shadow_ray_count", 4), ("shadow_step_count", 16), ("use_shadow_jitter_viewport", True)):
    try: setattr(ee, _k, _v)
    except Exception as _e: print("EE", _k, _e)
try:
    ee.ray_tracing_options.use_denoise = True
except Exception as _e: print("EE denoise", _e)
vs = scene.view_settings
try:
    vs.view_transform = 'AgX'
    vs.look = 'AgX - Medium High Contrast'
except Exception as e:
    print("LOOK", e)

world = scene.world or bpy.data.worlds.new("World")
scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes.get("Background")
bg.inputs[0].default_value = (0.035, 0.045, 0.06, 1)
bg.inputs[1].default_value = 1.0

# ----------------------------------------------------------------------------------------------
def new_mat(name, color=(0.8, 0.8, 0.8), rough=0.6, emit=None, emit_strength=0.0, alpha=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    if emit is not None:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = emit_strength
    if alpha < 1.0:
        b.inputs["Alpha"].default_value = alpha
        try: m.surface_render_method = 'BLENDED'
        except Exception: m.blend_method = 'BLEND'
        m.use_backface_culling = True
    return m

def srgb(h):
    h = h.lstrip('#'); c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c)

def empty(name, loc=(0, 0, 0), parent=None):
    e = bpy.data.objects.new(name, None)
    scene.collection.objects.link(e)
    e.location = loc
    if parent: e.parent = parent
    return e

def look_at(obj, target):
    d = (Vector(target) - obj.location)
    obj.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()

# ----------------------------------------------------------------------------------------------
# cyclorama backdrop with optional floor grid
def cyclorama(grid=False):
    import bmesh
    bm = bmesh.new()
    prof = []
    for i in range(13): prof.append((-9.0 + i * 0.85, 0.0))        # floor  y from -9 to ~1.2
    R0 = 2.4
    for i in range(1, 13):
        a = (math.pi / 2) * i / 12
        prof.append((1.2 + math.sin(a) * R0, R0 - math.cos(a) * R0))
    prof.append((1.2 + R0, 8.0))
    W = 14.0
    rows = []
    for (y, z) in prof:
        rows.append([bm.verts.new((x, y, z)) for x in (-W + i * (2 * W / 16) for i in range(17))])
    for i in range(len(rows) - 1):
        for j in range(16):
            bm.faces.new((rows[i][j], rows[i][j + 1], rows[i + 1][j + 1], rows[i + 1][j]))
    me = bpy.data.meshes.new("Cyc"); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = True
    ob = bpy.data.objects.new("Cyclorama", me)
    scene.collection.objects.link(ob)
    m = bpy.data.materials.new("CycMat"); m.use_nodes = True
    nt = m.node_tree; N = nt.nodes; L = nt.links
    b = N.get("Principled BSDF")
    b.inputs["Roughness"].default_value = 0.9
    tc = N.new("ShaderNodeTexCoord")
    sep = N.new("ShaderNodeSeparateXYZ"); L.new(tc.outputs["Object"], sep.inputs[0])
    # height gradient: floor colour -> darker top
    mr = N.new("ShaderNodeMapRange"); mr.inputs[1].default_value = 0.0; mr.inputs[2].default_value = 3.5
    L.new(sep.outputs[2], mr.inputs[0])
    ramp = N.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*srgb("#46566b"), 1)
    ramp.color_ramp.elements[1].color = (*srgb("#141b25"), 1)
    L.new(mr.outputs[0], ramp.inputs[0])
    col_out = ramp.outputs[0]
    if grid:
        def line(axis_out):
            mul = N.new("ShaderNodeMath"); mul.operation = 'MULTIPLY'; mul.inputs[1].default_value = 4.0
            L.new(axis_out, mul.inputs[0])
            fr = N.new("ShaderNodeMath"); fr.operation = 'PINGPONG'; fr.inputs[1].default_value = 0.5
            L.new(mul.outputs[0], fr.inputs[0])
            lt = N.new("ShaderNodeMath"); lt.operation = 'LESS_THAN'; lt.inputs[1].default_value = 0.008
            L.new(fr.outputs[0], lt.inputs[0])
            return lt.outputs[0]
        mx = N.new("ShaderNodeMath"); mx.operation = 'MAXIMUM'
        L.new(line(sep.outputs[0]), mx.inputs[0]); L.new(line(sep.outputs[1]), mx.inputs[1])
        # only on the floor
        fl = N.new("ShaderNodeMath"); fl.operation = 'LESS_THAN'; fl.inputs[1].default_value = 0.01
        L.new(sep.outputs[2], fl.inputs[0])
        g = N.new("ShaderNodeMath"); g.operation = 'MULTIPLY'; L.new(mx.outputs[0], g.inputs[0]); L.new(fl.outputs[0], g.inputs[1])
        g2 = N.new("ShaderNodeMath"); g2.operation = 'MULTIPLY'; g2.inputs[1].default_value = 0.10
        L.new(g.outputs[0], g2.inputs[0])
        mix = N.new("ShaderNodeMix"); mix.data_type = 'RGBA'
        L.new(g2.outputs[0], mix.inputs[0])
        L.new(col_out, mix.inputs[6])
        mix.inputs[7].default_value = (*srgb("#9fb2c8"), 1)
        col_out = mix.outputs[2]
    L.new(col_out, b.inputs["Base Color"])
    me.materials.append(m)
    return ob

# ----------------------------------------------------------------------------------------------
def light_rig(parent, az_deg, center, scale=1.0):
    """Lights placed relative to the camera azimuth (direction subject -> camera)."""
    tgt = empty("LightTarget", center, parent)
    def area(name, az, el, dist, power, size, color):
        l = bpy.data.lights.new(name, 'AREA'); l.energy = power * scale; l.size = size; l.color = color
        try: l.use_shadow_jitter = True
        except Exception: pass
        o = bpy.data.objects.new(name, l); scene.collection.objects.link(o)
        a = math.radians(az_deg + az); e = math.radians(el)
        o.location = Vector(center) + Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e))) * dist
        if parent: o.parent = parent
        c = o.constraints.new('TRACK_TO'); c.target = tgt; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'
        return o
    area("Key", -50, 48, 3.2, 230, 2.2, (1.0, 0.94, 0.86))
    area("Fill", 75, 18, 3.4, 70, 3.0, (0.78, 0.86, 1.0))
    area("Rim", 160, 32, 3.0, 380, 1.6, (1.0, 0.86, 0.70))
    area("Top", 0, 85, 3.5, 60, 3.0, (0.95, 0.97, 1.0))

def camera(loc, target, lens=50, parent=None):
    c = bpy.data.cameras.new("Cam"); c.lens = lens; c.clip_start = 0.05; c.clip_end = 100
    o = bpy.data.objects.new("Cam", c); scene.collection.objects.link(o)
    o.location = loc
    look_at(o, target)
    if parent: o.parent = parent
    scene.camera = o
    return o

# ----------------------------------------------------------------------------------------------
pivot = empty("Pivot")
arm.parent = pivot

def set_offset(dy):
    arm.location = (0, dy, 0)

def wire_overlay(thick=0.0022, color="#18222e"):
    w = bpy.data.objects.new("FoxWire", fox.data)
    scene.collection.objects.link(w)
    w.parent = arm
    a = w.modifiers.new("Armature", 'ARMATURE'); a.object = arm
    wm = w.modifiers.new("Wire", 'WIREFRAME'); wm.thickness = thick; wm.offset = 1.0
    wm.use_even_offset = True; wm.use_replace = True; wm.use_boundary = True
    wm.use_relative_offset = False
    m = new_mat("WireMat", srgb(color), 0.5)
    w.material_slots and None
    w.data.materials  # shared mesh: use object-linked material slot
    w.material_slots[0].link = 'OBJECT'
    w.material_slots[0].material = m
    return w

def ghost(alpha=0.22):
    m = new_mat("Ghost", srgb("#a9bdd2"), 0.4, alpha=alpha)
    fox.material_slots[0].link = 'OBJECT'
    fox.material_slots[0].material = m

def skeleton_viz():
    import bmesh
    bm = bmesh.new()
    groups = []  # (bone, [vert indices])
    vi = 0
    verts_by_bone = {}
    for b in arm.data.bones:
        if not b.use_deform: continue
        M = b.matrix_local
        h = M.translation.copy(); y = M.to_3x3().col[1].normalized(); x = M.to_3x3().col[0].normalized(); z = M.to_3x3().col[2].normalized()
        Lb = b.length
        w = max(0.006, min(0.018, 0.13 * Lb))
        waist = h + y * (Lb * 0.2)
        pts = [h, waist + x * w, waist + z * w, waist - x * w, waist - z * w, h + y * Lb]
        vs_ = [bm.verts.new(p) for p in pts]
        for i in range(4):
            a, c = vs_[1 + i], vs_[1 + (i + 1) % 4]
            bm.faces.new((vs_[0], c, a)); bm.faces.new((vs_[5], a, c))
        # joint ball
        jr = w * 0.85
        ring = []
        top = bm.verts.new(h + Vector((0, 0, jr))); bot = bm.verts.new(h - Vector((0, 0, jr)))
        for k in range(6):
            t = 2 * math.pi * k / 6
            ring.append(bm.verts.new(h + Vector((math.cos(t) * jr, math.sin(t) * jr, 0))))
        for k in range(6):
            bm.faces.new((top, ring[k], ring[(k + 1) % 6])); bm.faces.new((bot, ring[(k + 1) % 6], ring[k]))
        verts_by_bone[b.name] = (vs_ + ring + [top, bot], len(vs_))
    bm.verts.index_update()
    me = bpy.data.meshes.new("BoneViz")
    # remember indices before freeing
    idx = {n: [v.index for v in lst] for n, (lst, _) in verts_by_bone.items()}
    joint_idx = {n: [v.index for v in lst[nb:]] for n, (lst, nb) in verts_by_bone.items()}
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new("BoneViz", me); scene.collection.objects.link(ob)
    ob.parent = arm
    for n, ids in idx.items():
        g = ob.vertex_groups.new(name=n); g.add(ids, 1.0, 'REPLACE')
    md = ob.modifiers.new("Armature", 'ARMATURE'); md.object = arm
    mb = new_mat("BoneMat", srgb("#ff6a00"), 0.4, emit=srgb("#ff5a00"), emit_strength=0.9)
    mj = new_mat("JointMat", srgb("#fff1dc"), 0.4, emit=srgb("#ffe0b8"), emit_strength=0.8)
    me.materials.append(mb); me.materials.append(mj)
    jset = set(i for l in joint_idx.values() for i in l)
    for p in me.polygons:
        if all(v in jset for v in p.vertices): p.material_index = 1
    return ob

def before_mesh():
    me = fox.data.copy()
    ob = bpy.data.objects.new("FoxBefore", me); scene.collection.objects.link(ob)
    ob.parent = arm  # rest pose at origin (no armature modifier -> static)
    for p in me.polygons: p.use_smooth = True
    ss = ob.modifiers.new("Sub", 'SUBSURF'); ss.levels = 3; ss.render_levels = 3
    tex = bpy.data.textures.new("Noise", 'CLOUDS'); tex.noise_scale = 0.02; tex.noise_depth = 3
    dp = ob.modifiers.new("Disp", 'DISPLACE'); dp.texture = tex; dp.strength = 0.009; dp.mid_level = 0.5
    dg = bpy.context.evaluated_depsgraph_get()
    em = ob.evaluated_get(dg).to_mesh()
    tris = sum(len(p.vertices) - 2 for p in em.polygons)
    ob.evaluated_get(dg).to_mesh_clear()
    dec = ob.modifiers.new("Dec", 'DECIMATE'); dec.ratio = min(1.0, 120500 / tris)
    dg = bpy.context.evaluated_depsgraph_get()
    em = ob.evaluated_get(dg).to_mesh()
    tris2 = sum(len(p.vertices) - 2 for p in em.polygons)
    ob.evaluated_get(dg).to_mesh_clear()
    m = new_mat("Clay", srgb("#b8bcc4"), 0.55)
    ob.material_slots[0].link = 'OBJECT'; ob.material_slots[0].material = m
    json.dump({"before_tris": tris2}, open(os.path.join(WORK, "before_report.json"), "w"))
    print("BEFORE_TRIS", tris2)
    return ob

# ----------------------------------------------------------------------------------------------
# shots
TT_RATE = 360.0 / (30 * 9.0)  # deg per frame (one turn per 9 s)
TT_START = -35.0
CENTER = (0, 0, 0.36)

def turntable_keys(g0, g1):
    for g in range(g0, g1 + 1):
        pivot.rotation_euler = (0, 0, math.radians(TT_START + TT_RATE * g))
        pivot.keyframe_insert("rotation_euler", frame=g + 1)

def setup_turntable(cam_dist=2.85, lens=50, el=10.0, target=(0, 0, 0.30)):
    set_offset(-0.09)
    cyc = cyclorama(grid=False)
    cyc.rotation_euler = (0, 0, 0)   # wall on +Y, behind the subject (camera at -Y looking +Y)
    cyc.location = (0, 0, 0)
    e = math.radians(el)
    cam = camera((0, -cam_dist * math.cos(e), target[2] + cam_dist * math.sin(e)), target, lens)
    light_rig(None, -90, target)
    return cam

SHOTS = {
    "S1": (0, 95), "S2": (72, 215), "S3": (207, 305), "S4": (296, 410),
    "S5": (0, 104), "S6": (0, 89), "S7": (20, 94), "S8": (100, 174),
}
STILLS = {"still1", "still2", "still3"}

def act(name):
    arm.animation_data.action = bpy.data.actions[name]
    try:
        if arm.animation_data.action_slot is None:
            arm.animation_data.action_slot = bpy.data.actions[name].slots[0]
    except Exception as ex:
        print("SLOT", ex)

frames = None
outdir = os.path.join(WORK, "frames", SHOT)

if SHOT in ("S1", "S2", "S3", "S4"):
    setup_turntable()
    g0, g1 = SHOTS[SHOT]
    turntable_keys(g0, g1)
    act("Idle")
    if SHOT == "S1":
        before_mesh()
        fox.hide_render = True
        act("Idle"); arm.animation_data.action = None
        for pb in arm.pose.bones: pb.matrix_basis = Matrix.Identity(4)
    elif SHOT == "S3":
        wire_overlay()
    elif SHOT == "S4":
        ghost(0.20)
        wire_overlay(0.0012, "#6f8aa8")
        skeleton_viz()
    frames = list(range(g0 + 1, g1 + 2))

elif SHOT in ("S5", "S6", "still3"):
    act("Walk")
    set_offset(0.0)
    cyc = cyclorama(grid=True)
    g0, g1 = SHOTS.get(SHOT, (0, 0))
    for g in range(g0, max(g1, 30) + 1):
        pivot.location = (0, -WALK_V * g, 0)
        pivot.keyframe_insert("location", frame=g + 1)
    if SHOT == "S5":
        cyc.rotation_euler = (0, 0, math.radians(90))
        cam = camera((2.85, 0.05, 0.62), (0, 0.08, 0.36), 50, parent=pivot)
        light_rig(pivot, 0, (0, 0.08, 0.36))
    else:
        az = -48
        cyc.rotation_euler = (0, 0, math.radians(az + 90))
        a = math.radians(az)
        d = 2.65
        cam = camera((math.cos(a) * d, math.sin(a) * d, 0.95), (0, 0.02, 0.33), 50, parent=pivot)
        light_rig(pivot, az, (0, 0.05, 0.36))
    frames = list(range(g0 + 1, g1 + 2))
    if SHOT == "still3":
        frames = [int(FRAMES)] if FRAMES not in ("all",) else [8]

elif SHOT in ("S7", "S8", "still1", "still2"):
    act("Idle")
    set_offset(0.0)
    cyc = cyclorama(grid=False)
    if SHOT == "S7":
        az = -62
        a = math.radians(az)
        tgt = (0.0, -0.36, 0.56)
        cam = camera((tgt[0] + math.cos(a) * 1.5, tgt[1] + math.sin(a) * 1.5, 0.80), tgt, 55)
    elif SHOT == "S8":
        az = -60
        a = math.radians(az)
        tgt = (-0.46, -0.175, 0.36)
        cam = camera((math.cos(a) * 2.7, math.sin(a) * 2.7 + 0.1, 0.80), tgt, 50)
    elif SHOT == "still1":
        az = -58
        a = math.radians(az)
        tgt = (0.0, 0.08, 0.37)
        cam = camera((math.cos(a) * 2.55, math.sin(a) * 2.55 + 0.08, 0.86), tgt, 50)
    else:  # still2: wireframe + skeleton, side 3/4
        az = -30
        a = math.radians(az)
        tgt = (0.0, 0.09, 0.38)
        cam = camera((math.cos(a) * 2.6, math.sin(a) * 2.6 + 0.09, 0.80), tgt, 50)
        ghost(0.30)
        wire_overlay(0.0016, "#5d7896")
        skeleton_viz()
    cyc.rotation_euler = (0, 0, math.radians(az + 90))
    light_rig(None, az, (0, 0.0, 0.38))
    if SHOT in SHOTS:
        g0, g1 = SHOTS[SHOT]
        frames = list(range(g0 + 1, g1 + 2))
    else:
        frames = [int(FRAMES)] if FRAMES != "all" else [1]

elif SHOT.startswith("BEND"):
    # weight check: strong poses on every joint group
    arm.animation_data.action = None
    set_offset(0.0)
    cyc = cyclorama(grid=False)
    from mathutils import Euler
    def rot(n, x=0, y=0, z=0):
        pb = arm.pose.bones[n]; pb.rotation_mode = 'XYZ'
        pb.rotation_euler = Euler((math.radians(x), math.radians(y), math.radians(z)))
    rot("Spine1", 0, 0, 12); rot("Spine2", 0, 0, 12)
    rot("Neck", 25, 0, 20); rot("Head", -20, 0, 25)
    for i in range(4): rot(f"Tail{i + 1}", 12, 0, 25)
    rot("BackThighL", -35); rot("BackShinL", 40); rot("BackFootL", -30)
    rot("BackThighR", 30); rot("BackShinR", -20)
    rot("FrontUpperL", 40); rot("FrontLowerL", -60); rot("FrontFootL", 40)
    rot("FrontUpperR", -30)
    rot("EarL", -30, 0, -15)
    az = {"BEND": -45, "BEND2": 40, "BEND3": 180}.get(SHOT, -45)
    a = math.radians(az)
    tgt = (0.0, 0.05, 0.38)
    cam = camera((math.cos(a) * 2.5, math.sin(a) * 2.5 + 0.05, 1.3), tgt, 50)
    cyc.rotation_euler = (0, 0, math.radians(az + 90))
    light_rig(None, az, tgt)
    frames = [1]
    if SHOT.endswith("W"): wire_overlay()

# cyclorama orientation helper: wall must be opposite the camera.
cam = scene.camera
# ----------------------------------------------------------------------------------------------
if FRAMES != "all" and SHOT not in STILLS:
    frames = [int(x) for x in FRAMES.split(",")]
    outdir = os.path.join(WORK, "preview", SHOT)
os.makedirs(outdir, exist_ok=True)

if SHOT in STILLS:
    ee.taa_render_samples = max(SAMPLES, 128)
    scene.frame_set(frames[0])
    r.filepath = os.path.join(OUT, "..", f"rigged-fox-{SHOT[-1]}.png") if len(argv) > 3 and argv[3] == "final" else os.path.join(WORK, "preview", f"{SHOT}.png")
    os.makedirs(os.path.dirname(r.filepath), exist_ok=True)
    bpy.ops.render.render(write_still=True)
else:
    for f in frames:
        scene.frame_set(f)
        r.filepath = os.path.join(outdir, f"f_{f:05d}.png")
        bpy.ops.render.render(write_still=True)
print("DONE", SHOT, len(frames))
