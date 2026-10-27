--!strict
-- ShopService: game passes and developer products, decided ONLY on the server.
--
--   * Pass ownership comes from MarketplaceService (UserOwnsGamePassAsync) at join and from
--     PromptGamePassPurchaseFinished after a purchase, then is re-checked on the server.
--     The client can only ASK for a prompt; it never says "I own this".
--   * Developer products go through ProcessReceipt. Each PurchaseId is granted once:
--     it is stored in the profile and the profile is saved BEFORE we return PurchaseGranted.
--     If anything fails we return NotProcessedYet and Roblox retries later.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local DataService = require(script.Parent.DataService)

local ShopService = {}

local owned: { [Player]: { [string]: boolean } } = {}
local passById: { [number]: any } = {}
local passByKey: { [string]: any } = {}
local productById: { [number]: any } = {}
local onChanged: ((Player) -> ())? = nil

for _, pass in ipairs(Config.Passes) do
	passByKey[pass.Key] = pass
	if pass.Id ~= 0 then
		passById[pass.Id] = pass
	end
end
for _, product in ipairs(Config.Products) do
	if product.Id ~= 0 then
		productById[product.Id] = product
	end
end

local function setOwned(player: Player, key: string, value: boolean)
	owned[player] = owned[player] or {}
	if owned[player][key] == value then
		return
	end
	owned[player][key] = value
	player:SetAttribute("Pass_" .. key, value) -- replicated, for display only
	if onChanged then
		onChanged(player)
	end
end

local function checkOwnership(player: Player, pass: any): boolean
	if pass.Id == 0 then
		return false -- pass not created yet (placeholder id)
	end
	for _ = 1, 3 do
		local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
		if ok then
			return result
		end
		task.wait(1)
	end
	return false
end

function ShopService.owns(player: Player, key: string): boolean
	return owned[player] ~= nil and owned[player][key] == true
end

-- Called by the remote handler when the player taps a pass card.
function ShopService.promptPass(player: Player, key: string)
	local pass = passByKey[key]
	if not pass or ShopService.owns(player, key) then
		return
	end
	if pass.Id == 0 then
		warn("[ShopService] Pass '" .. key .. "' has no id yet; set it in Config.Passes.")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, pass.Id)
end

-- DEMO ONLY. Used by AutoDemo_ForRecording to show the owned state without a real Robux
-- purchase (Studio cannot sell passes). It goes through the same setOwned path as a real
-- purchase. Nothing else calls it.
function ShopService.grantForDemo(player: Player, key: string)
	if passByKey[key] then
		setOwned(player, key, true)
	end
end

function ShopService.playerAdded(player: Player)
	owned[player] = {}
	for _, pass in ipairs(Config.Passes) do
		player:SetAttribute("Pass_" .. pass.Key, false)
		task.spawn(function()
			if checkOwnership(player, pass) and player.Parent then
				setOwned(player, pass.Key, true)
			end
		end)
	end
end

local function processReceipt(receipt): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local product = productById[receipt.ProductId]
	if not player or not product then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile = DataService.get(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local id = tostring(receipt.PurchaseId)
	if table.find(profile.Receipts, id) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted earlier
	end

	-- Grant, remember the receipt, and save before confirming.
	profile.Cash += product.Cash
	table.insert(profile.Receipts, id)
	while #profile.Receipts > Config.ReceiptHistory do
		table.remove(profile.Receipts, 1)
	end
	if DataService.getMode() == "DataStore" and not DataService.save(player) then
		-- Roll back and let Roblox retry: never confirm a grant we could not store.
		profile.Cash -= product.Cash
		table.remove(profile.Receipts, table.find(profile.Receipts, id) :: number)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if onChanged then
		onChanged(player)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ShopService.start(changed: (Player) -> ())
	onChanged = changed

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local pass = passById[passId]
		if purchased and pass then
			-- This event fires on the server from Roblox itself, so it can be trusted.
			setOwned(player, pass.Key, true)
		end
	end)

	MarketplaceService.ProcessReceipt = processReceipt

	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)
end

return ShopService
