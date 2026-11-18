"""Re-sorts the whole low-poly library (run with: python -I resort.py [--apply]).

Every model in models/ and _unsorted/ is classified again from its name with the RULES of harvest.js:
the strongest, last-placed word wins ("Skeleton_Warrior" is Undead, "Treasure_Chest" a container,
"Knight_Helmet" armour); words after "holding", "riding", "made"... are ignored. A name no rule knows keeps its
folder (it came from Meshy's category). Then:
- names of other people's characters or brands -> models/_Review/IP_Risk/ (never sold as they are);
- over 20,000 triangles (Roblox's limit for one mesh) and not a set -> models/_Review/Over_20k/;
- models of _unsorted/ no rule knows -> models/_Review/Unclassified/;
- reposts (same name and same triangle count, other bytes): the most liked stays, the others -> _dupes/near/.
catalog.csv gets one row per model and placed.json points at the new paths; the moves are listed in
_state/resort_moves.csv. Without --apply it only counts. Stop the sorter while applying.
"""
import csv
import json
import random
import re
import sys
import time
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))   # -I leaves the script's folder out
from sorter import CATALOG, FIELDS, MODELS, ROOT, STATE, save_json, unique_path

APPLY = "--apply" in sys.argv
sys.stdout.reconfigure(encoding="utf-8")

JS = (Path(__file__).resolve().parent / "harvest.js").read_text(encoding="utf-8")
RULES = [(th, sb, re.compile(rx)) for th, sb, rx in re.findall(r"\['(\w+)', '(\w+)', /(.+)/\],", JS)]
STOP = set(re.findall(r"'([^']*)'", re.search(r"const STOP = new Set\(\[(.*?)\]\)", JS, re.S).group(1)))
SETRE = re.compile(re.search(r"const SETRE = /(.+)/;", JS).group(1))
WEAK = {("Characters", "Characters"), ("Monsters", "Other_Monsters")}
LIVING = {"Monsters", "Animals", "Characters"}
DESCRIBING = {"stone", "stones", "rock", "rocks", "gold", "crystal", "crystals", "log", "vine", "pot", "giant", "boss",
              "pet", "toy", "toys", "king", "queen"}
CUT = re.compile(r"\b(holding|wielding|carrying|wearing|riding|made|using|inside|under|near|sitting|standing|on|in|with)\b.*")
IP = re.compile(r"\b(pokemon|pok[eé]mon|pikachu|charizard|eevee|vulpix|bulbasaur|squirtle|jigglypuff|minecraft|creeper|"
                r"pepe|mario|luigi|bowser|yoshi|sonic the|sonic hedgehog|zelda|triforce|hylian|kirby|pacman|pac man|disney|mickey|minnie|"
                r"marvel|spiderman|spider man|batman|superman|iron man|ironman|hulk|thor|stormbreaker|mjolnir|"
                r"captain america|deadpool|groot|doom guy|doomguy|skeletor|starcraft|roggenrola|naruto|goku|vegeta|dragon ball|luffy|harry potter|hogwarts|"
                r"filch|dumbledore|star wars|darth|vader|yoda|mandalorian|lightsaber|stormtrooper|jedi|master chief|"
                r"fortnite|among us|amogus|shrek|spongebob|hello kitty|sanrio|totoro|ghibli|genshin|"
                r"keyblade|final fantasy|sephiroth|gundam|transformers|optimus|godzilla|toothless|elsa|olaf|"
                r"buzz lightyear|lego|barbie|poppy playtime|huggy|fnaf|freddy|fazbear|springtrap|bendy|cuphead|"
                r"undertale|hollow knight|terraria|witcher|skyrim|elden ring|megaman|mega man|street fighter|"
                r"mortal kombat|overwatch|valorant|ghostface|pennywise|chucky|xenomorph|terminator|robocop|"
                r"ghostbusters|scooby|garfield|snoopy|smurf|peppa|bluey|paw patrol|labubu|skibidi|toji|gojo|"
                r"jujutsu|tanjiro|nezuko|demon slayer|sydney opera|animal crossing|lilo)\b")
LIMIT = 20000


