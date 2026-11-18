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
     published but not yet purchasable (Roblox's review): check it on the next round.
     2026-11-08: REJECTED by moderation. The Configure page says "Not distributed on Creator Store. This asset
     may be in violation of Roblox Community Standards", with an Appeal button; Toolbox API purchasable=false,
     hasScripts=false, scriptCount 0 (the Pets kit and the Tycoon kit are purchasable=true). Nothing was saved
     or appealed. Next, in a live session: open the asset in Studio (Toolbox > My Models), check which part was
     taken out or moderated (scripts gone? a texture or flipbook image moderated?), fix it, re-upload as a new
     version, then distribute again or appeal if nothing is wrong. Next: redraw for pack 2 (pet
     mutation auras, about 15 pictures), one pack a week at most.
   - S3d, 2026-11-07: "Fantasy Creature Pets (64 Rigged, Animated)" LIVE on Creator Store, Model
     116354459698651, USD 14.99 (`products/creature-pets/STORE.md`): Egg Heist's 64 pets with the game's own
     procedural animator. Tested in Studio (64 of 64 animate). Next: watch sales weekly; a second pack of the 8
     bosses and 6 mounts if this one sells.
   - S3e, 2026-11-10: Tripo's "Light Up Diwali" weekly challenge (`research/2026-11-10-tripo-diwali-challenge.md`):
     3 ChatGPT reference pictures (lotus diya, baby elephant, star lantern), 3 models in Tripo (H3.1, 30 credits
     each); all 3 ENTERED on 11-10. RESULT (email 11-13): outside the top 10, so only USD 2 Tripo Cash. Tripo Cash is
     NOT credits: it is money off a plan or credit pack at checkout, valid 7 days (until about 11-20), so it is worth
     something only if the owner buys anyway. Lesson: without an audience to like the entries, a weekly challenge costs
     ~90 credits and returns nothing usable; enter one only with a ready model that costs no new credits.
   - S3e2, 2026-11-15: free-credit ways found (owner asked). Tripo: a survey email (11-11) gives 300 credits for
     the account email (owner fills it; Claude does not enter his data in a form reached from an email link). Meshy:
     support refunded 30 credits on 11-09 for the flat-slab task; "Get Free Credits" on the Subscriptions page
     (Discord connect 100 once, 50 per featured model, share actions); Contributor Program through Discord (1,000
     credits or a Pro month on acceptance). Both Discord routes need the owner's Discord account.
     Done 11-15 (Meshy, Chrome): Discord was already connected (100/100); followed 5 creators = +100 (balance 583 ->
     683). Left on Meshy's "Get Free Credits": G2 review 500 once (owner's G2 sign-in and his honest review), a social
     link on the Meshy profile 50 once (e.g. his GitHub URL; owner's yes first), Share on X 40/day (no X account),
     featured community posts 50 each (only models we will not sell), Contributor Program via Discord.
     GitHub link added 11-15 (+50, Meshy 733). The owner's order (11-15): put every daily credit task into the
     automatic daily work without being reminded. Done: scheduled task `free-credits-daily` (13:15 daily; Meshy Share
     on X from the owner's X, Tripo weekly Feature My Model +40, credit emails); sources and log in
     `research/free-credits-log.md`.
   - S3e3, 2026-11-16: Tripo MegaJam code redeemed (owner's yes): +3,000 Tripo credits (1,065 -> 4,065) that EXPIRE
     2026-11-23. Spend them before then on models for the next Roblox packs (about 100 text-to-model runs at 30
     each); unused ones are lost. The owner's paid Pro plan is unchanged (renews 2026-12-09).
   - S3f, 2026-11-15: the owner asked to split the skills and the VFX library into small products and sell them on
     Roblox and other sites.
     - VFX: 44 pictures redrawn in code, 5 packs built and tested in Studio (104 stands, 0 warnings), listings and
       thumbnails ready (`products/vfx-packs/STORE.md`, `media/`). Saved to Roblox and configured the same day:
       Wings 73482384781132 (9.99), Auras 117643355725830 (9.99), Combat 128561266438892 (12.99), Explosions
       113896470246117 (6.99), Weapons 106848503060543 (4.99), 3 thumbnails each, AI training off. Still in Roblox's
       review on 11-15 (`purchasable: false`). 2026-11-19: still not for sale, flagged by Roblox's moderation
       (Configure page: "Not distributed on Creator Store", Appeal button); see S3g, 2026-11-19.
       Reason on roblox.com/report-appeals: "Misusing Roblox Systems" for each (11-15), the same as the FX Kit
       on 11-07, which came back by itself before 11-16. Checked 11-19: the pack code has no require by id,
       loadstring, getfenv, HttpService or obfuscation, PackTextures is empty; toolbox shows hasScripts false,
       visibilityStatus 3, as the FX Kit did while blocked. Nothing to fix found; do not re-upload (re-sending
       moderated content risks the account). The owner said "Gửi kháng nghị": 5 appeals SENT 2026-11-19 (the same
       509-character text each; `products/vfx-packs/STORE.md`); Roblox says about 5 business days. Next round: read
       roblox.com/report-appeals and the toolbox API; once one is purchasable, save its new description (STORE.md).
     - Agent skills: 4 zips (VFX Craft 14, Creature Rigging + Animation 6, Game Art Cutout 7, bundle 22 USD) and their
       listings (`products/agent-skills/STORE.md`).
     - Owner, once (account and payout only, about 10 minutes each): sign up on **Agensi** (agensi.io, Stripe
       payout), **SkillHQ** (skillhq.dev, PayPal), **itch.io** (PayPal or Stripe, tax form) and **BuiltByBit**
       (PayPal). Then Claude makes every page and uploads the files.
   - S3g, 2026-11-15: the owner's order: download as many good free low-poly models from Meshy's community as
     possible, named and sorted by theme (weapons, monsters, props first), to build big Roblox packs later. No time
     or count limit; run until the owner says stop. How it works and the filters (CC0, textured, triangle limits):
     `products/lowpoly-library/README.md`. Models land in `products/lowpoly-library/models/` (git-ignored) with
     `catalog.csv`. Meshy allows one signed-in session: if the pane is signed out, the owner signs in again there,
     then a session restarts the in-page script (one line, in the README) and `tools/sorter.py`.
     2026-11-18: the owner paused downloading (Meshy's daily cap; 617 queued models left) and asked for the tidy-up.
     Done: whole library re-sorted (`tools/resort.py`), Sets split or reduced in Blender (`tools/split_sets.py`),
     split parts named by eye. Library: 10,745 GLBs, each at most 20k triangles, catalog complete; held back in
     `models/_Review/` (IP_Risk 131, Over_20k 9, Unclassified 67).
     Studio test done the same day (owner allowed `C:\Ai kiem tien` for uploads in the Slime Studio instance; only
     uploads go through it, the Slime place is never touched; inserts in StudioTest.rbxl, folder `LPReady`). It
     showed ~3,500 files carried another model's name (the old sorter guessed by triangle count): all relabelled
     from Edge's download records, `sorter.py` now matches by the Meshy id in the download link. Library after:
     10,739 GLBs, catalog consistent, `_Review` IP_Risk 112, Over_20k 2, Unclassified 4, Sets 12. Raw files are
     ~2 studs and up to 80 MB: `tools/roblox_ready.py` makes pack copies (studs per folder, 1024 colour map only,
     pivot at the bottom); 8 samples (sword, robot, dragon, tree, cottage, airship, fairy cat, rifle) import right.
     Still to fix: 72 weapons/props over 10k triangles after the relabel (under 20k, Roblox-fine); ~40 split parts
     and 65 files keep old credits.
     2026-11-18, the owner: "bán được nhóm nào thì cứ đăng bán hết đi, bán rẻ hơn so với thị trường một chút" (sell
     every group that can sell, a bit under the market, cheap and many). Done: 11 weapon packs built and their covers
     checked by eye (swords, axes, hammers, spears, bows, daggers, staffs, guns, shields, bombs, cannons; 22-30 models,
     8-14 MB each), price USD 2.99 (the Creator Store floor), listing text, tools: `products/lowpoly-library/STORE.md`.
     A GLB sent through the Assets API becomes a Package and cannot be sold (swords asset 85476012659902, private):
     each pack must be imported in a Studio test place and saved with Save to Roblox. The owner then allowed
     Studio ("Cho phép ngay"): all 11 saved from Studio as Models and configured (cover, Distribute, USD 2.99, AI
     training off); asset ids in `products/lowpoly-library/STORE.md`. All 11 for sale on 2026-11-18 (toolbox API
     purchasable: true; the last 5 passed Roblox's check within about an hour).
     2026-11-19 ("Làm tiếp"): 24 more packs (props, creatures, eggs, tech, dragons, animals, vehicles, slimes,
     characters) built, saved from Studio as Models and configured at USD 2.99: 35 low-poly packs in all, every one
     purchasable (toolbox API, 2026-11-19). Ids in `products/lowpoly-library/STORE.md`. An rbxm sent through the
     Assets API also becomes a Package: 7 packs had to be saved again from Studio.
     Same day, the owner's order: "tất cả các gói bán trên roblox với những lời giới thiệu không nên nhắc tới là do AI
     làm hay sưu tập gì cả, chỉ cần ghi trong danh sách có những gì thôi" (listings say only what is inside; never
     AI-made or collected). Done on Roblox for all 35 packs, the Tycoon Kit, the FX Kit and the Creature Pets. The 5
     VFX packs (S3f) could not be changed: Roblox has them "Not distributed on Creator Store ... may be in violation
     of Community Standards", Save off. Next: find what Roblox flags in them (or appeal), then save the new text from
     `products/vfx-packs/STORE.md`.
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
     2026-11-11: Roblox says Talent Hub is sunset on 12/7 (listings active until 12/6) and new posts go to
     DevForum's Collaboration category. Before 12/6: move the S5 round to DevForum hiring posts (the daily task's
     step B.1 too), and ask the two open clients to continue in DevForum messages if they reply.
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
   - Next listing change (still to do): Fiverr G1 title to
     "I will be your roblox scripter and code complete systems for your game", because G1 has few impressions and
     its title does not hold the word buyers search for. On 2026-11-02 and again on 2026-11-09 the edit page showed
     Fiverr's bot check ("It needs a human touch"), so it was not done. Owner: open the G1 edit page in the app's
     browser once and pass the check; then any session changes the title and logs it in the 2026-11-09 KPI row.
     Keep G2 as it is, to compare.
   - Live session wanted: fixed-price Roblox fits cannot be sent unattended. On 2026-11-09: "Roblox Luau Developer
     for Voxel Sandbox" (USD 500 fixed, see `listings/upwork-log.md`). Dropped on the 11-09 daily round: the
     client now shows payment unverified.
   - 2026-11-14: Upwork is signed out in the app's built-in browser (Proposals, Messages and Connects go to the
     login page). Owner: sign in to Upwork there again; until then the daily round can only search jobs, and the
     11-16 Plus gate cannot read the numbers.
3. **2026-11-16: the Freelancer Plus gate: FAILED** (Upwork net USD 0, needed 20; decided in the weekly round
   of 11-16). Cancel the renewal before **Nov 24** (Upwork > Settings > Membership & Connects, downgrade to Basic
   at the end of the cycle; the Connects already held stay usable). Blocked: Upwork is signed out in the app's
   built-in browser. Owner: sign in to Upwork there (or cancel the renewal himself); then any session cancels it
   and notes it in `PLAN.md` > Capital and the 2026-11-16 KPI row. The scheduled gate run (11-16 09:00) found
   Upwork signed out in Chrome too, so nothing was clicked; this item stays until the cancel is done.
4. **Signed out on 11-16: Fiverr too.** Owner: sign in to Fiverr in the app's built-in browser (and pass the bot
   check on the G1 edit page). Then the G1 title change (item 2) and the week's numbers.
5. **Creator Store, 11-16**: Tycoon Kit, Creature Pets and FX Kit purchasable (the FX Kit is back on sale, no
   appeal needed); the 5 VFX packs of 11-15 not yet public. Next round: check them again.
   2026-11-16 daily round: all 5 VFX packs now show "Not distributed on Creator Store. This asset may be in
   violation of Roblox Community Standards" (Appeal button), toolbox purchasable=false; nothing saved or appealed.
   The FX Kit had the same message on 11-08 and came back by itself, so wait 2-3 days; if still rejected, a live
   session opens one pack in Studio to find the moderated image or script, fixes it, or appeals.
   2026-11-17 daily round: toolbox API unchanged: Tycoon Kit, Creature Pets and FX Kit purchasable; the 5 VFX
   packs still purchasable=false (day 2 of the wait). Upwork still signed out in the app's built-in browser.
   2026-11-18 daily round: toolbox API unchanged (the 3 kits purchasable; the 5 VFX packs purchasable=false,
   hasScripts=false, day 3). The wait is over: a live session opens one pack in Studio, finds what moderation
   took out, fixes it or appeals. Upwork still signed out in the app's built-in browser.

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
