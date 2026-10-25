# Next steps (the work queue; Claude keeps it current)

Done items move to the KPI row of `PLAN.md` and leave this list.

## Needs the owner's computer: a Claude Code session there, in `C:\Ai kiem tien`

`C:\Ai kiem tien` is the owner's folder for this business (2026-10-25): everything of it is kept there, and it is
the clone of this repository.

The owner allowed Claude to use his whole computer for this business (2026-10-25). The limits of `CLAUDE.md` still
hold: the owner himself signs up, signs in, does the identity checks, accepts terms, and enters payout or tax
details. Claude does the rest and leaves the final "Publish" click to him.

1. **Clone the repository into `C:\Ai kiem tien`.** Done 2026-10-26 (the folder was empty; it is now the clone, and
   git pushes from it with the owner's saved GitHub login). The owner's own files stay out of git until he says what
   they are; private ones (ID, bank, tax) never go in.
2. **Fiverr.**
   - Done 2026-10-26 (account @dngng1, display name DuongN, signed in in the desktop app's built-in browser): the
     seller profile, and G1 and G2 filled from `listings/fiverr.md` with their covers.
     - G1: Programming & Tech > Game Development > Customization (Roblox, scripting, 3D, PC/console/mobile).
     - G2: Graphics & Design > Game Art > Character Design (3D, low poly; FBX, Blend, GLTF, GLB, rbxl), because
       Fiverr suggested Game Art and Character Modeling would promise modelling from scratch.
   - Left for the owner:
     - G2 gallery: tick the declaration that the materials are ours, then Save & Continue (an attestation is his
       to make).
     - ID verification, and the tax form (non-US: W-8BEN, not W-9), in the Freelancer dashboard. Fiverr shows no
       gig to buyers before both are done, so this is the real "Publish".
     - Payouts to PayPal, when Fiverr asks.
   - Checked 2026-10-26 after the owner said he had done them: G1 and G2 sit under Gigs > Draft, and the dashboard
     still shows "ID verification: Complete verification" (step 3 of 5), so the gigs are not live yet. Checked again:
     the verification page (Persona) lists three steps left for the owner: phone number, security question, ID
     upload. After the owner did them, the dashboard's ID step has no button left, and step 4 "Submit your Form
     W-9" shows "Complete W-9": the owner answers it as a non-US person (whether as himself or as Long Thuy Pty Ltd
     is the accountant's question). Step 5, Publish, comes after. The owner filed the tax form as non-US; the
     dashboard now offers "Publish Gig", and each gig's publish page is
     `fiverr.com/users/dngng1/manage_gigs/<gig-slug>/edit?tab=publish&wizard=5` (slugs:
     `script-a-complete-exploit-safe-system-for-your-roblox-game`, `make-your-3d-model-roblox-ready-low-poly-and-rigged`).
     The owner presses Publish Gig on both.
   - Checked 2026-10-26 after the owner said he had pressed Publish Gig on both: Active and Pending approval are
     empty, both gigs are still in Draft, and the dashboard still offers "Publish Gig". The publish page shows no
     error. Fiverr's own text says a gig can be published "once you received a notification that your Form W-9
     check was completed successfully", so the tax-form check may still be running: the owner presses Publish Gig
     again, reads any message Fiverr shows, and waits for Fiverr's email if it says so.
   - After the second try: **G1 is Active (live)**. G2 is still Draft; all its wizard steps are ticked and its
     publish page shows no error, so it only needs the owner's Publish Gig click.
   - Fiverr titles take letters and numbers only (no commas or hyphens). Its pages may show a "Press & Hold" bot
     check: the owner does it.
3. **Better covers (optional; the ones in place are good enough to publish).**
   - Send the two prompts of `listings/fiverr.md` to ChatGPT in the browser, on its highest reasoning setting.
   - Keep whichever cover reads better at thumbnail size, and note it in the KPI row: a cover change is the week's
     one change.
   - The covers in place are HTML (`listings/img/src/`), rendered by `node listings/img/src/render.js <in.html>
     <out.png>` (Playwright, 1280 x 769).
4. **Upwork.**
   - The owner creates the account and the Agency "Long Thuy" (Long Thuy Pty Ltd), its payout method, and the
     W-8BEN-E form when it is asked for.
   - Then Claude fills in the profile from `listings/upwork.md`.
   - 2026-10-26: not signed in to Upwork in the built-in browser yet.
5. **Write it down.** Fill the first KPI row of `PLAN.md` (what is live, the date) and push.

## The owner, once

- Ask the accountant to move the Claude and ChatGPT bills to the company card, with the ABN on the invoices.

## After the listings are live

- Upwork: 2–3 proposals a day, drafted by Claude from `listings/upwork.md` and sent by the owner.
- Each order: `orders/<platform>-<id>/`, the work tested in Roblox Studio, then the delivery and the message drafted
  for the owner.
- Each week: "tuần kinh doanh" (the weekly round of `PLAN.md`).
