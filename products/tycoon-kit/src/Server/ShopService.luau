--!strict
-- ShopService: game passes and developer products, decided ONLY on the server.
-- Installed at: ServerScriptService.TycoonKit.ShopService
--
--   * Game passes: ownership comes from MarketplaceService.UserOwnsGamePassAsync when the
--     player joins, and from PromptGamePassPurchaseFinished (fired on the server by
--     Roblox) after a purchase in this session. The client can only ASK for a prompt; it
--     never tells the server "I own this". Effects are applied by TycoonService.
--   * Developer products: MarketplaceService.ProcessReceipt. Each PurchaseId is granted
--     once: it is stored in the profile and the profile is SAVED before we answer
--     PurchaseGranted. If anything fails we answer NotProcessedYet and Roblox retries.
--   * Pass ownership is mirrored to player attributes "Pass_<Key>" for the HUD only.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("TycoonKit")
local Config = require(Shared:WaitForChild("Config"))
local DataService = require(script.Parent.DataService)

local Fx = Shared:WaitForChild("Remotes"):WaitForChild("Fx") :: RemoteEvent

local ShopService = {}

local owned: { [Player]: { [string]: boolean } } = {}
local onChanged: ((Player) -> ())? = nil

-- Lookups read Config every time (the lists are short), so ids set at run time count.
local function find(list: { any }, field: string, value: any): any
	if value == 0 or value == nil then
		return nil -- 0 is the "not created yet" placeholder, never a real id
	end
	for _, entry in ipairs(list) do
		if entry[field] == value then
			return entry
		end
	end
	return nil
end
local function passByKey(key: string): any
	return find(Config.Passes, "Key", key)
end
local function passById(id: number): any
	return find(Config.Passes, "Id", id)
end
local function productByKey(key: string): any
	return find(Config.Products, "Key", key)
end
local function productById(id: number): any
	return find(Config.Products, "Id", id)
end

---------------------------------------------------------------------------------------
-- Custom product rewards
-- A product with an entry here uses it instead of the default Grant.Cash reward.
-- The function changes the profile and returns an "undo" function used if the save
-- fails (so a purchase is never half granted). Example:
--
--   ProductRewards.SkipRebirth = function(player, profile)
--       profile.Rebirths += 1
--       return function() profile.Rebirths -= 1 end
--   end
---------------------------------------------------------------------------------------
local ProductRewards: { [string]: (Player, DataService.Profile) -> () -> () } = {}

local function defaultReward(product: any): (Player, DataService.Profile) -> () -> ()
	return function(_player, profile)
		local cash = (product.Grant and product.Grant.Cash) or 0
		profile.Cash += cash
		return function()
			profile.Cash -= cash
		end
	end
end

local function setOwned(player: Player, key: string, value: boolean)
	local list = owned[player]
	if not list or list[key] == value then
		return
	end
	list[key] = value
	player:SetAttribute("Pass_" .. key, value)
	if onChanged then
		onChanged(player)
	end
end

local function checkOwnership(player: Player, pass: any): boolean
	if pass.Id == 0 then
		return false -- placeholder id: not created yet
	end
	for attempt = 1, 3 do
		local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
		if ok then
			return result == true
		end
		if attempt == 3 then
			warn("[TycoonKit] Could not check pass " .. pass.Key .. " for " .. player.Name .. ": " .. tostring(result))
		end
		task.wait(attempt)
	end
	return false
end

-- True when the player owns the pass with this Key.
function ShopService.owns(player: Player, key: string): boolean
	local list = owned[player]
	return list ~= nil and list[key] == true
end

-- True when any owned pass has this effect; returns the combined value for numbers
-- (multiplied) or true for flags. Used by TycoonService.
function ShopService.effect(player: Player, name: string): any
	local result: any = nil
	for _, pass in ipairs(Config.Passes) do
		local value = pass.Effects and pass.Effects[name]
		if value ~= nil and ShopService.owns(player, pass.Key) then
			if type(value) == "number" then
				result = (result or 1) * value
			else
				result = value
			end
		end
	end
	return result
end

-- Remote: the player tapped a pass card.
function ShopService.promptPass(player: Player, key: string)
	local pass = passByKey(key)
	if not pass or ShopService.owns(player, key) then
		return
	end
	if pass.Id == 0 then
		warn("[TycoonKit] Pass '" .. key .. "' has Id = 0. Put your pass id in Config.Passes.")
		Fx:FireClient(player, "Denied", "Not for sale yet")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, pass.Id)
end

-- Remote: the player tapped a product card.
function ShopService.promptProduct(player: Player, key: string)
	local product = productByKey(key)
	if not product then
		return
	end
	if product.Id == 0 then
		warn("[TycoonKit] Product '" .. key .. "' has Id = 0. Put your product id in Config.Products.")
		Fx:FireClient(player, "Denied", "Not for sale yet")
		return
	end
	MarketplaceService:PromptProductPurchase(player, product.Id)
end

function ShopService.playerAdded(player: Player)
	owned[player] = {}
	-- Studio only: Config.StudioOwnsAllPasses lets you try every pass effect for free.
	local studioAll = Config.StudioOwnsAllPasses == true and RunService:IsStudio()
	for _, pass in ipairs(Config.Passes) do
		player:SetAttribute("Pass_" .. pass.Key, false)
		if studioAll then
			setOwned(player, pass.Key, true)
		else
			task.spawn(function()
				if checkOwnership(player, pass) and player.Parent then
					setOwned(player, pass.Key, true)
				end
			end)
		end
	end
end

function ShopService.playerRemoving(player: Player)
	owned[player] = nil
end

local function processReceipt(receipt: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local product = productById(receipt.ProductId)
	if not product then
		warn("[TycoonKit] Receipt for unknown product id " .. tostring(receipt.ProductId) .. " (add it to Config.Products).")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- granted next time they join
	end
	local profile = DataService.get(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- still loading
	end

	local id = tostring(receipt.PurchaseId)
	if table.find(profile.Receipts, id) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- granted before: do not grant twice
	end

	-- Grant, remember the receipt, and SAVE before confirming.
	local reward = ProductRewards[product.Key] or defaultReward(product)
	local ok, undo = pcall(reward, player, profile)
	if not ok then
		warn("[TycoonKit] Reward for " .. product.Key .. " failed: " .. tostring(undo))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	table.insert(profile.Receipts, id)
	while #profile.Receipts > Config.ReceiptHistory do
		table.remove(profile.Receipts, 1)
	end

	local saved = DataService.save(player)
	local studioTest = DataService.getMode() == "Memory" and RunService:IsStudio()
	if not saved and not studioTest then
		-- Roll back and let Roblox retry later: never confirm a grant we could not store.
		undo()
		local index = table.find(profile.Receipts, id)
		if index then
			table.remove(profile.Receipts, index)
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	Fx:FireClient(player, "ProductGranted", product.Name)
	if onChanged then
		onChanged(player)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- changed(player) is called whenever something that affects the plot changed.
function ShopService.start(changed: (Player) -> ())
	onChanged = changed

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local pass = passById(passId)
		if purchased and pass and player.Parent then
			-- Fired on the server by Roblox itself, so it can be trusted.
			setOwned(player, pass.Key, true)
		end
	end)

	-- Only ONE script in a game may set ProcessReceipt. If your game already has one,
	-- call this kit's handler from it instead (see README).
	MarketplaceService.ProcessReceipt = processReceipt
end

-- Exposed for games that already have their own ProcessReceipt (see README).
ShopService.processReceipt = processReceipt
ShopService.ProductRewards = ProductRewards

return ShopService
