--[[
================================================================================
 TYCOON SYSTEMS KIT  -  README
================================================================================

 A working, server-authoritative tycoon core you drop into your own game:
 droppers, conveyor and collector, dropper upgrades, rebirth with a permanent
 multiplier, a Robux shop (game passes + developer products), DataStore saving
 with a session lock, and a HUD that scales from phones to PC.

 Written in plain Luau, readable and commented. Every script is inside this
 model: nothing is downloaded or loaded from other assets at run time, no code
 is built from strings, nothing is obfuscated, and no uploaded images or sounds
 are needed (effects use Roblox's built-in rbxasset:// textures).

--------------------------------------------------------------------------------
 SETUP IN 3 STEPS
--------------------------------------------------------------------------------
 1. Insert the model. Keep "TycoonSystemsKit" in Workspace. Move the Plot where
    you want it (duplicate the Plot for more players: one plot per player in a
    server; every copy keeps the "TycoonPlot" tag).
 2. Open Shared > Config. Put your own game pass ids and developer product ids
    where it says "replace with your ... id" (Id = 0 means "not for sale yet").
    Tune prices, multipliers, dropper speed, rebirth curve, autosave there too.
 3. To save progress: publish the place, then Game Settings > Security >
    "Enable Studio Access to API Services" (only needed to test saving in
    Studio; live servers always save). Press Play.

 The Installer script does the rest each time a server starts:
   Shared -> ReplicatedStorage.TycoonKit
   Server -> ServerScriptService.TycoonKit   (Main is enabled by the Installer)
   Client -> StarterPlayer.StarterPlayerScripts.TycoonKit
   Plot(s) -> Workspace.TycoonPlots
 Prefer a permanent install? Do those moves yourself in Studio, rename each
 folder to "TycoonKit", set ServerScriptService.TycoonKit.Main Enabled = true,
 and delete the empty model with the Installer.

--------------------------------------------------------------------------------
 WHAT IS INSIDE
--------------------------------------------------------------------------------
 Shared/Config        every number and every pass/product (start here)
 Shared/Format        $1,234 / $3.40M / x1.5 formatting
 Shared/Remotes       Action (client -> server requests), Fx, FxFast (server -> clients)
 Server/Main          starts the services, player join/leave, checks every request
 Server/DataService   profiles: UpdateAsync session lock (JobId + time), retries
                      with backoff, autosave, BindToClose, refuses to save when
                      the lock was taken by another server
 Server/ShopService   game passes (UserOwnsGamePassAsync on join +
                      PromptGamePassPurchaseFinished) and developer products
                      (ProcessReceipt, each purchase granted once and saved
                      before it is confirmed)
 Server/TycoonService plots, droppers, conveyor, collector, upgrades, rebirth
 Server/Assets/DropperTemplate   the dropper model that is built on each slot
 Client/Hud           stat cards, buttons, toasts, shop window
 Client/Effects       particles and moments (sell, collect, build, rebirth)
 Plot                 example plot (tag "TycoonPlot")

--------------------------------------------------------------------------------
 HOW IT PLAYS
--------------------------------------------------------------------------------
 * Each player gets the first free plot on join and is placed on it.
 * Droppers drop on the belt; the collector sells each drop for
   DropValue x rebirth multiplier x pass multipliers. Cash waits in the
   collector until the player steps on COLLECT (or owns Auto Collect).
 * BUY DROPPER (pad or HUD) builds the next dropper; REBIRTH resets cash and
   droppers for a permanent +RebirthBonus multiplier. The HUD asks for a
   second tap before a rebirth.
 * SHOP lists every game pass and developer product from Config.

--------------------------------------------------------------------------------
 MAKING IT YOURS
--------------------------------------------------------------------------------
 * New pass: add an entry to Config.Passes with Effects (CashMultiplier,
   DropIntervalScale, AutoCollect, GoldenDrops, NameTag). No other code needed.
 * Try the pass effects for free in Studio: Config.StudioOwnsAllPasses = true
   (ignored on live servers).
 * New product: add an entry to Config.Products with Grant = { Cash = n }, or
   write a custom reward in ShopService.ProductRewards.
 * More dropper slots: add Slot7, Slot8 ... parts in Plot.DropperSlots and raise
   Config.MaxDroppers.
 * New look: restyle the Plot and Server/Assets/DropperTemplate freely. Keep the
   names listed at the top of TycoonService (Belt, Sensor, pads, slots, Spout).
 * Already have a ProcessReceipt in your game? Only one script may set it. Remove
   the line "MarketplaceService.ProcessReceipt = processReceipt" in ShopService
   and call ShopService.processReceipt(receipt) from your own handler for this
   kit's product ids.
 * Saved data: the DataStore is Config.DataStoreName; keys are "player_<UserId>".

--------------------------------------------------------------------------------
 WHAT IT DOES NOT DO
--------------------------------------------------------------------------------
 * It is a systems core, not a finished game: one plot design, one dropper
   type, no walls/doors/buttons-to-buy-buildings progression, no pets,
   no leaderboards, no sounds, no tutorial.
 * Prices on the shop cards are typed in Config; Roblox charges what you set
   on the Creator Dashboard. Keep them the same.
 * In Studio without API access nothing is saved (a warning says so and the
   HUD shows "Studio test: not saved").
 * Game passes and products cannot be really bought in Studio; Studio shows
   Roblox's test purchase dialog when the ids are real.

 Support: see the Creator Store page of this model.
================================================================================
]]

return {}
