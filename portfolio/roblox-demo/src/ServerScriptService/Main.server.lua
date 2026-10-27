--!strict
-- Main: boots the services and validates every client request.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = script.Parent:WaitForChild("Services")
local DataService = require(Services.DataService)
local ShopService = require(Services.ShopService)
local TycoonService = require(Services.TycoonService)

local Action = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Action") :: RemoteEvent

DataService.start()
ShopService.start(function(player)
	TycoonService.refresh(player)
end)
TycoonService.start()

local function onPlayerAdded(player: Player)
	local profile = DataService.load(player)
	if not profile or not player.Parent then
		return
	end
	ShopService.playerAdded(player)
	TycoonService.claimPlot(player)
	local function onCharacter(character: Model)
		-- Plain outfit (the place does not load avatars: StarterPlayer.LoadCharacterAppearance = false)
		local colors = character:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors")
		local skin, shirt, pants = Color3.fromRGB(234, 184, 146), Color3.fromRGB(40, 170, 140), Color3.fromRGB(44, 48, 62)
		colors.HeadColor3, colors.LeftArmColor3, colors.RightArmColor3 = skin, skin, skin
		colors.TorsoColor3, colors.LeftLegColor3, colors.RightLegColor3 = shirt, pants, pants
		colors.Parent = character
		task.wait(0.5)
		TycoonService.refresh(player)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	player:SetAttribute("Ready", true)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerRemoving:Connect(TycoonService.releasePlot)

-- Client requests: names are whitelisted, arguments type-checked, rate limited.
local lastRequest: { [Player]: number } = {}
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
		if typeof(key) == "string" and #key < 32 then
			ShopService.promptPass(player, key)
		end
	end,
}

Action.OnServerEvent:Connect(function(player, name, arg)
	if typeof(name) ~= "string" or not handlers[name] then
		return
	end
	local now = os.clock()
	if (lastRequest[player] or 0) + 0.2 > now then
		return
	end
	lastRequest[player] = now
	handlers[name](player, arg)
end)

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
end)
