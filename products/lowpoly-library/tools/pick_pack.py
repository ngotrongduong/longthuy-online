"""Writes a pack list from the cells picked on a contact sheet (python -I pick_pack.py <sheet txt> <pack id> <cells>).
<cells> is a comma list of cell numbers, ranges allowed (0-3,6,9). Appends to packs/<pack id>.txt if it exists."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sheet, pack, cells = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
files = dict(l.split("\t")[:2] for l in sheet.read_text(encoding="utf-8").splitlines() if l)
picked = []
for part in cells.split(","):
    a, _, b = part.partition("-")
    picked += [files[str(i)] for i in range(int(a), int(b or a) + 1)]
out = ROOT / "packs" / f"{pack}.txt"
out.parent.mkdir(exist_ok=True)
old = out.read_text(encoding="utf-8").splitlines() if out.exists() else []
new = old + [f for f in picked if f not in {o.split("\t")[0] for o in old}]
out.write_text("\n".join(new) + "\n", encoding="utf-8")
print(pack, len(new), "models")
