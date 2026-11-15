# Agent skills: store plan

Small digital products: Claude Code skills (SKILL.md folders) for Roblox developers. The paid files are built in
`products/agent-skills/dist/` (ignored by git, never in this public repo); this page holds only what is public anyway:
product names, contents, prices and listing text.

## Products and prices (USD, the same on every platform)

| product | zip | skills inside | price |
|---|---|---|---|
| Roblox VFX Craft | `roblox-vfx-craft.zip` | `roblox-vfx-craft` (SKILL.md + 15 references + 3 workflows) | 14 |
| Roblox Creature Rigging + Animation | `roblox-creature-skills.zip` | `roblox-creature-rigging`, `roblox-creature-animation` | 6 |
| Game Art Cutout | `game-art-cutout.zip` | `game-art-cutout` (SKILL.md + `cutout.py`) | 7 |
| Roblox Game-Dev Skills Bundle | `roblox-gamedev-skills-bundle.zip` | all four skills above | 22 (saves 5) |

Why these prices: most paid SKILL.md skills on Agensi sit between 5 and 15 USD one-time; the VFX skill is large
(about 270 KB of tested reference) so it sits at the top of that band; the two small ones sit at the bottom; the
bundle gives a clear reason to buy all. Revisit after the first 4 weeks of views and sales (one change a week, as in
`PLAN.md`).

Not sold, on purpose: the private effect-library skills (they only work with a private library), a third-party
MIT-licensed Blender skill (not our work), and a ChatGPT browser-automation flow (replaced in Game Art Cutout by
prompts plus a cutter, so buyers stay within their image generator's terms).

## Platforms, in order

| platform | why | creator share | payout |
|---|---|---|---|
| Agensi (agensi.io) | curated marketplace for SKILL.md skills, buyers already looking for skills, security scan builds trust | 70 % (official page, 2026) | Stripe Connect |
| SkillHQ (skillhq.dev) | marketplace for Claude Code skills with a CLI installer; quick seller onboarding | reported 85 % (check on sign-up) | PayPal |
| itch.io | where game developers already shop for tools and assets; the Roblox audience is there, not on skill sites | seller sets the share (default 10 % to itch) | PayPal or Stripe |

Later, only if the three above sell: Payhip (5 % fee on the free plan) or Gumroad (10 % + fees, but some discovery).

## Listings

### 1. Roblox VFX Craft (skill for Claude Code)

**Title:** Roblox VFX Craft - Claude Code skill for auras, slashes, skills and impacts that run on phones

**Short:** Teach your AI agent to design and build Roblox effects that make players stop and look, and stay smooth
on cheap phones.

**Description:**
Roblox VFX Craft is an agent skill (a SKILL.md folder) for Claude Code and other agents that read skills. Ask your
agent for "a fire aura", "a lightning sword combo" or "a boss ultimate", and the skill makes it work like an effects
artist: name the moment, plan the phases (anticipation, contact, main shape, secondary, decay), pick the layers and
textures, set a phone budget, build it with ParticleEmitter, Beam, Trail, Attachment and flipbooks, then score it.

Inside:
- A router that loads only what the task needs, so it stays light on context.
- 15 reference pages: visual principles, aura techniques (idle, charging, transformation, floor auras, wings), weapon
  slashes and combos, charge / projectile / beam / lightning / boss telegraphs, impacts, explosions, hit-stop and
  camera shake, textures and flipbooks, clear 3D shells, pixel-art effects, Unreal/Niagara-to-Roblox recipes, exact
  engine properties, animation-marker sync, server-decides / client-draws architecture, cost budgets, blending.
- 3 workflows: request to finished effect (10 steps), combat sequences with cancels, learning a look from a reference.
- A 100-point quality rubric with gates (clean cancel, overlap, low quality, cleanup).
- Every claim tagged verified in Studio, doc-verified, or unverified.

Not included: effect files, textures or Roblox assets. It does not run Studio for you. Made with AI help, checked by
hand. Single-user licence.

**Tags:** roblox, vfx, visual effects, particles, game development, luau, claude code, agent skill, combat, mobile
performance

### 2. Roblox Creature Rigging + Animation (two skills)

**Title:** Roblox Creature Rigging + Animation - two Claude Code skills for pets, animals and bosses

**Short:** Your agent rigs and animates creatures the right way: measured joints, clean weights, species-true motion.

**Description:**
Two compact agent skills for Claude Code. **Rigging** makes your agent audit, build and mend skeletons and skin
weights for any creature (quadrupeds, birds, fish, snakes, insects, golems, dragons) and follow Roblox's rules for
skinned meshes: root at the origin, at most 4 influences, unique bone names, rest pose rebuilt from bind matrices,
bend sweeps and a quality gate. **Animation** makes motion read per species: correct gait order and planted feet,
Froude scaling of stride, wingbeats that lift, waves that travel head to tail, springs and inertialisation instead of
pops, `Bone.Transform` vs `Animator`, `IKControl`, and how to run many creatures cheaply.

Works best with a Blender or Roblox Studio MCP connection. No models or animations included. Made with AI help,
checked by hand. Single-user licence.

**Tags:** roblox, rigging, animation, pets, creatures, blender, skinned mesh, procedural animation, claude code, agent
skill

### 3. Game Art Cutout (skill + Python cutter)

**Title:** Game Art Cutout - Claude Code skill to turn AI image sheets into game-ready icons, textures and flipbooks

**Short:** Prompts that come back easy to cut, and a cutter that keys, slices and packs them for Roblox.

**Description:**
An agent skill plus a small Python tool. The skill writes image prompts that come back easy to process (flat magenta
for solid art, white on black for glow, exact grids, 16-frame flipbook clips) for any image generator you use. Save
the images to your project; your agent then runs `cutout.py`:
- `key`: removes a magenta background by unmixing it, so soft edges and see-through parts keep their real colour;
- `grid`: cuts an icon sheet into named PNGs;
- `glow`: turns light on black into alpha;
- `atlas`: packs a flipbook sheet into a 1024 atlas with one scale for every frame, plus a strip to check motion.
Also covers sizes for phones, wearing flipbooks on Roblox emitters, trail strips, uploading and preloading.

Needs Python 3.9+ and Pillow, and your own access to an image generator. No art included; no website automation.
Made with AI help, tested on sample sheets. Single-user licence.

**Tags:** game art, icons, sprite sheet, flipbook, texture, image generation, python, roblox, claude code, agent
skill

### 4. Roblox Game-Dev Skills Bundle

**Title:** Roblox Game-Dev Skills Bundle - 4 Claude Code skills: VFX, creature rigging, animation, game art

**Short:** All four skills in one download for 22 USD instead of 27.

**Description:**
Roblox VFX Craft, Roblox Creature Rigging, Roblox Creature Animation and Game Art Cutout in one zip. See each
product for details. Copy the four folders into `~/.claude/skills/` and your agent picks the right one by itself.
Made with AI help, checked by hand. Single-user licence.

**Tags:** roblox, game development, vfx, animation, rigging, game art, claude code, agent skills, bundle

## What the owner does once (account and payout only)

1. **Agensi:** create a creator account, connect payouts (Stripe Connect).
2. **SkillHQ:** create a seller account, connect PayPal for payouts.
3. **itch.io:** create an account, set up payouts (PayPal or Stripe) and fill in its tax form.

After that Claude creates the listings, uploads the zips, writes the text above and handles updates and buyer
questions.
