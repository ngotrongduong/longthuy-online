# Procedural low-poly fox: mesh, palette texture, armature, skin weights, Idle + Walk actions, exports.
# Run: blender --background --factory-startup --python build_fox.py
import bpy, bmesh, math, os, json
from mathutils import Vector, Matrix, Quaternion

OUT = r"C:\Ai kiem tien\portfolio\rigged-fox"
WORK = os.path.join(OUT, "work")
for _o in list(bpy.data.objects):   # empty the factory scene (cube, light, camera)
    bpy.data.objects.remove(_o, do_unlink=True)

# ----------------------------------------------------------------------------------------------
# helpers
def lerp(a, b, t): return a + (b - a) * t
def smooth(t): t = max(0.0, min(1.0, t)); return t * t * (3 - 2 * t)

def catmull(p0, p1, p2, p3, t):
    t2, t3 = t * t, t * t * t
    return tuple(0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3)
                 for a, b, c, d in zip(p0, p1, p2, p3))

def densify(rows, sub=2):
    """Insert Catmull-Rom points between rows (tuples of floats)."""
    out = []
    n = len(rows)
    for i in range(n - 1):
        p0 = rows[max(i - 1, 0)]; p1 = rows[i]; p2 = rows[i + 1]; p3 = rows[min(i + 2, n - 1)]
        for s in range(sub):
            out.append(catmull(p0, p1, p2, p3, s / sub))
    out.append(rows[-1])
    return out

# palette: index -> sRGB
PALETTE = [
    (0.93, 0.47, 0.16),  # 0 orange
    (0.80, 0.35, 0.11),  # 1 dark orange (saddle)
    (0.97, 0.91, 0.82),  # 2 cream
    (0.22, 0.15, 0.13),  # 3 dark brown (legs, ear tips)
    (0.07, 0.06, 0.06),  # 4 black (nose, eyes)
    (0.93, 0.78, 0.70),  # 5 ear inner
    (1.00, 1.00, 1.00),  # 6 white (eye highlight)
    (0.99, 0.96, 0.90),  # 7 tail tip
]
ORANGE, SADDLE, CREAM, DARK, BLACK, EARIN, WHITE, TIP = range(8)
GRID = 4  # 4x4 swatches on a 256 px image

verts, faces, fcol, vpart = [], [], [], []   # vpart: part tag per vertex

def add_v(p, part):
    verts.append(Vector(p)); vpart.append(part); return len(verts) - 1

def add_f(idx, col):
    faces.append(tuple(idx)); fcol.append(col)

# ----------------------------------------------------------------------------------------------
# BODY (rump -> nose): vertical rings at stations (y, top, bottom, halfwidth)
BODY = [
    (0.318, 0.440, 0.395, 0.020),
    (0.300, 0.472, 0.340, 0.060),
    (0.270, 0.490, 0.312, 0.090),
    (0.220, 0.496, 0.300, 0.105),
    (0.160, 0.490, 0.310, 0.100),
    (0.100, 0.486, 0.325, 0.092),
    (0.040, 0.486, 0.330, 0.090),
    (-0.020, 0.490, 0.320, 0.094),
    (-0.080, 0.500, 0.305, 0.102),
    (-0.130, 0.510, 0.295, 0.104),
    (-0.175, 0.530, 0.292, 0.100),
    (-0.210, 0.560, 0.322, 0.096),
    (-0.245, 0.600, 0.385, 0.092),
    (-0.275, 0.632, 0.440, 0.092),
    (-0.305, 0.650, 0.468, 0.095),
    (-0.335, 0.655, 0.483, 0.102),
    (-0.365, 0.648, 0.498, 0.106),
    (-0.395, 0.630, 0.513, 0.088),
    (-0.420, 0.615, 0.523, 0.070),
    (-0.445, 0.598, 0.528, 0.052),
    (-0.470, 0.584, 0.530, 0.038),
    (-0.500, 0.573, 0.531, 0.030),
    (-0.525, 0.567, 0.533, 0.024),
    (-0.545, 0.563, 0.536, 0.016),
    (-0.555, 0.558, 0.540, 0.008),
]
NB = 16
EXP = 0.85

