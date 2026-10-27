--!strict
-- TycoonService: droppers, conveyor, collector, upgrades and rebirth. Server-authoritative:
-- the client sends requests ("BuyDropper", "Rebirth"); every check and every change of
-- money happens here, and the result is replicated through player attributes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local FxEvent = Remotes:WaitForChild("Fx") :: RemoteEvent
local FxFast = Remotes:WaitForChild("FxFast") :: UnreliableRemoteEvent

local plot = workspace:WaitForChild("Plot")
local slots = plot:WaitForChild("DropperSlots")
local belt = plot:WaitForChild("Conveyor"):WaitForChild("Belt") :: BasePart
local collector = plot:WaitForChild("Collector")
local sensor = collector:WaitForChild("Sensor") :: BasePart
local collectPad = plot:WaitForChild("CollectPad") :: BasePart
local buyPad = plot:WaitForChild("BuyDropperPad") :: BasePart
local rebirthPad = plot:WaitForChild("RebirthPad") :: BasePart
local template = ServerStorage:WaitForChild("DropperTemplate") :: Model

local BELT_SPEED = 13

local TycoonService = {}

local owner: Player? = nil
local bank = 0 -- cash waiting in the collector
local busy = false -- a rebirth is playing
local droppers: { Model } = {}
local nextDrop: { number } = {}
local liveDrops: { [BasePart]: boolean } = {}
local liveCount = 0
local dropFolder = Instance.new("Folder")
dropFolder.Name = "Drops"
dropFolder.Parent = plot

-- Helpers ------------------------------------------------------------------

local function multiplier(player: Player): number
	local p = DataService.get(player)
	local m = Config.RebirthMultiplier(if p then p.Rebirths else 0)
	for key, effect in pairs(Config.PassEffects) do
		if effect.CashMultiplier and ShopService.owns(player, key) then
			m *= effect.CashMultiplier
		end
	end
	return m
end

local function dropInterval(player: Player): number
	local scale = 1
	for key, effect in pairs(Config.PassEffects) do
		if effect.DropIntervalScale and ShopService.owns(player, key) then
			scale *= effect.DropIntervalScale
		end
	end
	return Config.DropInterval * scale
end

-- Pushes the authoritative state to replicated attributes (display only).
local function publish(player: Player)
	local p = DataService.get(player)
	if not p then
		return
	end
	player:SetAttribute("Cash", p.Cash)
	player:SetAttribute("Bank", bank)
	player:SetAttribute("Rebirths", p.Rebirths)
	player:SetAttribute("Droppers", p.Droppers)
	player:SetAttribute("Multiplier", multiplier(player))
	player:SetAttribute("RebirthMultiplier", Config.RebirthMultiplier(p.Rebirths))
	player:SetAttribute("DropperCost", if p.Droppers < Config.MaxDroppers then Config.DropperCost(p.Droppers) else -1)
	player:SetAttribute("RebirthCost", Config.RebirthCost(p.Rebirths))

	local screen = collector:FindFirstChild("Screen")
	local label = screen and screen:FindFirstChild("Value", true)
	if label and label:IsA("TextLabel") then
		label.Text = if ShopService.owns(player, "AutoCollect") then "AUTO" else Format.cash(bank)
	end
	local collectLabel = collectPad:FindFirstChild("Cost", true)
	if collectLabel and collectLabel:IsA("TextLabel") then
		collectLabel.Text = if ShopService.owns(player, "AutoCollect") then "auto: on" else "step here"
	end
	local buyLabel = buyPad:FindFirstChild("Cost", true)
	if buyLabel and buyLabel:IsA("TextLabel") then
		buyLabel.Text = if p.Droppers < Config.MaxDroppers then Format.cash(Config.DropperCost(p.Droppers)) else "MAX"
	end
	local rebirthLabel = rebirthPad:FindFirstChild("Cost", true)
	if rebirthLabel and rebirthLabel:IsA("TextLabel") then
		rebirthLabel.Text = Format.cash(Config.RebirthCost(p.Rebirths))
	end
end

local function slotFor(i: number): BasePart
	return slots:FindFirstChild("Slot" .. i) :: BasePart
end

local function buildDroppers(count: number, announceIndex: number?)
	for i = #droppers + 1, count do
		local slot = slotFor(i)
		local m = template:Clone()
		m.Name = "Dropper" .. i
		m:PivotTo(slot.CFrame)
		m.Parent = plot
		droppers[i] = m
		nextDrop[i] = os.clock() + 0.6 + i * 0.13
		if announceIndex == i then
			FxEvent:FireAllClients("DropperBuilt", m)
		end
	end
	for i = #droppers, count + 1, -1 do
		droppers[i]:Destroy()
		droppers[i] = nil
		nextDrop[i] = nil
	end
end

local function clearDrops()
	for part in pairs(liveDrops) do
		part:Destroy()
	end
	table.clear(liveDrops)
	liveCount = 0
end

local function spawnDrop(dropper: Model, golden: boolean)
	if liveCount >= Config.MaxLiveDrops then
		return
	end
	local spout = dropper:FindFirstChild("Spout", true) :: Attachment
	local part = Instance.new("Part")
	part.Name = "Drop"
	part.Size = Vector3.new(1.15, 1.15, 1.15)
	part.Material = Enum.Material.SmoothPlastic
	part.Color = if golden then Color3.fromRGB(255, 200, 70) else Color3.fromRGB(70, 230, 170)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = CFrame.new(spout.WorldPosition) * CFrame.Angles(0, math.random() * math.pi, 0)
	part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.6, 0.1)
	part:SetAttribute("Golden", golden)
	part.Parent = dropFolder
	part:SetNetworkOwner(nil) -- the server simulates every drop
	liveDrops[part] = true
	liveCount += 1
	-- Safety: a drop that never reaches the collector is removed
	task.delay(20, function()
		if liveDrops[part] then
			liveDrops[part] = nil
			liveCount -= 1
			part:Destroy()
		end
	end)
