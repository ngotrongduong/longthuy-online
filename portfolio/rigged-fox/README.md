# Low-poly rigged fox (Roblox ready)

A stylized low-poly fox, modelled, rigged, skinned and animated procedurally in Blender 5.2 by Long Thuy.
Portfolio piece for the service "make your 3D model Roblox ready: low poly, rigged, animated".

## What is in the folder

| File | What it is |
|---|---|
| `fox.blend` | Source scene: mesh `Fox`, armature `FoxRig`, actions `Idle` and `Walk` (texture packed in) |
| `fox.fbx` | Mesh + armature + both animations as two takes (`Idle`, `Walk`), texture embedded |
| `fox_idle.fbx`, `fox_walk.fbx` | The same rig with one animation each, for Roblox's Animation Editor import |
| `fox.glb` | glTF binary: mesh, skin, texture and both animations |
| `fox_palette.png` | The 256 x 256 colour palette texture (also embedded in the FBX/GLB) |
| `work/` | The bpy scripts that build, check, render and export everything (rebuild: `blender -b --factory-startup --python work/build_fox.py`) |

## Model

- **3,808 triangles**, 1,928 vertices, one mesh, one material, one 256 px palette texture (flat colours by UV, so it works
  with Roblox's MeshPart / SurfaceAppearance; no vertex colours needed). Well under Roblox's 10,000-triangle MeshPart limit.
- Flat shaded (hard edges on every face), low-poly style. Body, legs, tail and ears are separate closed shells that overlap
  at the joints, the usual low-poly build; no seams open at any tested pose.
- Size: 1.31 m nose to tail tip, 0.75 m to the ear tips, 0.28 m wide. Feet stand on the ground plane, pivot at the origin
  between the feet. Faces **-Y** in Blender (Blender's Front view).

## Rig

- **28 bones**: `Root` (at the origin, no skin), `Hips`, `Spine1`, `Spine2`, `Neck`, `Head`, `EarL/R`, `Tail1-4`, and per leg
  4 bones: hind `BackThigh`, `BackShin`, `BackFoot`, `BackToe` (L/R), front `FrontUpper`, `FrontLower`, `FrontFoot`, `FrontToe` (L/R).
- Skin weights: at most **4 influences per vertex**, normalised; rule-based (each body part only weighted to its own bones),
  checked by posing every joint group to strong angles and rendering it (no tearing, no part dragging a neighbour).
- No leaf/end bones in the export, unique names, transforms applied (scale 1, no rotation on the objects).

## Animations (30 fps, both loop seamlessly)

| Name | Length | What it does |
|---|---|---|
| `Idle` | 120 frames (4.0 s) | two breaths, slow head look, tail sway with a travelling wave, left ear twitch, right ear double twitch; feet stay planted |
| `Walk` | 24 frames (0.8 s) | quadruped lateral-sequence walk (LH, LF, RH, RF), 62% stance, paws planted while the body passes over, hips bob twice a stride, steady head, tail follow-through. **In place**: move the model at **0.34 m/s** (0.27 m per cycle) for zero foot sliding |

## Import into Roblox Studio

1. **Model:** Avatar tab (or Home) > **Import 3D** > choose `fox.fbx`.
   - Rig General > Rig Type: **Custom** (not R15). The importer keeps the bones and skinning.
   - File General > Scale Unit: **Meter** gives a fox about 2.7 studs tall (1 stud = 0.28 m). Choose another unit or scale
     if you want a bigger pet.
   - If the fox faces backwards in your setup, set the import rotation to 180 degrees around Y.
2. **Animations:** select the imported model, open the **Animation Editor** > ... > **Import > From FBX Animation**, pick
   `fox_walk.fbx` (then `fox_idle.fbx`), set Looping on, and Publish to Roblox to get the Animation IDs.
3. Play them with an `AnimationController` + `Animator` (`Animator:LoadAnimation`), `Idle` at a low priority and `Walk`
   at Movement priority. Adjust the walk track speed if your pet moves faster than 0.34 m/s per model scale.

## Known limits

- The walk is in place (Roblox moves the model); there is no run, turn or jump clip in this sample.
- No jaw or eyelid bones (the stylized face does not need them).
- Built and checked in Blender (export re-imported and checked: 3,808 tris, 28 bones, 4 influences max, both clips present).
  Not yet opened in Roblox Studio itself.
