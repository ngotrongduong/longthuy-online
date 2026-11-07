# VFX packs for the Creator Store: what can be sold, and how

Source: the owner's effects library `C:\roblox-vfx-library` (private; 88 effects on 2026-11-07, `CATALOG.md`).
Decided 2026-11-07 by Claude.

## The licence check (done 2026-11-07)

Every picture an effect wears was traced (`src/VfxLib/Textures.luau`, `textures/README.md`, a scan of each effect):

- **Ours:** the Goo Lineage battle art and icons, the 24 `floor_*` circles (ChatGPT, drawn for the owner),
  the snowflake sheet, and Roblox's own engine textures.
- **Not ours:** every `pk*` key, the streaks, flipbooks, rings, sparks and glows baked from **free Creator Store
  packs by other creators** (`packs/*.rbxm`, their original asset ids). We may use those in our own games. We may
  **not** sell them: a paid asset must hold only art we own.

Result:

| | effects | sellable now |
|---|---|---|
| Auras | 47 | **0**: each uses 2 to 11 pack pictures (only the floor circle is ours) |
| Trails, skills, storm set | 16 | 0 |
| Hits | 14 | 5: `shock`, `slash_arc`, `holy`, `acid_splat`, `claw_spores` |
| Hatch reveals, upgrade, buffs | 5 | 5: `hatch_dual`, `hatch_material`, `hatch_secret`, `area_upgrade`, `buff.stat_set` |
| Bursts | 6 | 0 (`coin_sell` needs 3 pack pictures swapped) |

So the auras need their pack pictures redrawn before they can be sold. That is about 60 distinct pictures across the
47 auras (shared ones: `spark_dot`, `glow_soft`, `glow_round`, `star_four`, `star_tiny`, `ring_glow`, `ring_thin`,
`smoke_dark`, `ember_streak`, `crescent_arc`, the lightning and flame flipbooks). Sources we may use: new ChatGPT
pictures (skill `chatgpt-art`, VFX recipe, uploaded on the owner's account) and Kenney's Particle Pack (CC0, approved).

Five showcase auras (`crystal_bloom`, `ember_sovereign`, `glacier_crown`, `solar_eclipse`, `starfall_sigil`) follow
the look of auras shown in TerKungTH's YouTube tutorial. The technique is fair to use; selling close copies of his
showcased looks is not. Before they are sold, each gets its own colours and shapes, so it is not his aura.

## The packs

Each pack is one Creator Store **Model** saved from Studio (never through the Assets API: an `.rbxm` upload becomes a
Package, which cannot be sold). Inside: ready-to-use effects (attachments and emitters a buyer can drop on a
character, no code needed), the VfxLib runtime for those who want the phone-friendly LOD and quality levels, a demo
script and a README. Thumbnails from the library's showroom.

| # | Pack | Effects | Price | Ready |
|---|---|---|---|---|
| 1 | **Hatch & Hit FX Kit** (pet and simulator games) | 3 egg hatch reveals (gold, prism, arcane secret), area upgrade, 4 stat buffs, 5 hits (shock, slash, holy, acid, plague claws) | USD 6.99 | **LIVE 2026-11-07**, Model 117863653160979 (`products/vfx-kit/STORE.md`) |
| 2 | **Pet Mutation Auras** | blazing flames, electric bolts, frozen snowfall, lunar halo, rainbow rings, shadow wisps | USD 4.99 | after redraw (~15 pictures) |
| 3 | **Anime Power Auras** (Level 1, light on phones) | azure fury, crimson awakening, hyper surge, power drop, radiant surge, static charge, thunder omen, twin balance, prism pulse, dawn star, heartfire, azure wisp, dove wings, night wings | USD 7.99 | after redraw |
| 4 | **Elemental Ground Auras** (Level 2, a floor circle each) | inferno sigil, frost vortex, crescent tide, tempest halo, sakura breeze, prism flame, glitch virus, binary breach, atomic pulse, crimson night, violet veil, clockwork hour | USD 9.99 | after redraw |
| 5 | **Celestial Auras** (Level 2) | astral drift, nebula veil, nova core, halo ascent, twilight wings, aether halo, thunder seraph | USD 7.99 | after redraw |
| 6 | **Legendary Showcase Auras** (heavy, for rare moments) | storm sigil, hellfire pulse, seraph grace, glacier crown, solar eclipse, starfall sigil, crystal bloom, ember sovereign | USD 12.99 | after redraw and the 5 looks made our own |
| 7 | **Storm Combat Set** | storm charge, ascend, lance, cleave, verdict, tempest ultimate, storm blade trail | USD 9.99 | after redraw |
| 8 | **Run Trails** | aurora curtain, comet lines, crimson flame, galaxy stars, ribbon ladder, tide splash, wind dash | USD 5.99 | after redraw |

Order: 1 first (no art work, sells while the rest is redrawn), then 2 (smallest redraw, proves the pipeline), then
3 to 8 in the order of the redraw work they share. One pack a week at most, so each listing can be judged.

## Work for each pack

1. Redraw the pack pictures it uses (ChatGPT or Kenney), upload on the owner's account, give them keys of their own
   (never the pack keys), and point the effects at them. Check the look against the old preview in the showroom.
2. Export: the effects as plain instances (an Attachment per effect with its emitters), plus the runtime without
   `PackTextures` (no other creator's id may ship).
3. Test in Studio on a fresh Baseplate: drop on an R15 and an R6 character, Play, look at it near and far, quality
   Low/High. Then Save to Roblox, Distribute, price, thumbnails, Roblox AI training off.
4. Log the asset id here and in `NEXT_STEPS.md`.
