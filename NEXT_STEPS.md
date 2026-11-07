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
   - S3, Creator Store: the Tycoon Systems Kit is packaged and tested in Studio (2026-10-27,
     `products/tycoon-kit/`, listing text and steps in its `STORE.md`). Seller onboarding: Claude chose Australia,
     accepted the Creator Store Terms (owner's yes in chat) and pressed Continue; Roblox then asks for the 6-digit
     2-step verification code from the owner's authenticator app (create.roblox.com/settings/eligibility/priced-assets
     in Chrome), then Stripe's form (bank, tax). Both are the owner's. Stripe review takes up to 7 days. Then Claude
     publishes the kit at USD 9.99 and logs it.
     2026-10-27: the owner entered the code and filled Stripe's form. From 10-28 to 11-06 the asset's Configure page
     kept showing "Get approval to set prices / Register" and no Stripe or Roblox seller email came.
     2026-11-06 diagnosis (Roblox's own API, fetched on create.roblox.com while signed in):
     `marketplace-fiat-service/v1/seller/status` = SELLER_STATUS_RESTRICTED, setupCompleted false, country AU,
     created 2026-10-27; publishing requirements: pricing "Invalid", sellerOnboarding allowed, ID "Verified".
     So the Stripe onboarding was never finished; it is not a review in progress. Gmail has no Stripe seller mail.
     Owner: open create.roblox.com/settings/eligibility/priced-assets again, Continue, 2-step code, then go
     through every Stripe page until Stripe says the account is set up (bank and tax are his). Check the seller
     status API daily: setupCompleted true means publish the kit.
     Stripe's Verification summary (2026-11-06) lists 3 items still Incomplete, all the owner's: Business details
     (upload a document that verifies the company's tax details, e.g. the ABN registration or ASIC certificate),
     a bank account for payouts, and the W-8 tax form (W-8BEN-E for a company outside the US). Then "Agree and submit".
     2026-11-06: the owner finished it. Seller status SELLER_STATUS_COMPLETE, Priced assets page "Approved for
     distribution". Kit uploaded through Creator Hub's user-auth Assets API as asset 115048363596479 with the 3
     thumbnails (in moderation), but an .rbxm uploaded that way becomes subtype "Package", and the Configure page
     says "User is not authorized to distribute packages". Studio's AssetService:CreateAssetAsync is "not available
     yet", the legacy Upload.ashx is blocked by CORS, and Open Cloud upload from the Studio MCP needs the folder
     approved in Assistant Settings > MCP Permissions. Next: Studio's right-click Save to Roblox (makes a plain
     Model), then Distribute on Creator Store, USD 9.99, the thumbnails; then archive 115048363596479.
     PUBLISHED 2026-11-06: Studio Save to Roblox made plain Model 107252338850218
     (create.roblox.com/store/asset/107252338850218), Distribute on Creator Store on, USD 9.99, the 3 thumbnails
     (in moderation), Roblox AI training off. Toolbox API: published, purchasable. The Package upload
     115048363596479 stays private and off sale (models cannot be archived). Next: watch sales and reviews weekly.
     The daily task `upwork-daily-proposals` still has the old "check approval, then publish" step B.2; it no
     longer applies (2026-11-07: skipped, the kit is live).
   - S3c, 2026-11-07: VFX packs from the owner's library (`products/vfx-packs/PLAN.md`). Licence check: all 47
     auras wear other creators' free-pack pictures, so none can be sold until redrawn; 10 effects are all our art.
     Pack 1 "Hatch & Hit FX Kit (10 Effects, Mobile Ready)" LIVE 2026-11-07: Model 117863653160979, USD 6.99
     (`products/vfx-kit/STORE.md`), tested in Studio (10 of 10 play, no warnings). On 11-07 the Toolbox API said
     published but not yet purchasable (Roblox's review): check it on the next round. Next: redraw for pack 2 (pet
     mutation auras, about 15 pictures), one pack a week at most.
   - S3d, 2026-11-07: "Fantasy Creature Pets (64 Rigged, Animated)" LIVE on Creator Store, Model
     116354459698651, USD 14.99 (`products/creature-pets/STORE.md`): Egg Heist's 64 pets with the game's own
     procedural animator. Tested in Studio (64 of 64 animate). Next: watch sales weekly; a second pack of the 8
     bosses and 6 mounts if this one sells.
   - S3/S3b, started 2026-10-28: "Low Poly Forest Animals" (fox, wolf, deer, bear, boar, rabbit; Idle, Walk, Run,
     Eat). Built and checked in Blender 2026-10-28: `products/animal-pack/LowPolyForestAnimals_v1.zip` (8.6 MB),
     media in `media/` (committed). The pack (`dist/`, the zip) and its build scripts (`work/`) are git-ignored, so
     the public repo does not give the product away: they exist only on the owner's computer until uploaded. Listings, prices and
     the owner's sign-ups in `products/animal-pack/STORE.md`: Creator Store USD 9.99, itch.io 7.99 at launch, Fab 9.99.
     Owner, once: sign up on itch.io (PayPal payout) and Fab (Epic account, payout and tax). Claude makes the pages
     and uploads. Before selling it as "Roblox-ready", import one animal into Roblox Studio and check it.
   - S5b, owner's sign-ups when he has 10 minutes: Contra (0 % commission, Claude copies the Upwork profile and
     portfolio) and BuiltByBit (sell the Tycoon Kit there too; PayPal payout).
   - S5: Claude reads the Talent Hub and DevForum hiring posts and applies to Roblox scripting jobs that fit
     (`listings/talent-hub.md`: rules and log). Mue_you is signed in in the owner's Chrome (Claude in Chrome), not in
     the app's built-in browser. 2026-10-27: consent accepted, Creator Page public, first application sent.
     Replies arrive as Roblox notifications on create.roblox.com: check them in Chrome on each inbox round.
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
   - Next listing change (weekly round of 2026-11-09, if Upwork's title change has had its week): Fiverr G1 title to
     "I will be your roblox scripter and code complete systems for your game", because G1 has few impressions and
     its title does not hold the word buyers search for. On 2026-11-02 the edit page showed a bot check, so it was
     not done; if the check is still there, the owner passes it once. Keep G2 as it is, to compare.
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
- `upwork-daily-proposals`: about 10:00 daily. Up to 2 strong-fit proposals (`listings/upwork-log.md`); since
  2026-10-27 also the Roblox round in Chrome: Talent Hub replies, and whether priced selling is approved (then it
  publishes the Tycoon Kit).
- `weekly-business-review`: Mondays about 08:30. KPI, ledger, `LESSONS.md`, one listing change.
- `upwork-plus-gate`: once, 2026-11-16 09:00. Keep or cancel Freelancer Plus.

- Upwork: up to 2 strong-fit proposals a day, written and sent by Claude (rules and log in
  `listings/upwork-log.md`). Buying Connects is the owner's (money).
- Each order: `orders/<platform>-<id>/`, the work tested in Roblox Studio, then the delivery and the message, sent by
  Claude.
- Each week: "tuần kinh doanh" (the weekly round of `PLAN.md`).