def body_ring_point(y, top, bot, hw, k, n=NB):
    th = 2 * math.pi * k / n          # 0 = top, pi/2 = +x side, pi = bottom
    s, c = math.sin(th), math.cos(th)
    sx = math.copysign(abs(s) ** EXP, s)
    cz = math.copysign(abs(c) ** EXP, c)
    mid = bot + (top - bot) * 0.55
    x = hw * sx
    z = mid + ((top - mid) if c >= 0 else (mid - bot)) * cz
    # cheek tufts: push the lower side outward on the cheeks
    cheek = math.exp(-((y + 0.362) / 0.026) ** 2)
    ang = math.exp(-((abs(th if th <= math.pi else 2 * math.pi - th) - 1.95) / 0.32) ** 2)
    x += math.copysign(0.040 * cheek * ang, sx if sx != 0 else 1)
    z -= 0.012 * cheek * ang
    # chest ruff: bottom of the throat pushed slightly down/forward
    ruff = math.exp(-((y + 0.235) / 0.035) ** 2) * max(0.0, -c) ** 2
    z -= 0.012 * ruff
    return (x, y, z), th

rows = densify(BODY, 2)
ring_idx = []
ring_theta = []
for (y, top, bot, hw) in rows:
    r = []
    th_list = []
    for k in range(NB):
        p, th = body_ring_point(y, top, bot, hw, k)
        r.append(add_v(p, 'body')); th_list.append(th)
    ring_idx.append(r); ring_theta.append(th_list)

def body_color(yc, thc, zc):
    # thc: angle 0 top .. pi bottom (folded)
    if yc < -0.538: return BLACK
    if yc < -0.30:                     # head
        if thc > 1.75: return CREAM    # jaw, cheeks, under snout
        return ORANGE
    if yc < -0.12:                     # neck / chest
        lim = 1.95 if yc > -0.2 else 1.75
        if thc > lim: return CREAM
        return ORANGE
    if yc < 0.25:
        if thc > 2.55: return CREAM    # belly
        if thc < 0.42 and yc > -0.2: return SADDLE
        return ORANGE
    return ORANGE

for i in range(len(ring_idx) - 1):
    a, b = ring_idx[i], ring_idx[i + 1]
    for k in range(NB):
        k2 = (k + 1) % NB
        quad = (a[k], a[k2], b[k2], b[k])
        cen = sum((verts[q] for q in quad), Vector()) / 4
        thm = (ring_theta[i][k] + ((ring_theta[i][k2]) if k2 != 0 else 2 * math.pi)) / 2
        thf = thm if thm <= math.pi else 2 * math.pi - thm
        add_f(quad, body_color(cen.y, thf, cen.z))
# caps
for ring, col in ((ring_idx[0], ORANGE), (ring_idx[-1], BLACK)):
    cen = sum((verts[q] for q in ring), Vector()) / NB
    cen.y += 0.006 if ring is ring_idx[0] else -0.004
    ci = add_v(cen, 'body')
    for k in range(NB):
        add_f((ring[k], ring[(k + 1) % NB], ci), col)

# ----------------------------------------------------------------------------------------------
# generic tube along a path in the YZ plane (rings perpendicular to the tangent)
def tube(stations, x, n, part, color_fn, jag=0.0, cap_end=True, cap_start=True, flatten_ground=False):
    pts = [Vector((x, s[0], s[1])) for s in stations]
    rings = []
    for i, s in enumerate(stations):
        p = pts[i]
        t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        u = Vector((1, 0, 0))
        v = t.cross(u).normalized()
        rs, ro = s[2], s[3]
        r = []
        for k in range(n):
            th = 2 * math.pi * k / n
            f = 1.0 - (jag if k % 2 else 0.0)
            q = p + u * (math.sin(th) * rs * f) + v * (math.cos(th) * ro * f)
            if flatten_ground and q.z < 0.0: q.z = 0.0
            r.append(add_v(q, part))
        rings.append(r)
    L = len(rings)
    for i in range(L - 1):
        for k in range(n):
            k2 = (k + 1) % n
            quad = (rings[i][k], rings[i][k2], rings[i + 1][k2], rings[i + 1][k])
            add_f(quad, color_fn(i / (L - 1), k, n))
    if cap_start:
        c = add_v(pts[0] - (pts[1] - pts[0]).normalized() * 0.004, part)
        for k in range(n): add_f((rings[0][k], rings[0][(k + 1) % n], c), color_fn(0.0, k, n))
    if cap_end:
        c = add_v(pts[-1] + (pts[-1] - pts[-2]).normalized() * 0.006, part)
        for k in range(n): add_f((rings[-1][k], rings[-1][(k + 1) % n], c), color_fn(1.0, k, n))
    return rings

# ----------------------------------------------------------------------------------------------
# LEGS  joints (y, z)
HIND = dict(x=0.057, J=[(0.200, 0.420), (0.150, 0.245), (0.240, 0.110), (0.222, 0.026), (0.178, 0.016)])
FRONT = dict(x=0.052, J=[(-0.150, 0.420), (-0.070, 0.258), (-0.128, 0.095), (-0.140, 0.026), (-0.184, 0.016)])

