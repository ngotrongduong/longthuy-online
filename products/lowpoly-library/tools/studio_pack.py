"""Writes the Studio code that turns an uploaded pack into the Model for sale (python -I studio_pack.py <pack id>
<uploaded asset id> "<Model name>"). Writes _ready/packs/<pack id>_studio.luau, to run in the test place (never the
Slime game): it loads the upload, takes each MeshPart out of its wrapper Model, anchors it, sets the pack on the
ground at the origin, adds a StringValue Credits (from <pack id>_credits.txt) and puts it in workspace.LPPacks.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACK, ASSET, NAME = sys.argv[1], int(sys.argv[2]), sys.argv[3]
credits = (ROOT / "_ready" / "packs" / f"{PACK}_credits.txt").read_text(encoding="utf-8").replace("\t", "  ")
credits = f"{NAME}: {len(credits.splitlines())} models, each CC0 (public domain) from the Meshy community.\n" \
          "Name, maker, source:\n" + credits
assert "]==]" not in credits
code = f"""local f = workspace:FindFirstChild("LPPacks") or Instance.new("Folder")
f.Name = "LPPacks"
f.Parent = workspace
local old = f:FindFirstChild({NAME!r})
if old then old:Destroy() end
local m = game:GetObjects("rbxassetid://{ASSET}")[1]
for _, node in m:GetChildren() do
  if node:IsA("Model") then
    local p = node:FindFirstChildWhichIsA("MeshPart")
    if p then
      p.Anchored = true
      p.Parent = m
    end
    node:Destroy()
  end
end
m.Name = {NAME!r}
local c = Instance.new("StringValue")
c.Name = "Credits"
c.Value = [==[{credits}]==]
c.Parent = m
m.Parent = f
local cf, size = m:GetBoundingBox()
m:PivotTo(m:GetPivot() + Vector3.new(-cf.Position.X, size.Y / 2 - cf.Position.Y, -cf.Position.Z))
local n = 0
for _, p in m:GetChildren() do if p:IsA("MeshPart") then n += 1 end end
return m.Name .. ": " .. n .. " parts, size " .. tostring(size)
"""
out = ROOT / "_ready" / "packs" / f"{PACK}_studio.luau"
out.write_text(code, encoding="utf-8")
print("STUDIO", out)