def make_name(raw, fallback):
    s = re.split(r"[,.;:\n(]", raw or "")[0]
    s = re.sub(r"[_\-]+", " ", s)
    s = re.sub(r"[^\w ]+", " ", s)
    words = [w for w in s.split() if re.fullmatch(r"[A-Za-z0-9]+", w) and w.lower() not in STOP][:5]
    n = "_".join(w[0].upper() + w[1:].lower() for w in words)
    return n if len(n) >= 3 else fallback


def classify(name):
    """((theme, sub, sure), places the name allows) from the last word a rule knows, or (None, set()).
    Describing words (stone, gold, giant...) lose to any other word; generic words (creature, warrior...) lose to
    a named creature, and when one ends the name the objects before it are only its parts."""
    text = CUT.sub("", name.replace("_", " ").lower()).strip()
    ms = [(m.end(), -i, th, sb, m.group(0)) for i, (th, sb, rx) in enumerate(RULES) for m in rx.finditer(text)]
    if any(m[4] not in DESCRIBING for m in ms):
        ms = [m for m in ms if m[4] not in DESCRIBING]
    if any(m[2] in LIVING and (m[2], m[3]) not in WEAK for m in ms):
        ms = [m for m in ms if (m[2], m[3]) not in WEAK]
    if ms and (max(ms)[2], max(ms)[3]) in WEAK:
        ms = [m for m in ms if m[2] in LIVING]
    if not ms:
        return None, set()
    _, _, th, sb, _ = max(ms)
    return (th, sb, (th, sb) not in WEAK), {(m[2], m[3]) for m in ms}


entries = json.loads((STATE / "entries.json").read_text(encoding="utf-8"))
placed = json.loads((STATE / "placed.json").read_text(encoding="utf-8"))
task_of = {rel: r for r, rel in placed.items()}
with open(CATALOG, encoding="utf-8", newline="") as f:
    row_of = {r["file"]: r for r in csv.DictReader(f)}
TRIS = re.compile(r"_(\d+)t(?:_\d+)?$")

models = []   # [path, row, source]
for p in MODELS.rglob("*.glb"):
    rel = str(p.relative_to(MODELS))
    row = row_of.get(rel)
    if row is None:
        e = entries.get(task_of.get(rel, ""), {})
        m = TRIS.search(p.stem)
        row = {"file": rel, "theme": p.parent.parent.name, "folder": p.parent.name,
               "name": e.get("n") or TRIS.sub("", p.stem), "triangles": m.group(1) if m else "",
               "license": e.get("lic", "cc0"), "author": e.get("a", ""), "likes": e.get("l", 0),
               "downloads": e.get("d", 0), "meshy_post": "https://www.meshy.ai/posts/" + e["p"] if e else "",
               "task_id": e.get("r", ""), "downloaded_at": time.strftime("%Y-%m-%d %H:%M", time.localtime(p.stat().st_mtime))}
    models.append([p, row, "models"])
for p in (ROOT / "_unsorted").glob("*.glb"):
    m = re.match(r"Meshy_AI_(.*?)_(\d{10})_", p.stem)
    tm = TRIS.search(p.stem)
    name = make_name(m.group(1) if m else "", "Model_" + (m.group(2) if m else p.stem[-10:]))
    row = {"file": "", "theme": "", "folder": "", "name": name, "triangles": tm.group(1) if tm else "",
           "license": "cc0", "author": "", "likes": 0, "downloads": 0, "meshy_post": "", "task_id": "",
           "downloaded_at": time.strftime("%Y-%m-%d %H:%M", time.localtime(p.stat().st_mtime))}
    models.append([p, row, "unsorted"])

# decide each model's place
plan = []   # (path, row, theme, sub, reason)
for p, row, src in models:
    name, tris = row["name"], int(row["triangles"] or 0)
    low = name.replace("_", " ").lower()
    cl, allowed = classify(name)
    th, sb = (row["theme"], row["folder"]) if src == "models" else (None, None)
    if ("Weapons", "Other_Weapons") in allowed:   # a "...blade" may be a sword or a knife
        allowed |= {("Weapons", "Swords"), ("Weapons", "Daggers_Knives")}
    if (th, sb) in allowed:   # the folder (chosen from Meshy's whole title) still fits the name
        cl = (th, sb, True)
    if IP.search(low):
        th, sb, why = "_Review", "IP_Risk", "ip"
    elif th == "Sets" or (tris > LIMIT and SETRE.search(low)):
        th, sb, why = "Sets", (cl[0] if cl and (cl[2] or th != "Sets") else (sb if th == "Sets" else "Props")), "set"
    elif tris > LIMIT:
        th, sb, why = "_Review", "Over_20k", "over"
    elif cl:
        th, sb, why = cl[0], cl[1], "rule"
    elif th and not (th == "_Review" and sb == "Unclassified"):
        why = "kept"
    else:
        th, sb, why = "_Review", "Unclassified", "unknown"
    plan.append((p, row, th, sb, why))