end

local function credit(player: Player, amount: number)
	local p = DataService.get(player)
	if not p then
		return
	end
	if ShopService.owns(player, "AutoCollect") then
		p.Cash += amount
	else
		bank += amount
	end
	publish(player)
end

local function onSensorTouched(hit: BasePart)
	if not liveDrops[hit] or not owner then
		return
	end
	liveDrops[hit] = nil
	liveCount -= 1
	local value = math.floor(Config.DropValue * multiplier(owner) + 0.5)
	local pos = hit.Position
	local golden = hit:GetAttribute("Golden") == true
	hit:Destroy()
	credit(owner, value)
	FxFast:FireAllClients("Collect", value, pos, golden)
end

-- Public API (used by remotes and by AutoDemo_ForRecording) -----------------

function TycoonService.getOwner(): Player?
	return owner
end

function TycoonService.claimBank(player: Player): boolean
	local p = DataService.get(player)
	if player ~= owner or not p or bank <= 0 then
		return false
	end
	local amount = bank
	bank = 0
	p.Cash += amount
	publish(player)
	FxEvent:FireAllClients("BankClaimed", amount)
	return true
end

function TycoonService.buyDropper(player: Player): boolean
	local p = DataService.get(player)
	if player ~= owner or not p or busy then
		return false
	end
	if p.Droppers >= Config.MaxDroppers then
		return false
	end
	local cost = Config.DropperCost(p.Droppers)
	if p.Cash < cost then
		FxEvent:FireClient(player, "Denied", "Need " .. Format.cash(cost - p.Cash) .. " more")
		return false
	end
	p.Cash -= cost
	p.Droppers += 1
	buildDroppers(p.Droppers, p.Droppers)
	publish(player)
	FxEvent:FireClient(player, "Spent", cost)
	return true
end

function TycoonService.rebirth(player: Player): boolean
	local p = DataService.get(player)
	if player ~= owner or not p or busy then
		return false
	end
	local cost = Config.RebirthCost(p.Rebirths)
	if p.Cash < cost then
		FxEvent:FireClient(player, "Denied", "Rebirth needs " .. Format.cash(cost))
		return false
	end
	busy = true
	local from = Config.RebirthMultiplier(p.Rebirths)
	local to = Config.RebirthMultiplier(p.Rebirths + 1)
	FxEvent:FireAllClients("RebirthStart", from, to)
	task.wait(0.9) -- let the clients play the build-up; the reset lands on the flash
	if not player.Parent or DataService.get(player) ~= p or p.Cash < cost then
		busy = false
		return false
	end
	p.Rebirths += 1
	p.Cash = Config.StartCash
	p.Droppers = 1
	bank = 0
	clearDrops()
	buildDroppers(1)
	publish(player)
	FxEvent:FireAllClients("RebirthDone", p.Rebirths, to)
	busy = false
	return true
end

function TycoonService.refresh(player: Player)
	if player == owner then
		-- Auto Collect just turned on: pay out what is waiting in the collector
		local p = DataService.get(player)
		if p and bank > 0 and ShopService.owns(player, "AutoCollect") then
			local amount = bank
			bank = 0
			p.Cash += amount
			FxEvent:FireAllClients("BankClaimed", amount)
		end
		publish(player)
		local character = player.Character
		local head = character and character:FindFirstChild("Head")
		if head and ShopService.owns(player, "VIP") and not head:FindFirstChild("VipTag") then
			local tag = Instance.new("BillboardGui")
			tag.Name = "VipTag"
			tag.Size = UDim2.fromOffset(90, 30)
			tag.StudsOffset = Vector3.new(0, 2.4, 0)
			tag.AlwaysOnTop = true
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 1)
			t.BackgroundTransparency = 1
			t.Text = "VIP"
			t.TextScaled = true
			t.Font = Enum.Font.GothamBlack
			t.TextColor3 = Color3.fromRGB(255, 210, 90)
			t.Parent = tag
			tag.Parent = head
		end
	end
end

function TycoonService.claimPlot(player: Player)
	if owner then
		return -- this demo place has one plot
	end
	owner = player
	local p = DataService.get(player)
	buildDroppers(if p then p.Droppers else 1)
	publish(player)
end

function TycoonService.releasePlot(player: Player)
	if owner ~= player then
		return
	end
	owner = nil
	bank = 0
	clearDrops()
	buildDroppers(0)
end

function TycoonService.start()
	belt.AssemblyLinearVelocity = Vector3.new(BELT_SPEED, 0, 0)
	sensor.Touched:Connect(onSensorTouched)

	local padDebounce: { [Player]: number } = {}
	local function padHandler(fn: (Player) -> boolean)
		return function(hit: BasePart)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			local now = os.clock()
			if (padDebounce[player] or 0) > now then
				return
			end
			padDebounce[player] = now + 0.8
			fn(player)
		end
	end
	collectPad.Touched:Connect(padHandler(TycoonService.claimBank))
	buyPad.Touched:Connect(padHandler(TycoonService.buyDropper))
	rebirthPad.Touched:Connect(padHandler(TycoonService.rebirth))

	-- One scheduler for all droppers
	RunService.Heartbeat:Connect(function()
		local player = owner
		if not player or busy then
			return
		end
		local now = os.clock()
		local interval = dropInterval(player)
		local golden = ShopService.owns(player, "DoubleCash")
		for i, dropper in ipairs(droppers) do
			if now >= nextDrop[i] then
				nextDrop[i] = now + interval
				spawnDrop(dropper, golden)
			end
		end
	end)
end

return TycoonService