def leg_stations(J, top_r, kind):
    (h, k, a, b, t) = J
    mid = lambda p, q, w=0.5: (lerp(p[0], q[0], w), lerp(p[1], q[1], w))
    if kind == 'hind':
        st = [
            ((h[0] + 0.004, h[1] + 0.03), 0.030, 0.036),
            (h, top_r, top_r + 0.012),
            (mid(h, k, 0.5), 0.047, 0.058),
            (k, 0.036, 0.042),
            (mid(k, a), 0.027, 0.030),
            (a, 0.021, 0.025),
        ]
    else:
        st = [
            ((h[0] - 0.002, h[1] + 0.03), 0.032, 0.036),
            (h, top_r, top_r + 0.010),
            (mid(h, k, 0.5), 0.038, 0.048),
            (k, 0.034, 0.038),
            (mid(k, a), 0.026, 0.028),
            (a, 0.021, 0.023),
        ]
    st += [
        (mid(a, b), 0.019, 0.020),
        (b, 0.027, 0.026),
        (mid(b, t), 0.027, 0.019),
        (t, 0.016, 0.012),
    ]
    rows = [(p[0], p[1], rs, ro) for (p, rs, ro) in st]
    return densify(rows, 2)

def leg_color(kind):
    def fn(u, k, n):
        # u along the tube 0 (top) .. 1 (toe tip)
        dark_from = 0.36 if kind == 'hind' else 0.30
        if u > 0.80: return BLACK if u > 0.97 else DARK
        if u > dark_from: return DARK
        return ORANGE
    return fn

legs_info = {}
for side, sx in (('L', 1), ('R', -1)):
    for kind, D in (('hind', HIND), ('front', FRONT)):
        x = D['x'] * sx
        st = leg_stations(D['J'], 0.045 if kind == 'hind' else 0.040, kind)
        tube(st, x, 10, f'{kind}{side}', leg_color(kind), flatten_ground=True)

# ----------------------------------------------------------------------------------------------
# TAIL
TAIL = [
    (0.270, 0.445, 0.035, 0.035),
    (0.320, 0.440, 0.046, 0.048),
    (0.370, 0.420, 0.062, 0.066),
    (0.425, 0.385, 0.075, 0.080),
    (0.480, 0.340, 0.083, 0.088),
    (0.535, 0.292, 0.085, 0.089),
    (0.590, 0.252, 0.081, 0.084),
    (0.640, 0.228, 0.071, 0.073),
    (0.685, 0.220, 0.056, 0.056),
    (0.722, 0.225, 0.036, 0.036),
    (0.748, 0.236, 0.014, 0.014),
]
def tail_color(u, k, n):
    return TIP if u > 0.70 else ORANGE
tube(densify(TAIL, 2), 0.0, 12, 'tail', tail_color, jag=0.07)

# ----------------------------------------------------------------------------------------------
# EARS
EAR_H, EAR_W, EAR_D = 0.118, 0.094, 0.036
EAR_BASE = Vector((0.052, -0.328, 0.634))
ear_tips = {}
def build_ear(side):
    sx = 1 if side == 'L' else -1
    rot = Matrix.Rotation(math.radians(13 * sx), 3, 'Y') @ Matrix.Rotation(math.radians(-9), 3, 'X')
    base = Vector((EAR_BASE.x * sx, EAR_BASE.y, EAR_BASE.z))
    prof = [(-0.5, 0.0), (-0.22, -0.5), (0.0, -0.12), (0.22, -0.5), (0.5, 0.0), (0.0, 0.55)]
    levels = [(0.0, 1.0), (0.45, 0.74), (0.78, 0.38)]
    rings = []
    for (hz, sc) in levels:
        r = []
        for (a, b) in prof:
            lp = Vector((a * EAR_W * sc * sx, b * EAR_D * sc, hz * EAR_H))
            r.append(add_v(base + rot @ lp, 'ear' + side))
        rings.append(r)
    apex_l = Vector((0.010 * sx, 0.004, EAR_H))
    apex = add_v(base + rot @ apex_l, 'ear' + side)
    ear_tips[side] = (base, base + rot @ apex_l)
    n = len(prof)
    front = {1, 2}  # segments (1-2), (2-3) are the inner face
    for i in range(len(rings) - 1):
        for k in range(n):
            k2 = (k + 1) % n
            if k in front:
                col = EARIN if i == 0 else DARK
            else:
                col = ORANGE if i == 0 else DARK
            add_f((rings[i][k], rings[i][k2], rings[i + 1][k2], rings[i + 1][k]), col)
    for k in range(n):
        add_f((rings[-1][k], rings[-1][(k + 1) % n], apex), DARK)
    c = add_v(base - rot @ Vector((0, 0, 0.01)), 'ear' + side)
    for k in range(n):
        add_f((rings[0][(k + 1) % n], rings[0][k], c), ORANGE)
