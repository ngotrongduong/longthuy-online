--!strict
-- Config: EVERY tunable of the Tycoon Systems Kit lives here.
--
-- Installed at: ReplicatedStorage.TycoonKit.Config
-- Both the server and the clients read this module. Only the SERVER acts on the values
-- (money, prices, purchases); the client uses them to draw the HUD and the shop.
-- Nothing secret belongs here: clients can read it.
--
-- After changing a value, press Play: no other file needs editing for the numbers below.

local Config = {}

---------------------------------------------------------------------------------------
-- Economy
---------------------------------------------------------------------------------------
Config.StartCash = 0 -- cash of a brand-new player, and after each rebirth
Config.DropValue = 15 -- cash per collected drop, before multipliers
Config.DropInterval = 0.9 -- seconds between two drops of ONE dropper
Config.ConveyorSpeed = 13 -- studs per second the belt pushes drops toward the collector
Config.MaxLiveDrops = 60 -- hard cap of drop parts alive on one plot (protects the server)
Config.DropLifetime = 20 -- seconds before a drop that never reached the collector is removed

-- Droppers: the first one is free. The plot has one slot per dropper (Plot.DropperSlots);
-- the real maximum is the smaller of MaxDroppers and the number of slots.
Config.MaxDroppers = 6
Config.DropperBaseCost = 150 -- price of the 2nd dropper
Config.DropperCostGrowth = 1.6 -- each next dropper costs this much more

-- Price of the next dropper when the player owns `owned` droppers.
function Config.DropperCost(owned: number): number
	return math.floor(Config.DropperBaseCost * Config.DropperCostGrowth ^ (owned - 1) + 0.5)
end

---------------------------------------------------------------------------------------
-- Rebirth: resets cash and droppers, keeps a PERMANENT cash multiplier.
---------------------------------------------------------------------------------------
Config.RebirthBaseCost = 1000 -- price of the first rebirth
Config.RebirthCostGrowth = 2.5 -- each next rebirth costs this much more
Config.RebirthBonus = 0.5 -- +0.5x permanent multiplier per rebirth (1x, 1.5x, 2x, ...)

function Config.RebirthCost(rebirths: number): number
	return math.floor(Config.RebirthBaseCost * Config.RebirthCostGrowth ^ rebirths + 0.5)
end

function Config.RebirthMultiplier(rebirths: number): number
	return 1 + Config.RebirthBonus * rebirths
end

---------------------------------------------------------------------------------------
-- Game passes
--
--   REPLACE Id = 0 WITH YOUR OWN PASS IDS (Creator Dashboard > your experience >
--   Monetization > Passes). While Id is 0 the pass is shown in the shop but cannot be
--   bought, and the server never asks Roblox about it (it is treated as not owned).
--
--   Price is only the number SHOWN in the shop. Roblox charges the price you set on the
--   Creator Dashboard, so keep the two the same.
--
--   Effects the server understands (combine freely, add your own passes):
--     CashMultiplier = 2      every drop is worth 2x (multiplies with rebirth and other passes)
--     DropIntervalScale = 0.8 droppers drop 20% faster
--     AutoCollect = true      cash goes straight to the wallet, no collect pad needed
--     GoldenDrops = true      drops look golden (visual only)
--     NameTag = "VIP"         a tag above the player's head
---------------------------------------------------------------------------------------
-- Studio only: true = you own every pass while testing in Studio (try the effects for
-- free). Live servers ignore it. Leave false to test the real purchase prompts.
Config.StudioOwnsAllPasses = false

Config.Passes = {
	{
		Key = "DoubleCash", -- internal name, must be unique, letters only
		Id = 0, -- <-- replace with your game pass id
		Name = "2x Cash",
		Blurb = "Every drop is worth double.",
		Price = 149,
		Color = Color3.fromRGB(255, 196, 64),
		Icon = "2x",
		Effects = { CashMultiplier = 2, GoldenDrops = true },
	},
	{
		Key = "AutoCollect",
		Id = 0, -- <-- replace with your game pass id
		Name = "Auto Collect",
		Blurb = "Cash goes straight to your wallet.",
		Price = 99,
		Color = Color3.fromRGB(80, 214, 255),
		Icon = "AC",
		Effects = { AutoCollect = true },
	},
	{
		Key = "VIP",
		Id = 0, -- <-- replace with your game pass id
		Name = "VIP",
		Blurb = "+25% cash, faster droppers, gold tag.",
		Price = 249,
		Color = Color3.fromRGB(196, 120, 255),
		Icon = "VIP",
		Effects = { CashMultiplier = 1.25, DropIntervalScale = 0.8, NameTag = "VIP" },
	},
}

---------------------------------------------------------------------------------------
-- Developer products (can be bought many times). Granted through ProcessReceipt:
-- each purchase is granted exactly once and saved before Roblox is told it was granted.
--
--   REPLACE Id = 0 WITH YOUR OWN PRODUCT IDS (Creator Dashboard > Monetization >
--   Developer Products). Grant.Cash is the cash given. For other rewards, add a handler
--   in ShopService (see "Custom product rewards" there).
---------------------------------------------------------------------------------------
Config.Products = {
	{
		Key = "CashPack",
		Id = 0, -- <-- replace with your developer product id
		Name = "Cash Pack",
		Blurb = "+$5,000 cash, right now.",
		Price = 49,
		Color = Color3.fromRGB(64, 226, 146),
		Icon = "$",
		Grant = { Cash = 5000 },
	},
}

---------------------------------------------------------------------------------------
-- Saving (DataStoreService)
---------------------------------------------------------------------------------------
Config.DataStoreName = "TycoonKitProfiles_v1" -- change the name to start everyone fresh
Config.AutosaveSeconds = 60 -- autosave interval; it also refreshes the session lock
-- A session lock older than this is treated as left behind by a crashed server.
-- Must stay well above AutosaveSeconds (the kit uses at least 3x AutosaveSeconds).
Config.SessionLockTimeout = 300
Config.LoadRetries = 5 -- tries to take the profile before the player is asked to rejoin
Config.ReceiptHistory = 50 -- developer-product purchase ids remembered per player
-- In Studio without "Enable Studio Access to API Services" DataStores are unreachable.
-- true: play anyway with in-memory profiles (nothing is saved, a warning says so).
Config.StudioMemoryFallback = true

---------------------------------------------------------------------------------------
-- Anti-spam and misc
---------------------------------------------------------------------------------------
Config.RequestInterval = 0.2 -- minimum seconds between two requests of one player
Config.PadCooldown = 0.8 -- seconds before the same player can trigger a floor pad again
Config.TeleportToPlotOnSpawn = true -- put each player on their own plot when they spawn
Config.EffectsMaxDistance = 220 -- clients skip world effects of plots farther than this

return Config
