# Next steps (the work queue; Claude keeps it current)

Done items move to the KPI row of `PLAN.md` and leave this list.

## Needs the owner's computer: a Claude Code session there, in `C:\longthuy-online`

The owner allowed Claude to use his whole computer for this business (2026-10-25). The limits of `CLAUDE.md` still
hold: the owner himself signs up, signs in, does the identity checks, accepts terms, and enters payout or tax
details. Claude does the rest and leaves the final "Publish" click to him.

1. **Clone the repository.** `git clone https://github.com/ngotrongduong/longthuy-online C:\longthuy-online`
2. **Draw the gig pictures.**
   - Send the two prompts of `listings/fiverr.md` to ChatGPT in the browser, on its highest reasoning setting.
   - Save them as `listings/img/g1.png` and `listings/img/g2.png` (1280 x 769).
   - Commit and push.
3. **Fiverr.**
   - The owner creates the seller account (payouts to PayPal).
   - Then Claude fills in G1 and G2 from `listings/fiverr.md`, and the owner presses Publish.
4. **Upwork.**
   - The owner creates the account and the Agency "Long Thuy" (Long Thuy Pty Ltd), its payout method, and the
     W-8BEN-E form when it is asked for.
   - Then Claude fills in the profile from `listings/upwork.md`.
5. **Write it down.** Fill the first KPI row of `PLAN.md` (what is live, the date) and push.

## The owner, once

- Ask the accountant to move the Claude and ChatGPT bills to the company card, with the ABN on the invoices.

## After the listings are live

- Upwork: 2–3 proposals a day, drafted by Claude from `listings/upwork.md` and sent by the owner.
- Each order: `orders/<platform>-<id>/`, the work tested in Roblox Studio, then the delivery and the message drafted
  for the owner.
- Each week: "tuần kinh doanh" (the weekly round of `PLAN.md`).
