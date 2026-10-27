# Build portfolio\rigged-fox-demo.mp4 from the rendered shot frames (xfade chain + drawtext overlays).
# Run with: blender --background --factory-startup --python assemble.py   (only uses the stdlib)
import os, json, shutil, subprocess

WORK = r"C:\Ai kiem tien\portfolio\rigged-fox\work"
OUTMP4 = r"C:\Ai kiem tien\portfolio\rigged-fox-demo.mp4"
FFMPEG = r"C:\Users\ngotr\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.2-full_build\bin\ffmpeg.exe"
FPS = 30

build = json.load(open(os.path.join(WORK, "build_report.json")))
before = json.load(open(os.path.join(WORK, "before_report.json")))
TRIS = build["tris"]; BONES = build["bones"]; BEFORE = before["before_tris"]

# shot: (folder, first file frame, count, transition into this shot, transition seconds)
SHOTS = [
    ("S1", 1, 96, None, 0.0),
    ("S2", 73, 144, "wipeleft", 0.8),
    ("S3", 208, 99, "fade", 0.3),
    ("S4", 297, 115, "fade", 0.333),
    ("S5", 1, 105, "fade", 0.4),
    ("S6", 1, 90, "fade", 0.4),
    ("S7", 21, 75, "fade", 0.4),
    ("S8", 101, 75, "fade", 0.5),
]
TEXT = {
    "S1": ("BEFORE", f"Raw high-poly model  ·  {BEFORE:,} tris  ·  no rig"),
    "S2": ("AFTER", f"Clean low poly  ·  {TRIS:,} tris  ·  Roblox MeshPart ready"),
    "S3": ("CLEAN TOPOLOGY", "Quad flow that bends well  ·  flat shaded  ·  one 256 px texture"),
    "S4": ("SKELETON + SKIN WEIGHTS", f"{BONES} bones  ·  max 4 influences per vertex  ·  tested bends"),
    "S5": ("WALK CYCLE", "Quadruped gait  ·  feet planted, no sliding  ·  seamless loop"),
    "S6": ("WALK CYCLE", "In-place loop for Roblox  ·  exported as FBX + GLB"),
    "S7": ("IDLE", "Breathing  ·  tail sway  ·  ear twitch  ·  seamless loop"),
}

os.makedirs(os.path.join(WORK, "txt"), exist_ok=True)
os.makedirs(os.path.join(WORK, "fonts"), exist_ok=True)
for f in ("segoeuib.ttf", "segoeui.ttf", "seguisb.ttf"):
    shutil.copy(os.path.join(r"C:\Windows\Fonts", f), os.path.join(WORK, "fonts", f))

def tfile(name, s):
    p = os.path.join(WORK, "txt", name + ".txt")
    with open(p, "w", encoding="utf-8") as fh: fh.write(s)
    return f"txt/{name}.txt"

# timeline
starts, L = [], 0.0
offsets = []
for i, (sid, f0, n, tr, d) in enumerate(SHOTS):
    dur = n / FPS
    if i == 0:
        starts.append(0.0); L = dur
    else:
        off = L - d
        offsets.append(off); starts.append(off); L = L + dur - d
TOTAL = L
ends = [starts[i + 1] + SHOTS[i + 1][4] if i + 1 < len(SHOTS) else TOTAL for i in range(len(SHOTS))]

inputs = []
for (sid, f0, n, tr, d) in SHOTS:
    inputs += ["-framerate", str(FPS), "-start_number", str(f0), "-i", f"frames/{sid}/f_%05d.png"]

fl = []
for i in range(len(SHOTS)):
    fl.append(f"[{i}:v]trim=end_frame={SHOTS[i][2]},setpts=PTS-STARTPTS,fps={FPS},format=yuv444p,setsar=1[v{i}]")
prev = "v0"
for i in range(1, len(SHOTS)):
    tr, d = SHOTS[i][3], SHOTS[i][4]
    out = f"x{i}"
    fl.append(f"[{prev}][v{i}]xfade=transition={tr}:duration={d:.3f}:offset={offsets[i - 1]:.3f}[{out}]")
    prev = out

