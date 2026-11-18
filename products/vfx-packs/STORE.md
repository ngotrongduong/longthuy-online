# VFX packs 2 to 6: store pages

Five packs built from the owner's effects library on 2026-11-15, after 44 other creators' pictures were redrawn
in code (`work/redraw/`) so every picture they wear is ours. The pack files (`work/dist/*.rbxm`) and the build
scripts (`work/`) are git-ignored: this public repo holds only the listing text and the thumbnails (`media/`).

| pack | file | effects | price (USD) | Creator Store |
|---|---|---|---|---|
| Fantasy Wings FX Pack | `FantasyWingsFX.rbxm` | 32 wings (12 for players, 20 for pets) | 9.99 | Model 73482384781132 |
| Magic Auras & Shields FX | `MagicAurasFX.rbxm` | 25 auras, domes and shields | 9.99 | Model 117643355725830 |
| Combat Skills FX Pack | `CombatSkillsFX.rbxm` | 26 skills (charge, release, projectile, impact) | 12.99 | Model 128561266438892 |
| Explosions & Status FX Pack | `ExplosionsStatusFX.rbxm` | 11 bursts, 3 status effects | 6.99 | Model 113896470246117 |
| Weapon Auras & Trails FX | `WeaponAurasFX.rbxm` | 5 weapon auras, 2 trails | 4.99 | Model 106848503060543 |

Saved to Roblox and configured on 2026-11-15: Distribute on Creator Store on, the price above, 3 thumbnails each,
Roblox AI training off, the description below. Toolbox API right after: published, price right, 3 preview images,
`purchasable: false` and `visibilityStatus: 3` (Roblox still reviewing them; pack 1 showed the same at first and
became purchasable later). Store page: `create.roblox.com/store/asset/<id>`. If one is still not purchasable after
a day, open its Configure page and look for a message.

Checked 2026-11-19: all 5 are still `purchasable: false`. Each Configure page says "Not distributed on Creator
Store. This asset may be in violation of Roblox Community Standards" with an Appeal button, and Pricing Disabled;
Save stays off, so the descriptions on Roblox still carry the old AI lines (the text below is the new one, without
them). Ways on: appeal each one, or find what Roblox flags (a picture, a script), fix it and save a new Model.

Why these prices: pack 1 (10 effects) sells at 6.99 and the creature pack at 14.99; most paid VFX packs on the
Creator Store sit between 5 and 15 USD. The combat pack has the most work in it (each skill is a full sequence), the
weapons pack is the smallest. Revisit after 4 weeks (one change a week, `PLAN.md`).

## Tested (2026-11-15, Studio, `work/dist/PackTest.rbxl`)

All 5 packs side by side on a baseplate, Play: 104 stands, every effect registered, every stand shows its effect,
0 warnings and 0 errors in the client and server logs. The first run found 4 effects refused (a see-through shell's
picture was missing from the pack) and the install scripts switched on; both fixed in the build and tested again.
Effects far from the player or behind the camera switch off on purpose (the library's phone budget).

## How to publish (Studio, then the Configure page)

1. Open `work/dist/PackTest.rbxl` (or run `work/reload_all.ps1 -StudioId <id>` in any open place).
2. Right-click the pack's model > Save to Roblox (a plain Model, never an Assets API upload: that makes a Package).
   Studio's `AssetService:CreateAssetAsync` still answers "not available yet" (checked 2026-11-15).
3. Configure page: Distribute on Creator Store on, the price above, the 3 thumbnails `media/<pack>_1..3.jpg`,
   Roblox AI training off, the description below.
4. Check `toolbox-service/v1/items/details?assetIds=<id>` says purchasable, log the id here and in `NEXT_STEPS.md`.

## Listings (descriptions under 1000 characters)

### Fantasy Wings FX Pack (32 Wings, Players and Pets)

32 wings that move: they flap and catch the light, with feathers, sparks or flames. 12 sized for players (seraph,
rune, frost crystal, hologram, jet thruster, clockwork, leaf, angel, bat, blade fan, sword, ribbon tentacles) and
20 for pets (sun phoenix, storm dragon, royal griffin, thunderbird, rose fairy, honeybee, imp and more).

Drop the model in, press Play and the demo shows every wing on a stand. To give wings to a player or a pet, set one
attribute (`VfxWings = "wings.seraph"`) and the included runtime does the rest: lower detail far away and on cheap
phones, clean removal.

Inside: the wings, the VfxLib runtime, an install folder (two scripts you move and switch on), a demo and a README.
Not included: sounds, flight gameplay. Use in your own experiences; no resale.

### Magic Auras & Shields FX (25 Auras)

25 auras for characters: magic circles, fire and dark tornadoes, a portal ring, a sci-fi dome, an aurora shield, ice
body, petal storm, skull aura, wind swirl, glitch, a campfire, golden and hologram dragons and more.

Press Play and the demo shows them all. To put one on a player, set the attribute `VfxAura = "aura.portal_ring"`;
remove it and the aura fades out. The runtime lowers detail far away and on cheap phones.

Inside: the auras, the VfxLib runtime, an install folder, a demo and a README.
Not included: sounds, gameplay (buffs, damage). Use in your own experiences; no resale.

### Combat Skills FX Pack (26 Skills)

26 skill effects with the whole moment in them: a charge, the release, a projectile or a strike, the impact.
Lightning strikes, icicle slash, lava rocks, ground slash, energy ball, magic and piercing arrows, arrow volley and
ring, fan shot, explosive bolt, acid rain, spirit wolf, wind blade, spear flurry, flash step, teleport, a healer's
ward and a frost burst.

Press Play: the demo casts every skill from one dummy at another. In your game, one call plays a skill from the
caster at the target (self, melee or projectile, set per skill). The runtime keeps it light on phones.

Inside: the skills, the VfxLib runtime, an install folder, a demo and a README. Not included: damage,
cooldowns, animations, sounds. Use in your own experiences; no resale.

### Explosions & Status FX Pack (14 Effects)

11 one-shot bursts and 3 status effects: anime and toon explosions, a classic explosion, ground break, crack rays,
bubbles, disintegrate, muzzle flash, a spawn wall, an ether burst, a momentum ring; acid melt, slowed and warded for
characters.

Press Play to see them all. One call plays a burst where you want it; a status effect follows a character while an
attribute is set. Light on phones.

Inside: the effects, the VfxLib runtime, an install folder, a demo and a README. Not included: damage, sounds.
Use in your own experiences; no resale.

### Weapon Auras & Trails FX (7 Effects)

5 auras for held weapons (staff, sword kit, shield, focus orb, bow) and 2 trails (a sword trail and ghost trails for
running characters).

Press Play to see them on demo weapons. Put an aura on any tool's handle with one attribute; the trails follow what
they are attached to. Light on phones.

Inside: the effects, the VfxLib runtime, an install folder, a demo and a README. Not included: the weapon
models, sounds. Use in your own experiences; no resale.

## Other stores (after the Creator Store pages are live)

BuiltByBit (Roblox assets section) and itch.io take the same `.rbxm` files and the same text. The owner signs up
once on each (account, payout, tax form); Claude makes the pages and uploads. See `NEXT_STEPS.md`.

## Wave 2

80 more effects need only 1 to 2 more pictures each (about 40 pictures in all, `work/redraw/coverage.txt`): 23
auras, 39 skills (guardian, holy sword, mage), 6 wings, 5 bursts, 3 hits, 3 trails. Redraw them after the first 5
packs show whether VFX sells.