# reposts: same name and triangle count; the most liked and downloaded stays
groups = {}
for item in plan:
    groups.setdefault((item[1]["name"].lower(), item[1]["triangles"]), []).append(item)
near = {}   # path of a repost -> path of the copy that stays
for items in groups.values():
    if len(items) > 1:   # a repost also has (nearly) the same file size; 10000 triangles is a common target
        items.sort(key=lambda it: (not it[0].is_relative_to(MODELS), -(int(it[1]["likes"] or 0) + int(it[1]["downloads"] or 0)), it[0].stat().st_mtime))
        kept = []
        for it in items:
            size = it[0].stat().st_size
            same = next((k for k in kept if abs(k[1] - size) <= 0.005 * k[1]), None)
            if same:
                near[it[0]] = same[0]
            else:
                kept.append((it[0], size))

moves, count, matrix = [], Counter(), Counter()
for p, row, th, sb, why in plan:
    if p in near:
        count["repost"] += 1
        moves.append((p, None, "repost"))
        continue
    count[why] += 1
    if p.parent != MODELS / th / sb:
        moves.append((p, (th, sb), why))
        matrix[(f'{row["theme"] or "_unsorted"}/{row["folder"]}', f"{th}/{sb}")] += 1

print("models", len(plan), dict(count), "moves", len(moves))
for (a, b), n in matrix.most_common(40):
    print(f"  {n:4d}  {a} -> {b}")
if "--ip" in sys.argv:
    print("IP:", sorted(p.stem for p, d, w in moves if w == "ip"))
random.seed(2)
for p, dest, why in random.sample(moves, min(40, len(moves))):
    print("  ", why, p.parent.name, "/", p.stem, "->", "/".join(dest) if dest else "_dupes/near")

if APPLY:
    rows = {p: row for p, row, *_ in plan}
    new_rel, log = {}, []   # old models-relative path -> new one (None for a repost)
    for p, dest, why in moves:
        png = p.with_suffix(".png")
        if dest is None:
            out = ROOT / "_dupes" / "near"
            out.mkdir(parents=True, exist_ok=True)
            q = unique_path(out, p.stem)
        else:
            folder = MODELS / dest[0] / dest[1]
            folder.mkdir(parents=True, exist_ok=True)
            stem = f'{rows[p]["name"]}_{rows[p]["triangles"]}t' if p.parent.name == "_unsorted" else p.stem
            q = unique_path(folder, stem)
        p.replace(q)
        if png.exists():
            png.replace(q.with_suffix(".png"))
        log.append((str(p), str(q), why))
        if p.is_relative_to(MODELS):
            new_rel[str(p.relative_to(MODELS))] = str(q.relative_to(MODELS)) if dest else None
        rows[p] = None if dest is None else dict(rows[p], file=str(q.relative_to(MODELS)), theme=dest[0], folder=dest[1])
    for r, rel in list(placed.items()):
        if rel not in new_rel:
            continue
        if new_rel[rel] is not None:
            placed[r] = new_rel[rel]
            continue
        k = near[MODELS / rel]   # a repost: point at the copy that stays
        k_rel = str(k.relative_to(MODELS)) if k.is_relative_to(MODELS) else None
        if k_rel:
            placed[r] = new_rel.get(k_rel) or k_rel
    save_json(STATE / "placed.json", placed)
    out_rows = sorted((r for r in rows.values() if r), key=lambda r: (r["theme"], r["folder"], r["file"]))
    with open(CATALOG, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, FIELDS)
        w.writeheader()
        w.writerows(out_rows)
    new_log = not (STATE / "resort_moves.csv").exists()
    with open(STATE / "resort_moves.csv", "a", encoding="utf-8", newline="") as f:   # every run adds its moves
        csv.writer(f).writerows([("old", "new", "reason")] * new_log + log)
    print("moved", len(log), "catalog rows", len(out_rows))