def alpha(a, b, fade=0.3):
    return (f"'if(lt(t,{a:.3f}),0,if(lt(t,{a + fade:.3f}),(t-{a:.3f})/{fade},"
            f"if(lt(t,{b - fade:.3f}),1,if(lt(t,{b:.3f}),({b:.3f}-t)/{fade},0))))'")

BOLD = "fonts/segoeuib.ttf"; REG = "fonts/segoeui.ttf"; SEMI = "fonts/seguisb.ttf"
SH = "shadowcolor=black@0.55:shadowx=2:shadowy=2"
draws = []
for i, (sid, *_r) in enumerate(SHOTS):
    if sid not in TEXT: continue
    a = starts[i] + (0.35 if i == 0 else SHOTS[i][4] + 0.1)
    b = (starts[i + 1] + 0.05) if i + 1 < len(SHOTS) else TOTAL
    title, sub = TEXT[sid]
    al = alpha(a, b)
    draws.append(f"drawbox=x=60:y=h-166:w=58:h=6:color=0xff7a1a@1:t=fill:enable='between(t,{a:.3f},{b - 0.15:.3f})'")
    draws.append(f"drawtext=fontfile={BOLD}:textfile={tfile(sid + 'a', title)}:fontsize=46:fontcolor=white:x=58:y=h-152:alpha={al}:{SH}")
    draws.append(f"drawtext=fontfile={REG}:textfile={tfile(sid + 'b', sub)}:fontsize=25:fontcolor=0xe4ebf2:x=60:y=h-92:alpha={al}:{SH}")
# watermark (all but end card)
wm_end = starts[-1] + 0.2
draws.append(f"drawtext=fontfile={SEMI}:textfile={tfile('wm', 'LONG THUY   |   3D model  →  Roblox ready')}:fontsize=20:"
             f"fontcolor=white@0.85:x=40:y=34:alpha={alpha(0.2, wm_end, 0.4)}:{SH}")
# end card
a = starts[-1] + SHOTS[-1][4]; b = TOTAL + 1.0
ec = alpha(a, b, 0.4)
draws.append(f"drawtext=fontfile={BOLD}:textfile={tfile('e1', 'LONG THUY')}:fontsize=72:fontcolor=white:x=80:y=214:alpha={ec}:{SH}")
draws.append(f"drawbox=x=84:y=304:w=72:h=6:color=0xff7a1a@1:t=fill:enable='gte(t,{a + 0.2:.3f})'")
draws.append(f"drawtext=fontfile={SEMI}:textfile={tfile('e2', 'Your 3D model, Roblox ready')}:fontsize=36:fontcolor=white:x=82:y=326:alpha={ec}:{SH}")
draws.append(f"drawtext=fontfile={SEMI}:textfile={tfile('e3', 'Low poly  ·  Rigged  ·  Animated')}:fontsize=28:fontcolor=0xffa14a:x=82:y=382:alpha={ec}:{SH}")
draws.append(f"drawtext=fontfile={REG}:textfile={tfile('e4', 'FBX + GLB + .blend   ·   under 10k tris   ·   4 bone influences')}:fontsize=21:fontcolor=0xdde5ee:x=82:y=432:alpha={ec}:{SH}")
# global fade in/out
draws.append(f"fade=t=in:st=0:d=0.4,fade=t=out:st={TOTAL - 0.5:.3f}:d=0.5")
fl.append(f"[{prev}]" + ",".join(draws) + ",format=yuv420p[out]")

script = ";\n".join(fl)
with open(os.path.join(WORK, "filter.txt"), "w", encoding="utf-8") as fh: fh.write(script)
cmd = [FFMPEG, "-y", "-hide_banner", "-loglevel", "warning"] + inputs + [
    "-/filter_complex", "filter.txt", "-map", "[out]", "-c:v", "libx264", "-preset", "slow", "-crf", "20",
    "-profile:v", "high", "-pix_fmt", "yuv420p", "-r", str(FPS), "-movflags", "+faststart", OUTMP4]
print("TOTAL_SECONDS", round(TOTAL, 2), "STARTS", [round(s, 2) for s in starts])
p = subprocess.run(cmd, cwd=WORK, capture_output=True, text=True)
print("FFMPEG_RC", p.returncode)
print(p.stderr[-3000:])
if os.path.exists(OUTMP4): print("MP4_BYTES", os.path.getsize(OUTMP4))
