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
   - 2026-10-26: the owner's Fiverr account (@dngng1) is signed in, in the desktop app's built-in browser. Claude
     filled the seller profile (title, About, skills: Roblox development, Roblox scripts, Blender) from
     `listings/fiverr.md`. Fiverr will not go on until the owner adds a display name and a profile photo.
   - The owner creates the seller account (payouts to PayPal).
   - Then Claude fills in G1 and G2 from `listings/fiverr.md`, with the covers `listings/img/g1.png` and
     `listings/img/g2.png`, and the owner presses Publish.
   - The owner can also do this step alone, from any browser: paste the texts and upload the two covers.
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
