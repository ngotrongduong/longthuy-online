# Tycoon Systems Kit: Creator Store listing

Asset type: **Model**. File: `TycoonSystemsKit.rbxm` (or right-click the `TycoonSystemsKit` model in
`TycoonKitDev.rbxlx` > Save to Roblox). Suggested price: **USD 9.99**.

## Title (max 50 characters)

Tycoon Systems Kit: Droppers, Rebirth, Shop, Saving

## Description

A working tycoon core you drop into your own game. Everything runs on the server, every script is
plain, commented Luau inside this model, and all numbers live in one Config.

**What is included**
- Droppers, conveyor and collector. Drops are simulated by the server and sold at the collector.
- Buy-dropper upgrade with a cost curve (from a floor pad or the HUD).
- Rebirth: resets cash and droppers for a permanent cash multiplier. The HUD asks for a second tap first.
- Robux shop built from Config: game passes (ownership checked with MarketplaceService when the player
  joins and after a purchase; 2x Cash, Auto Collect and VIP effects applied on the server) and developer
  products (ProcessReceipt grants each purchase once, saved before it is confirmed).
- DataStore saving with a session lock: UpdateAsync lock with JobId and time, retries with backoff,
  autosave, BindToClose, and no save once another server holds the lock. In Studio without API access
  it falls back to in-memory play with a clear warning.
- Several plots: duplicate the example plot. Each player gets a free plot when they join and spawns on it.
- HUD for phone and PC: cash, multiplier, rebirths, save status, active boosts, toasts and a shop window.
  On touch screens the buttons move away from the jump button.
- Effects made on the client with Roblox's built-in textures: sell sparks, collect burst, dropper
  build-in and a rebirth moment. Effects far from the camera are skipped.
- Remote requests are checked on the server: name whitelist, argument types, one request per 0.2 s per
  player, plot ownership and price.

**Setup in 3 steps**
1. Insert the model and keep `TycoonSystemsKit` in Workspace. Move the Plot where you want it, and
   duplicate it for more players.
2. Open `Shared > Config` and put in your own game pass and developer product ids (they start at 0,
   "not for sale"). Tune prices, multipliers, dropper speed, the rebirth curve and autosave there.
3. Press Play. The Installer script moves each folder to its service every time a server starts.
   To save progress, publish the place. To test saving in Studio, turn on Game Settings > Security >
   Enable Studio Access to API Services. The README inside the model also explains how to install it
   by hand.

**What it does NOT do**
- It is a systems core, not a finished game. You get one plot design and one dropper type. There are no
  buy-a-wall or building unlocks, no pets, no leaderboards, no sounds and no tutorial.
- Shop prices are shown from Config. Roblox charges the price set on your Creator Dashboard.
- Passes and products cannot be truly bought in Studio. With real ids, Studio shows Roblox's
  test-purchase dialog. `Config.StudioOwnsAllPasses` lets you try the pass effects for free.
- Only one script in a game may set ProcessReceipt. If your game already has one, the README shows how
  to call this kit's handler from it.

No outside code is loaded, nothing is obfuscated, and no uploaded images or sounds are used.
The code was written with the help of an AI assistant, then tested in Roblox Studio.

## Tags

tycoon, dropper, rebirth, datastore, game pass, developer product, shop, saving, conveyor, kit, framework, HUD

## Thumbnails (1280 x 720, in this folder)

All three are real captures of the kit running in `TycoonKitDev.rbxlx`, taken in Studio Play with a
fixed camera. To set up the shots, a temporary script gave the test player cash and turned on all passes
(`StudioOwnsAllPasses`). The sign text was changed to "PLAYER'S TYCOON" on the client only, so the
owner's account name is not shown. The HUD's "Studio test: not saved" pill is real: that is how Studio
looks without API access.

1. `thumb-1-plot.png`: the plot running, with five droppers, golden drops on the belt, the collector on
   AUTO, the HUD and the active pass chips. It shows what the buyer gets.
2. `thumb-2-shop.png`: the shop window with three owned passes and the Cash Pack product.
3. `thumb-3-rebirth.png`: the rebirth moment with the "REBIRTH!" title, the light column, the sparks and
   the multiplier going from x1 to x1.5.

The older `portfolio/roblox-demo-1..3.png` come from the demo video, with caption bars and the old
sign. Do not use them for this listing.

## Publishing (Claude, once the Stripe seller account is approved)
- Open `TycoonKitDev.rbxlx`, right-click `TycoonSystemsKit` > Save to Roblox > Model (as Mue_you). Put in
  the title, description and tags above, and set the price on the Creator Store page.
- Upload the thumbnails on the asset's Creator Hub page, then log the asset id in `NEXT_STEPS.md`.
