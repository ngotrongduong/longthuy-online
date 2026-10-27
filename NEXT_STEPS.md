# Next steps (the work queue; Claude keeps it current)

Done items move to the KPI row of `PLAN.md` and leave this list.

## Needs the owner's computer: a Claude Code session there, in `C:\Ai kiem tien`

`C:\Ai kiem tien` is the owner's folder for this business (2026-10-25): everything of it is kept there, and it is
the clone of this repository.

The owner allowed Claude to use his whole computer for this business (2026-10-25), and ordered (2026-10-26) that
Claude press the buttons itself (Publish, Save, choices): see `CLAUDE.md`. The owner only does money steps and what
Claude's rules forbid it (sign-in, bot checks, identity documents, ID or tax numbers).

Done 2026-10-26 (now in the KPI row): this folder is the clone, and Fiverr G1 and G2 are live (Active).

**Fiverr facts** (account @dngng1, display name DuongN, signed in in the desktop app's built-in browser):
- G1: Programming & Tech > Game Development > Customization (Roblox, scripting, 3D, PC/console/mobile).
- G2: Graphics & Design > Game Art > Character Design (3D, low poly; FBX, Blend, GLTF, GLB, rbxl). Fiverr suggested
  Game Art; Character Modeling would promise modelling from scratch.
- Edit pages: `fiverr.com/users/dngng1/manage_gigs/<slug>/edit` (slugs
  `script-a-complete-exploit-safe-system-for-your-roblox-game`, `make-your-3d-model-roblox-ready-low-poly-and-rigged`).
- Titles take letters and numbers only. Opening pages fast brings a "Press & Hold" bot check, which only the owner
  may do: wait 10 s or more between page loads.
- ID verification and the tax form (filed as non-US) are done. Payouts to PayPal: the owner, when Fiverr asks.

0. **New streams (2026-10-27, `research/2026-10-27-income-options.md`).**
   - S3, Creator Store: Claude packages the Tycoon Systems Kit as a sellable model (no demo driver, README, clean
     scripts that pass the store's script rules, tested in Studio). The owner, once: on create.roblox.com as Mue_you,
     turn on 2-step verification and open the Stripe seller account (bank details). Then Claude publishes it at
     USD 9.99 and logs it.
   - S3, then: a rigged, animated low-poly animal pack for Roblox (the fox pipeline, 6–8 animals), USD 14.99.
   - S5: Claude reads the Talent Hub and DevForum hiring posts and applies to Roblox scripting jobs that fit. The
     Talent Hub needs a Roblox sign-in: the owner signs in as Mue_you in the desktop app's built-in browser.
1. **Better covers (optional; the ones in place are good enough to publish).**
   - Send the two prompts of `listings/fiverr.md` to ChatGPT in the browser, on its highest reasoning setting.
   - Keep whichever cover reads better at thumbnail size, and note it in the KPI row: a cover change is the week's
     one change.
   - The covers in place are HTML (`listings/img/src/`), rendered by `node listings/img/src/render.js <in.html>
     <out.png>` (Playwright, 1280 x 769).
2. **Upwork.**
   - The owner signs up and signs in, in the desktop app's built-in browser, and later adds the payout method and the
     tax ID on the W-8BEN-E form.
   - Claude does the rest: the freelancer profile and the Agency "Long Thuy" (Long Thuy Pty Ltd) from
     `listings/upwork.md`, and publishes them.
   - 2026-10-26: signed in (the account's name shows as "Zu Finches"). Claude filled profile steps 1–3 (see
     `listings/upwork.md`). Step 3 will not go on without a profile photo: the owner adds a real headshot. Upwork's
     name must match the owner's ID, so the owner checks the account name too.
   - Photo added; the owner filled step 4 (personal info); Claude did step 5 and submitted the profile, and created
     and filled the Agency "Long Thuy" on the free plan (details and costs in `listings/upwork.md`).
   - 2026-10-26: the owner bought Freelancer Plus (9.99 now, 19.99 from Nov 25; 100 Connects a month); the
     "profile is still private" banner is gone. Upwork shows the account name "Zu Finches"; it must match his ID.
     Claude entered the owner's real name (Duong Ngo); the owner set the password and security question, and Upwork
     says the name change is under review. Approved 2026-10-26 (Upwork email "Your profile name change was
     approved"). Time zone set to Sydney, Melbourne.
   - Proposals started 2026-10-26 (2 sent; rules, budget and log in `listings/upwork-log.md`). As the freelancer:
     the Agency is on the free plan and cannot bid.
   - Portfolio done 2026-10-27 (`listings/portfolio.md`): 4 items on Upwork, both Fiverr galleries. Next: import
     the fox into Roblox Studio once to check scale and facing, so it can be called "tested in Roblox".
3. **2026-11-16: the Freelancer Plus gate** (in `PLAN.md` > Capital): Upwork net so far against USD 20; below it,
   cancel the renewal before Nov 24. The Claude app's scheduled task `upwork-plus-gate` runs it at 09:00 that day
   (the app must be open; otherwise it runs at next launch). If it has not run, do it in any session on or after
   that date.

## The owner, once

- Ask the accountant to move the Claude and ChatGPT bills to the company card, with the ABN on the invoices.

## After the listings are live

Scheduled tasks in the Claude app (they run only while the app is open; missed runs run at next launch):
- `marketplace-inbox-watch`: 08:00, 11:00, 14:00, 17:00, 20:00. Reads Fiverr and Upwork notifications in Gmail,
  ignores scams, answers real buyers, opens order folders.
- `upwork-daily-proposals`: about 10:00 daily. Up to 2 strong-fit proposals (`listings/upwork-log.md`).
- `weekly-business-review`: Mondays about 08:30. KPI, ledger, `LESSONS.md`, one listing change.
- `upwork-plus-gate`: once, 2026-11-16 09:00. Keep or cancel Freelancer Plus.

- Upwork: up to 2 strong-fit proposals a day, written and sent by Claude (rules and log in
  `listings/upwork-log.md`). Buying Connects is the owner's (money).
- Each order: `orders/<platform>-<id>/`, the work tested in Roblox Studio, then the delivery and the message, sent by
  Claude.
- Each week: "tuần kinh doanh" (the weekly round of `PLAN.md`).
