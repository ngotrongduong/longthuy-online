--!strict
-- Config: every tunable number of the tycoon lives here, shared by server and client.
-- The server is the only side that ACTS on these values; the client only displays them.

local Config = {}

-- Economy -----------------------------------------------------------------
Config.StartCash = 0
Config.DropValue = 15 -- cash per collected drop before multipliers
Config.DropInterval = 0.9 -- seconds between drops, per dropper
Config.MaxDroppers = 6
Config.MaxLiveDrops = 60 -- hard cap on physics parts per plot

-- Cost of the Nth dropper (the first one is free)
function Config.DropperCost(owned: number): number
	return math.floor(150 * 1.6 ^ (owned - 1) + 0.5)
end

-- Rebirth -----------------------------------------------------------------
Config.RebirthBaseCost = 1000
Config.RebirthCostGrowth = 2.5
Config.RebirthBonus = 0.5 -- +0.5x permanent multiplier per rebirth

function Config.RebirthCost(rebirths: number): number
	return math.floor(Config.RebirthBaseCost * Config.RebirthCostGrowth ^ rebirths + 0.5)
end

function Config.RebirthMultiplier(rebirths: number): number
	return 1 + Config.RebirthBonus * rebirths
end

-- Game passes ---------------------------------------------------------------
-- Id = 0 means "not created yet": replace with the real ids from the Creator Dashboard.
-- With Id 0 the server never asks MarketplaceService and treats the pass as not owned.
Config.Passes = {
	{
		Key = "DoubleCash",
		Id = 0,
		Name = "2x Cash",
		Blurb = "Every drop is worth double.",
		Price = 149,
		Color = Color3.fromRGB(255, 196, 64),
		Icon = "2x",
	},
	{
		Key = "AutoCollect",
		Id = 0,
		Name = "Auto Collect",
		Blurb = "Cash goes straight to your wallet.",
		Price = 99,
		Color = Color3.fromRGB(80, 214, 255),
		Icon = "AC",
	},
	{
		Key = "VIP",
		Id = 0,
		Name = "VIP",
		Blurb = "+25% cash, faster droppers, gold tag.",
		Price = 249,
		Color = Color3.fromRGB(196, 120, 255),
		Icon = "VIP",
	},
}

Config.PassEffects = {
	DoubleCash = { CashMultiplier = 2 },
	AutoCollect = {},
	VIP = { CashMultiplier = 1.25, DropIntervalScale = 0.8 },
}

-- Developer product (consumable) handled through ProcessReceipt
Config.Products = {
	{ Key = "CashPack", Id = 0, Name = "Cash Pack", Cash = 5000, Price = 49 },
}

-- Data --------------------------------------------------------------------
Config.DataStoreName = "TycoonProfiles_v1"
Config.AutosaveSeconds = 60
Config.SessionLockTimeout = 30 * 60 -- a lock older than this is treated as stale
Config.LoadRetries = 5
Config.ReceiptHistory = 50 -- purchase ids remembered per player

return Config
