# Upwork proposals log (one row per proposal; Claude keeps it)

Rules for choosing (2026-10-26):
- Only jobs in our scope: Roblox Luau systems, Roblox-ready 3D models (optimise, rig, animate), Lua scripting.
  Also any job that is easy for us and pays well (scripting, small web or 3D tools), since the owner wants the
  largest profit (2026-10-26). Rank candidates by expected profit: price × chance of winning − Connects cost − time.
- Skip: posts that forbid AI-generated work (our pipeline is AI-assisted, and every listing says so); payment not
  verified; a hire already made; mass posters paying a few dollars an hour; "preferred location" we do not meet
  when the job also costs 15+ Connects.
- Budget: Freelancer Plus gives 100 Connects a month and a proposal costs 11–19, so about 6–8 proposals a month.
  At most 2 proposals a day, only on strong fits, and keep 20 Connects in reserve. Buying more Connects is the
  owner's call (money). Boost bids only when it costs 1–2 Connects.
- The Claude app's scheduled task `upwork-daily-proposals` runs this every day at about 10:00 (the app must be open).
- Cover letters follow the template in `upwork.md`, in English, signed "Long Thuy", with an honest note when we
  lack a portfolio piece.

| Date | Job | Type | Our bid | Connects | Status |
|---|---|---|---|---|---|
| 2026-10-26 | [Roblox Tycoon: Rebirth System + Gamepass Shop (trial)](https://www.upwork.com/jobs/~022112082325470722379) | Fixed (client budget USD 5) | USD 20, < 1 month | 11 + boost 1 | Sent |
| 2026-10-26 | [Stylized Blender character refinement & rigging (Meshy model → Three.js GLB)](https://www.upwork.com/jobs/~022114380119304878200) | Hourly; asked for fixed quotes | USD 30/h; fixed 180 / 80 / 120 for the 3 phases, free head test | 18 | Sent |

| 2026-10-27 | [Flight Simulator GUI built with FlyWithLua (X-Plane 11)](https://www.upwork.com/jobs/~022113815955323894777) | Hourly (USD 5–60) | USD 30/h, rate increase Never, est. 6–8 h, fixed quote offered after seeing his code | 13 (no boost: 1st place was 41) | Sent |
| 2026-10-27 | [Blender LOD + Texture Baking (3 LODs, 4 maps 1024)](https://www.upwork.com/jobs/~022114791800937774789) | Fixed (client budget USD 11) | USD 35, < 1 month (3 days), boost 2 | 7 + 2 | Not sent: the scheduled run may not tick the fixed-price "Yes, I understand" notice |
| 2026-10-28 | [FPS Roblox Viewmodel Animations (~24 weapons)](https://www.upwork.com/jobs/~022114404312621172821) | Hourly | USD 30/h, rate increase Never, start with one weapon family | 12 (no boost: 4th place needed 5+) | Sent |

Seen and skipped on 2026-10-28: "Roblox developer and more" (19 Connects, Americas only); simulator/pets/DataStore and
obby jobs at USD 5 fixed (same mass-poster pattern); Discord manager, video creators, Shorts animator (not our scope);
3D jobs at USD 3–5/h or USD 20–30 fixed, unverified clients, Unreal realistic art (20–50 proposals). Invites: Airbnb
consultant and voice actors (not our scope, ignored). No client messages.

Connects left after 2026-10-26: 121, plus 8 free for Upwork's one-minute safety video = 129.
Connects left after 2026-10-27: 116.
Connects left after 2026-10-28: 114 (Upwork showed 126 before today's proposal).

Note (2026-10-27): in an unattended scheduled run, the app's permission check refuses ticking the fixed-price
"Yes, I understand" notice, so fixed-price proposals only go out from a live session. The scheduled run prefers
hourly jobs and leaves strong fixed-price ones listed in its report.
