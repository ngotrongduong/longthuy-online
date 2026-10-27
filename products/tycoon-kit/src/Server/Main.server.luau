--!strict
-- Main: starts the kit's services, handles players joining and leaving, and checks
-- every request a client sends.
-- Installed at: ServerScriptService.TycoonKit.Main
--
-- This Script is DISABLED inside the TycoonSystemsKit model so it does not run while the
-- model sits in Workspace. The Installer moves it to ServerScriptService and enables it.
-- If you install by hand, set Main.Enabled = true after moving the folder.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("TycoonKit")
local Config = require(Shared:WaitForChild("Config"))
local Action = Shared:WaitForChild("Remotes"):WaitForChild("Action") :: RemoteEvent

local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)
local TycoonService = require(script.Parent.TycoonService)

DataService.start()
ShopService.start(TycoonService.refresh)
TycoonService.start()

---------------------------------------------------------------------------------------
-- Players
---------------------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	local profile = DataService.load(player)
	if not profile or not player.Parent then
		return -- kicked (data locked elsewhere) or left while loading
	end
	ShopService.playerAdded(player)
	TycoonService.claimPlot(player)
	player.CharacterAdded:Connect(function(character)
		TycoonService.onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(TycoonService.onCharacter, player, player.Character)
	end
	player:SetAttribute("TycoonReady", true)
end

-- Order matters on leave: free the plot first (it pays the collector's bank into the
-- profile), then save and unlock the profile.
local function onPlayerRemoving(player: Player)
	TycoonService.releasePlot(player)
	ShopService.playerRemoving(player)
	DataService.release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player) -- players who joined before this script ran
end

---------------------------------------------------------------------------------------
-- Client requests
--   who:        the request must come from a loaded player (TycoonService also checks
--               that the player owns the plot it acts on)
--   what:       only whitelisted names; arguments are type- and length-checked
--   how often:  one request per Config.RequestInterval per player, extras are dropped
--   can afford: TycoonService / ShopService check the price on the server
---------------------------------------------------------------------------------------

local lastRequest: { [Player]: number } = {}

local function shortString(value: any): boolean
	return typeof(value) == "string" and #value > 0 and #value <= 32
end

local handlers: { [string]: (Player, any) -> () } = {
	BuyDropper = function(player)
		TycoonService.buyDropper(player)
	end,
	Rebirth = function(player)
		TycoonService.rebirth(player)
	end,
	Collect = function(player)
		TycoonService.claimBank(player)
	end,
	PromptPass = function(player, key)
		if shortString(key) then
			ShopService.promptPass(player, key)
		end
	end,
	PromptProduct = function(player, key)
		if shortString(key) then
			ShopService.promptProduct(player, key)
		end
	end,
}

Action.OnServerEvent:Connect(function(player: Player, name: any, arg: any)
	if typeof(name) ~= "string" or not handlers[name] then
		return
	end
	if not DataService.get(player) then
		return -- profile not loaded yet
	end
	local now = os.clock()
	if (lastRequest[player] or 0) + Config.RequestInterval > now then
		return
	end
	lastRequest[player] = now
	handlers[name](player, arg)
end)

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
end)

print(string.format("[TycoonKit] Running. Save mode: %s.", DataService.getMode()))