build_ear('L'); build_ear('R')

# ----------------------------------------------------------------------------------------------
# EYES (low-poly ellipsoids + a tiny highlight)
def ellipsoid(center, radii, rotz, part, col, seg=8, rings=5):
    R3 = Matrix.Rotation(rotz, 3, 'Z')
    top = add_v(center + R3 @ Vector((0, 0, radii[2])), part)
    bot = add_v(center + R3 @ Vector((0, 0, -radii[2])), part)
    rr = []
    for j in range(1, rings):
        phi = math.pi * j / rings
        r = []
        for k in range(seg):
            th = 2 * math.pi * k / seg
            lp = Vector((math.sin(phi) * math.cos(th) * radii[0], math.sin(phi) * math.sin(th) * radii[1], math.cos(phi) * radii[2]))
            r.append(add_v(center + R3 @ lp, part))
        rr.append(r)
    for k in range(seg):
        k2 = (k + 1) % seg
        add_f((top, rr[0][k], rr[0][k2]), col)
        add_f((bot, rr[-1][k2], rr[-1][k]), col)
    for j in range(len(rr) - 1):
        for k in range(seg):
            k2 = (k + 1) % seg
            add_f((rr[j][k], rr[j + 1][k], rr[j + 1][k2], rr[j][k2]), col)

for sx in (1, -1):
    c = Vector((0.054 * sx, -0.418, 0.598))
    ellipsoid(c, (0.011, 0.017, 0.013), math.radians(-18 * sx), 'head', BLACK)
    ellipsoid(c + Vector((0.008 * sx, -0.008, 0.006)), (0.0045, 0.0045, 0.0045), 0.0, 'head', WHITE, seg=4, rings=2)

# ----------------------------------------------------------------------------------------------
# MESH OBJECT
me = bpy.data.meshes.new("FoxMesh")
me.from_pydata([tuple(v) for v in verts], [], faces)
me.update()
bm = bmesh.new(); bm.from_mesh(me)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(me); bm.free()
for p in me.polygons: p.use_smooth = False

# palette texture
IMG = 256
img = bpy.data.images.new("fox_palette", IMG, IMG, alpha=False)
px = [0.0] * (IMG * IMG * 4)
cell = IMG // GRID
for yy in range(IMG):
    for xx in range(IMG):
        idx = (yy // cell) * GRID + (xx // cell)
        col = PALETTE[idx] if idx < len(PALETTE) else (0.5, 0.5, 0.5)
        o = (yy * IMG + xx) * 4
        px[o:o + 4] = [col[0], col[1], col[2], 1.0]
img.pixels = px
pal_path = os.path.join(OUT, "fox_palette.png")
img.filepath_raw = pal_path; img.file_format = 'PNG'; img.save()
img.filepath = pal_path
img.pack()

uv = me.uv_layers.new(name="UVMap")
for poly, col in zip(me.polygons, fcol):
    cx = ((col % GRID) + 0.5) / GRID
    cy = ((col // GRID) + 0.5) / GRID
    n = poly.loop_total
    for j, li in enumerate(range(poly.loop_start, poly.loop_start + n)):
        a = 2 * math.pi * j / n
        uv.data[li].uv = (cx + 0.03 * math.cos(a), cy + 0.03 * math.sin(a))

mat = bpy.data.materials.new("FoxPalette")
mat.use_nodes = True
nt = mat.node_tree
bsdf = nt.nodes.get("Principled BSDF")
tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = img; tex.interpolation = 'Closest'
nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Roughness"].default_value = 0.72
me.materials.append(mat)

fox = bpy.data.objects.new("Fox", me)
bpy.context.scene.collection.objects.link(fox)

# ----------------------------------------------------------------------------------------------
# ARMATURE
def P(y, z, x=0.0): return Vector((x, y, z))
def tail_path_points():
    pts = [Vector((0, s[0], s[1])) for s in densify(TAIL, 8)]
    # cumulative length
    L = [0.0]
    for i in range(1, len(pts)): L.append(L[-1] + (pts[i] - pts[i - 1]).length)
    def at(f):
        tgt = f * L[-1]
        for i in range(1, len(pts)):
            if L[i] >= tgt:
                w = (tgt - L[i - 1]) / max(L[i] - L[i - 1], 1e-9)
                return pts[i - 1].lerp(pts[i], w)
        return pts[-1]
    return [at(f) for f in (0.0, 0.24, 0.48, 0.72, 0.97)]

BONES = []  # (name, head, tail, parent, connect, deform)
BONES.append(("Root", P(0, 0), P(0, 0) + Vector((0, 0, 0.12)), None, False, False))
BONES.append(("Hips", P(0.230, 0.430), P(0.080, 0.425), "Root", False, True))
BONES.append(("Spine1", P(0.080, 0.425), P(-0.060, 0.430), "Hips", True, True))
BONES.append(("Spine2", P(-0.060, 0.430), P(-0.180, 0.450), "Spine1", True, True))
BONES.append(("Neck", P(-0.180, 0.450), P(-0.300, 0.545), "Spine2", True, True))
BONES.append(("Head", P(-0.300, 0.545), P(-0.520, 0.555), "Neck", True, True))
for side in ('L', 'R'):
    b, t = ear_tips[side]
    BONES.append(("Ear" + side, b.copy(), t.copy(), "Head", False, True))
tp = tail_path_points()
for i in range(4):
    BONES.append((f"Tail{i + 1}", tp[i], tp[i + 1], "Hips" if i == 0 else f"Tail{i}", i > 0, True))
LEGNAMES = {'hind': ["BackThigh", "BackShin", "BackFoot", "BackToe"],
            'front': ["FrontUpper", "FrontLower", "FrontFoot", "FrontToe"]}
for side, sx in (('L', 1), ('R', -1)):
    for kind, D in (('hind', HIND), ('front', FRONT)):
        J = D['J']; x = D['x'] * sx
        names = [n + side for n in LEGNAMES[kind]]
        for i in range(4):
            BONES.append((names[i], P(J[i][0], J[i][1], x), P(J[i + 1][0], J[i + 1][1], x),
                          ("Hips" if kind == 'hind' else "Spine2") if i == 0 else names[i - 1], i > 0, True))

arm_data = bpy.data.armatures.new("FoxRig")
arm = bpy.data.objects.new("FoxRig", arm_data)
bpy.context.scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
arm.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
eb = arm_data.edit_bones
for (name, h, t, parent, connect, deform) in BONES:
    b = eb.new(name)
    b.head = h; b.tail = t
    d = (t - h).normalized()
    up = Vector((1, 0, 0)).cross(d)
    if up.length < 1e-4: up = Vector((0, -1, 0))
    b.align_roll(up)
    b.use_deform = deform
for (name, h, t, parent, connect, deform) in BONES:
    if parent:
        eb[name].parent = eb[parent]
        eb[name].use_connect = connect
bpy.ops.object.mode_set(mode='OBJECT')
arm_data.display_type = 'OCTAHEDRAL'

# ----------------------------------------------------------------------------------------------
# SKIN WEIGHTS (rule based: inverse distance to bone segments within each part's bone set)
bone_seg = {name: (h, t) for (name, h, t, *_r) in BONES}
def seg_dist(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
    return (p - (a + ab * t)).length

PART_BONES = {
    'body': (["Hips", "Spine1", "Spine2", "Neck", "Head"], 6),
    'tail': (["Tail1", "Tail2", "Tail3", "Tail4"], 6),
    'head': (["Head"], 1),
    'earL': (["EarL"], 1), 'earR': (["EarR"], 1),
}
for side in ('L', 'R'):
    PART_BONES['hind' + side] = ([n + side for n in LEGNAMES['hind']], 8)
    PART_BONES['front' + side] = ([n + side for n in LEGNAMES['front']], 8)

vgroups = {}
for (name, *_r) in BONES:
    if name != "Root":
        vgroups[name] = fox.vertex_groups.new(name=name)
max_infl = 0
for vi, (co, part) in enumerate(zip(verts, vpart)):
    names, pw = PART_BONES[part]
    if len(names) == 1:
        w = {names[0]: 1.0}
    else:
        raw = {}
        for n in names:
            d = seg_dist(co, *bone_seg[n])
            raw[n] = 1.0 / (d + 0.004) ** pw
        top = sorted(raw.items(), key=lambda kv: -kv[1])[:4]
        s = sum(v for _, v in top)
        w = {n: v / s for n, v in top if v / s >= 0.03}
        s = sum(w.values())
        w = {n: v / s for n, v in w.items()}
    max_infl = max(max_infl, len(w))
    for n, v in w.items():
        vgroups[n].add([vi], v, 'REPLACE')

fox.parent = arm
mod = fox.modifiers.new("Armature", 'ARMATURE'); mod.object = arm

# ----------------------------------------------------------------------------------------------
# ANIMATION (own FK + 2D leg IK -> per-frame bone basis keys)
bones = arm.data.bones
R = {b.name: b.matrix_local.copy() for b in bones}
PARENT = {b.name: (b.parent.name if b.parent else None) for b in bones}
def depth(n):
    d = 0
    while PARENT[n]: n = PARENT[n]; d += 1
    return d
ORDER = sorted([b.name for b in bones], key=depth)
I4 = Matrix.Identity(4)

def eul(x=0.0, y=0.0, z=0.0):
    from mathutils import Euler
    return Euler((math.radians(x), math.radians(y), math.radians(z)), 'XYZ').to_matrix().to_4x4()

def fk_one(n, M, B):
    p = PARENT[n]
    if p is None: return R[n] @ B
    return M[p] @ (R[p].inverted() @ R[n]) @ B

def basis_from_M(n, M, Mb):
    p = PARENT[n]
    if p is None: return R[n].inverted() @ Mb
    return (R[p].inverted() @ R[n]).inverted() @ M[p].inverted() @ Mb

def yz(v): return (v.y, v.z)
def ang(v): return math.atan2(v[1], v[0])
def cross2(a, b): return a[0] * b[1] - a[1] * b[0]

LEGS = []
for side, sx in (('L', 1), ('R', -1)):
    for kind in ('hind', 'front'):
        names = [n + side for n in LEGNAMES[kind]]
        J = [bone_seg[names[0]][0]] + [bone_seg[n][1] for n in names]
        Js = [yz(j) for j in J]
        L = [math.dist(Js[i], Js[i + 1]) for i in range(4)]
        a3 = ang((Js[3][0] - Js[2][0], Js[3][1] - Js[2][1]))
        a4 = ang((Js[4][0] - Js[3][0], Js[4][1] - Js[3][1]))
        s = 1 if cross2((Js[2][0] - Js[0][0], Js[2][1] - Js[0][1]), (Js[1][0] - Js[0][0], Js[1][1] - Js[0][1])) > 0 else -1
        LEGS.append(dict(names=names, kind=kind, side=side, x=J[0].x, ball=Js[3], L=L, a3=a3, a4=a4, s=s))

reach_err = [0.0]
def solve_leg(leg, M, ball, da3=0.0, da4=0.0):
    n1, n2, n3, n4 = leg['names']
    L1, L2, L3, L4 = leg['L']
    J0 = fk_one(n1, M, I4).translation  # posed hip / shoulder
    j0 = (J0.y, J0.z)
    a3 = leg['a3'] + da3; a4 = leg['a4'] + da4
    j2 = (ball[0] - L3 * math.cos(a3), ball[1] - L3 * math.sin(a3))
    dv = (j2[0] - j0[0], j2[1] - j0[1]); d = math.hypot(*dv)
    dmax = (L1 + L2) * 0.9995
    if d > dmax:
        reach_err[0] = max(reach_err[0], d - dmax)
        dv = (dv[0] * dmax / d, dv[1] * dmax / d); d = dmax
        j2 = (j0[0] + dv[0], j0[1] + dv[1])
    ca = (L1 * L1 + d * d - L2 * L2) / (2 * L1 * d)
    al = math.acos(max(-1.0, min(1.0, ca))) * leg['s']
    base = ang(dv)
    j1 = (j0[0] + L1 * math.cos(base + al), j0[1] + L1 * math.sin(base + al))
    j3 = (j2[0] + L3 * math.cos(a3), j2[1] + L3 * math.sin(a3))
    j4 = (j3[0] + L4 * math.cos(a4), j3[1] + L4 * math.sin(a4))
    pts = [j0, j1, j2, j3, j4]
    x = J0.x
    for i, n in enumerate(leg['names']):
        h = Vector((x, pts[i][0], pts[i][1])); t = Vector((x, pts[i + 1][0], pts[i + 1][1]))
        d_new = (t - h).normalized()
        d_old = R[n].to_3x3().col[1].normalized()
        a = math.atan2(d_old.y * d_new.z - d_old.z * d_new.y, d_old.y * d_new.y + d_old.z * d_new.z)
        Mb = Matrix.Translation(h) @ Matrix.Rotation(a, 4, 'X') @ R[n].to_3x3().to_4x4()
        M[n] = Mb

def pose(body, legs_targets, head_world=None):
    """body: dict bone -> basis Matrix (non-leg bones). legs_targets: list of (ball, da3, da4) per LEGS."""
    M = {}
    basis = {}
    for n in ORDER:
        if any(n in lg['names'] for lg in LEGS): continue
        if n == "Head" and head_world is not None:
            Mn = fk_one(n, M, I4)
            Mb = Matrix.Translation(Mn.translation) @ head_world.to_4x4() @ R[n].to_3x3().to_4x4()
            M[n] = Mb
            basis[n] = basis_from_M(n, M, Mb)
            continue
        B = body.get(n, I4)
        M[n] = fk_one(n, M, B)
        basis[n] = B
    for lg, tg in zip(LEGS, legs_targets):
        solve_leg(lg, M, *tg)
        for n in lg['names']:
            basis[n] = basis_from_M(n, M, M[n])
    return basis

def hips_loc(dy=0.0, dz=0.0):
    return R["Hips"].to_3x3().transposed() @ Vector((0, dy, dz))

def ear_twitch(t, t0, dur=11):
    u = (t - t0)
    if u < 0 or u > dur: return 0.0
    if u < 3: return smooth(u / 3)
    if u < 5: return 1.0
    return 1.0 - smooth((u - 5) / (dur - 5))

# ---- WALK
WALK_T = 24
DUTY = 0.62
STRIDE_R = 0.17            # foot travel relative to the body during stance (m)
WALK_D = STRIDE_R / DUTY   # distance the body travels per cycle
WALK_V = WALK_D / WALK_T   # m per frame
PHASE = {('hind', 'L'): 0.0, ('front', 'L'): 0.25, ('hind', 'R'): 0.5, ('front', 'R'): 0.75}
LIFT = {'hind': 0.045, 'front': 0.055}

def walk_frame(f):
    t = f / WALK_T
    w = 2 * math.pi * t
    body = {}
    body["Hips"] = Matrix.Translation(hips_loc(0, 0.006 * math.cos(2 * w))) @ eul(1.2 * math.sin(2 * w), 2.5 * math.sin(w), 2.0 * math.sin(w))
    body["Spine1"] = eul(-0.6 * math.sin(2 * w), -1.0 * math.sin(w), -1.2 * math.sin(w))
    body["Spine2"] = eul(-0.6 * math.sin(2 * w), -1.0 * math.sin(w), -1.2 * math.sin(w))
    body["Neck"] = eul(0.8 * math.sin(2 * w + 0.6), 0, 0)
    for i in range(4):
        body[f"Tail{i + 1}"] = eul(4.0 - 1.2 * i + 2.0 * math.sin(2 * w - 0.7 * (i + 1)), 0,
                                   (4 + 3 * i) * math.sin(w - 0.8 * (i + 1)))
    body["EarL"] = eul(3 * math.sin(2 * w - 1.0), 0, 0)
    body["EarR"] = eul(3 * math.sin(2 * w - 1.0), 0, 0)
    head_world = Matrix.Rotation(math.radians(1.2 * math.sin(2 * w + 1.0)), 3, 'X') @ Matrix.Rotation(math.radians(1.5 * math.sin(w)), 3, 'Z')
    targets = []
    for lg in LEGS:
        p = (t + PHASE[(lg['kind'], lg['side'])]) % 1.0
        y0, z0 = lg['ball']
        if p < DUTY:
            u = p / DUTY
            y = y0 - STRIDE_R / 2 + STRIDE_R * u
            z = z0; da3 = 0.0; da4 = 0.0
            if u > 0.8:   # heel starts to peel off
                da3 = -math.radians(12) * smooth((u - 0.8) / 0.2) * (1 if lg['kind'] == 'hind' else 0.6)
        else:
            s = (p - DUTY) / (1 - DUTY)
            y = y0 + STRIDE_R / 2 - STRIDE_R * smooth(s)
            z = z0 + LIFT[lg['kind']] * math.sin(math.pi * s) ** 1.3
            flex = math.sin(math.pi * min(1.0, s * 1.15))
            da3 = math.radians(40 if lg['kind'] == 'hind' else 65) * flex - math.radians(12) * (1 - smooth(s / 0.2)) * (1 if lg['kind'] == 'hind' else 0.6)
            da4 = math.radians(35) * math.sin(math.pi * s)
        targets.append(((y, z), da3, da4))
    return pose(body, targets, head_world)

# ---- IDLE
IDLE_T = 120
def idle_frame(f):
    t = f / IDLE_T
    w = 2 * math.pi * t
    br = math.sin(2 * w)                      # 2 breaths per loop
    body = {}
    body["Hips"] = Matrix.Translation(hips_loc(0, 0.0025 * br)) @ eul(0.4 * br, 0, 0)
    body["Spine1"] = eul(-0.8 * br, 0, 0)
    body["Spine2"] = eul(-1.0 * br, 0, 0)
    look = math.sin(w)
    body["Neck"] = eul(2.5 * math.sin(w + 1.3) + 0.8 * br, 0, -5 * look)
    hw = Matrix.Rotation(math.radians(-9 * look), 3, 'Z') @ Matrix.Rotation(math.radians(-3 * math.sin(2 * w + 0.4)), 3, 'X')
    for i in range(4):
        body[f"Tail{i + 1}"] = eul(1.5 * math.sin(2 * w - 0.6 * i), 0, (5 + 3.5 * i) * math.sin(2 * w - 0.75 * (i + 1)))
    tl = ear_twitch(f, 34); tr = ear_twitch(f, 82) + 0.7 * ear_twitch(f, 96, 9)
    body["EarL"] = eul(-28 * tl + 1.5 * br, 0, -10 * tl)
    body["EarR"] = eul(-28 * tr + 1.5 * br, 0, 10 * tr)
    targets = [(lg['ball'], 0.0, 0.0) for lg in LEGS]
    # head orientation is set in world space (rest orientation turned by hw): steady, deliberate look
    return pose(body, targets, hw)

def bake(name, T, fn):
    arm.animation_data_create()
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    arm.animation_data.action = act
    prev = {}
    for f in range(T + 1):
        basis = fn(f % T)
        for n, B in basis.items():
            pb = arm.pose.bones[n]
            pb.rotation_mode = 'QUATERNION'
            loc, q, sc = B.decompose()
            if n in prev and q.dot(prev[n]) < 0: q.negate()
            prev[n] = q
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=f + 1, group=n)
            if n == "Hips":
                pb.location = loc
                pb.keyframe_insert("location", frame=f + 1, group=n)
    act.use_frame_range = True
    act.frame_start = 1; act.frame_end = T + 1
    act.use_cyclic = True
    for fc in action_fcurves(act):
        for kp in fc.keyframe_points: kp.interpolation = 'LINEAR'
        m = fc.modifiers.new('CYCLES')
    return act

def action_fcurves(act):
    out = []
    for layer in act.layers:
        for strip in layer.strips:
            for cb in strip.channelbags:
                out += list(cb.fcurves)
    return out

walk = bake("Walk", WALK_T, walk_frame)
idle = bake("Idle", IDLE_T, idle_frame)
arm.animation_data.action = idle

# reset pose channels outside of action evaluation
# ----------------------------------------------------------------------------------------------
# CHECKS: foot sliding in Walk (world = armature pos + body travel), ground contact, influences
scene = bpy.context.scene
scene.render.fps = 30
report = {}
arm.animation_data.action = walk
foot_bones = [lg['names'][3] for lg in LEGS]
slide = {}
minz = 9
for lg in LEGS:
    tb = lg['names'][3]
    p0 = PHASE[(lg['kind'], lg['side'])]
    ys = []
    started = False
    for f in range(2 * WALK_T):
        scene.frame_set((f % WALK_T) + 1)
        pb = arm.pose.bones[tb]
        hpos = pb.head
        minz = min(minz, pb.tail.z)
        p = (f / WALK_T + p0) % 1.0
        if p < DUTY * 0.8:
            started = True
            ys.append(hpos.y - WALK_V * f)   # world y when the rig travels -Y at WALK_V per frame
        elif started:
            break
    slide[tb] = max(ys) - min(ys)
report['walk_slide_m'] = slide
report['walk_min_toe_tail_z'] = minz
report['reach_clamp_m'] = reach_err[0]
arm.animation_data.action = idle
scene.frame_set(1)

tri = sum(len(p.vertices) - 2 for p in me.polygons)
report.update(dict(verts=len(me.vertices), faces=len(me.polygons), tris=tri, bones=len(arm.data.bones),
                   deform_bones=sum(1 for b in arm.data.bones if b.use_deform), max_influences=max_infl,
                   walk_frames=WALK_T, idle_frames=IDLE_T, walk_speed_mps=WALK_V * 30, walk_stride_m=WALK_D))
# dimensions
xs = [v.co.x for v in me.vertices]; ys = [v.co.y for v in me.vertices]; zs = [v.co.z for v in me.vertices]
report['bbox'] = [min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)]
print("REPORT", json.dumps(report))
with open(os.path.join(WORK, "build_report.json"), "w") as fh: json.dump(report, fh, indent=1)

scene.frame_start = 1; scene.frame_end = IDLE_T + 1
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "fox.blend"))
print("SAVED")
