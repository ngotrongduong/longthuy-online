--!strict
-- TycoonService: plots, droppers, conveyor, collector, dropper upgrade and rebirth.
-- Installed at: ServerScriptService.TycoonKit.TycoonService
--
-- Server-authoritative: clients send REQUESTS ("BuyDropper", "Rebirth", "Collect") or
-- step on floor pads; every check and every change of money happens here. The results
-- are replicated through player attributes (Cash, Bank, Rebirths, ...) that the HUD
-- only displays.
--
-- Plots: every Model in Workspace with the CollectionService tag "TycoonPlot" is a plot.
-- Duplicate the example Plot (it keeps its tag) to have one plot per player in a server.
-- A player gets the first free plot when they join and loses it when they leave.
--
-- A plot needs these children (names matter, positions are free):
--   Conveyor.Belt         anchored part; drops ride on it toward the collector
--   Collector.Sensor      non-colliding part; a drop touching it is sold
--   Collector.Screen      optional; SurfaceGui with a TextLabel "Value" shows the bank
--   CollectPad, BuyDropperPad, RebirthPad   floor pads (BillboardGui label "Cost" optional)
--   DropperSlots.Slot1..SlotN  where droppers are built (N = max droppers on this plot)
--   Spawn                 optional; the owner is placed here when they spawn
--   Sign                  optional; SurfaceGui with TextLabels "Title" and "Subtitle"

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("TycoonKit")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)

local Remotes = Shared:WaitForChild("Remotes")
local Fx = Remotes:WaitForChild("Fx") :: RemoteEvent
local FxFast = Remotes:WaitForChild("FxFast") :: UnreliableRemoteEvent

local template = script.Parent:WaitForChild("Assets"):WaitForChild("DropperTemplate") :: Model

local PLOT_TAG = "TycoonPlot"
local GOLDEN_TAG = "TycoonGoldenDrop" -- clients add a sparkle to drops with this tag

type PlotState = {
	model: Model,
	owner: Player?,
	bank: number, -- cash waiting in the collector
	busy: boolean, -- a rebirth is playing
	droppers: { Model },
	nextDrop: { number },
	live: { [BasePart]: boolean },
	liveCount: number,
	dropFolder: Folder,
	belt: BasePart,
	sensor: BasePart,
	collectPad: BasePart,
	buyPad: BasePart,
	rebirthPad: BasePart,
	slots: { BasePart },
	maxDroppers: number,
}

local TycoonService = {}

local plots: { PlotState } = {}
local plotOf: { [Player]: PlotState } = {}

---------------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------------

local function multiplier(player: Player): number
	local p = DataService.get(player)
	local m = Config.RebirthMultiplier(if p then p.Rebirths else 0)
	return m * (ShopService.effect(player, "CashMultiplier") or 1)
end

local function dropInterval(player: Player): number
	return Config.DropInterval * (ShopService.effect(player, "DropIntervalScale") or 1)
end

local function autoCollect(player: Player): boolean
	return ShopService.effect(player, "AutoCollect") == true
end

local function setLabel(root: Instance?, name: string, text: string)
	local label = root and root:FindFirstChild(name, true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

-- Pushes the authoritative state to replicated attributes and plot labels (display only).
local function publish(plot: PlotState)
	local player = plot.owner
	local p = player and DataService.get(player)
	if not player or not p then
		return
	end
	local canBuy = p.Droppers < plot.maxDroppers
	player:SetAttribute("Cash", p.Cash)
	player:SetAttribute("Bank", plot.bank)
	player:SetAttribute("Rebirths", p.Rebirths)
	player:SetAttribute("Droppers", p.Droppers)
	player:SetAttribute("Multiplier", multiplier(player))
	player:SetAttribute("RebirthMultiplier", Config.RebirthMultiplier(p.Rebirths))
	player:SetAttribute("DropperCost", if canBuy then Config.DropperCost(p.Droppers) else -1)
	player:SetAttribute("RebirthCost", Config.RebirthCost(p.Rebirths))

	local auto = autoCollect(player)
	setLabel(plot.model:FindFirstChild("Collector"), "Value", if auto then "AUTO" else Format.cash(plot.bank))
	setLabel(plot.collectPad, "Cost", if auto then "auto: on" else "step here")
	setLabel(plot.buyPad, "Cost", if canBuy then Format.cash(Config.DropperCost(p.Droppers)) else "MAX")
	setLabel(plot.rebirthPad, "Cost", Format.cash(Config.RebirthCost(p.Rebirths)))
end

local function setSign(plot: PlotState)
	local sign = plot.model:FindFirstChild("Sign")
	local owner = plot.owner
	if owner then
		setLabel(sign, "Title", string.upper(owner.DisplayName) .. "'S TYCOON")
		local p = DataService.get(owner)
		setLabel(sign, "Subtitle", "REBIRTHS: " .. tostring(if p then p.Rebirths else 0))
	else
		setLabel(sign, "Title", "FREE PLOT")
		setLabel(sign, "Subtitle", "WAITING FOR AN OWNER")
		setLabel(plot.model:FindFirstChild("Collector"), "Value", "$0")
		setLabel(plot.collectPad, "Cost", "")
		setLabel(plot.buyPad, "Cost", "")
		setLabel(plot.rebirthPad, "Cost", "")
	end
end

local function buildDroppers(plot: PlotState, count: number, announceIndex: number?)
	count = math.clamp(count, 0, plot.maxDroppers)
	for i = #plot.droppers + 1, count do
		local m = template:Clone()
		m.Name = "Dropper" .. i
		m:PivotTo(plot.slots[i].CFrame)
		m.Parent = plot.model
		plot.droppers[i] = m
		plot.nextDrop[i] = os.clock() + 0.6 + i * 0.13
		if announceIndex == i then
			Fx:FireAllClients("DropperBuilt", plot.model, m)
		end
	end
	for i = #plot.droppers, count + 1, -1 do
		plot.droppers[i]:Destroy()
		plot.droppers[i] = nil
		plot.nextDrop[i] = nil
	end
end

local function clearDrops(plot: PlotState)
	for part in pairs(plot.live) do
		part:Destroy()
	end
	table.clear(plot.live)
	plot.liveCount = 0
end

local function spawnDrop(plot: PlotState, dropper: Model, golden: boolean)
	if plot.liveCount >= Config.MaxLiveDrops then
		return
	end
	local spout = dropper:FindFirstChild("Spout", true)
	if not (spout and spout:IsA("Attachment")) then
		return
	end
	local part = Instance.new("Part")
	part.Name = "Drop"
	part.Size = Vector3.new(1.15, 1.15, 1.15)
	part.Material = Enum.Material.SmoothPlastic
	part.Color = if golden then Color3.fromRGB(255, 200, 70) else Color3.fromRGB(70, 230, 170)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = CFrame.new(spout.WorldPosition) * CFrame.Angles(0, math.random() * math.pi, 0)
	part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.6, 0.1)
	if golden then
		part:AddTag(GOLDEN_TAG)
	end
	part.Parent = plot.dropFolder
	part:SetNetworkOwner(nil) -- the server simulates every drop (no client can move them)
	plot.live[part] = true
	plot.liveCount += 1
	task.delay(Config.DropLifetime, function()
		if plot.live[part] then -- never reached the collector
			plot.live[part] = nil
			plot.liveCount -= 1
			part:Destroy()
		end
	end)
end

local function credit(plot: PlotState, player: Player, amount: number)
	local p = DataService.get(player)
	if not p then
		return
	end
	if autoCollect(player) then
		p.Cash += amount
	else
		plot.bank += amount
	end
	publish(plot)
end

local function onSensorTouched(plot: PlotState, hit: BasePart)
	local owner = plot.owner
	if not plot.live[hit] or not owner then
		return
	end
	plot.live[hit] = nil
	plot.liveCount -= 1
	local value = math.floor(Config.DropValue * multiplier(owner) + 0.5)
	local pos = hit.Position
	local golden = hit:HasTag(GOLDEN_TAG)
	hit:Destroy()
	credit(plot, owner, value)
	FxFast:FireAllClients("Collect", plot.model, value, pos, golden)
end

local function updateNameTag(player: Player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local text = ShopService.effect(player, "NameTag")
	local tag = head:FindFirstChild("TycoonKitTag")
	if type(text) ~= "string" then
		if tag then
			tag:Destroy()
		end
		return
	end
	if tag then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "TycoonKitTag"
	gui.Size = UDim2.fromOffset(90, 30)
	gui.StudsOffset = Vector3.new(0, 2.4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(255, 210, 90)
	label.TextStrokeTransparency = 0.4
	label.Parent = gui
	gui.Parent = head
end

---------------------------------------------------------------------------------------
-- Public API (called by Main from remotes, pads and player events)
---------------------------------------------------------------------------------------

function TycoonService.getPlot(player: Player): Model?
	local plot = plotOf[player]
	return plot and plot.model
end

-- Moves the collector's bank into the wallet.
function TycoonService.claimBank(player: Player): boolean
	local plot = plotOf[player]
	local p = DataService.get(player)
	if not plot or not p or plot.bank <= 0 then
		return false
	end
	local amount = plot.bank
	plot.bank = 0
	p.Cash += amount
	publish(plot)
	Fx:FireAllClients("BankClaimed", plot.model, amount)
	return true
end

function TycoonService.buyDropper(player: Player): boolean
	local plot = plotOf[player]
	local p = DataService.get(player)
	if not plot or not p or plot.busy then
		return false
	end
	if p.Droppers >= plot.maxDroppers then
		Fx:FireClient(player, "Denied", "All dropper slots are full")
		return false
	end
	local cost = Config.DropperCost(p.Droppers)
	if p.Cash < cost then
		Fx:FireClient(player, "Denied", "Need " .. Format.cash(cost - p.Cash) .. " more")
		return false
	end
	p.Cash -= cost
	p.Droppers += 1
	buildDroppers(plot, p.Droppers, p.Droppers)
	publish(plot)
	return true
end

function TycoonService.rebirth(player: Player): boolean
	local plot = plotOf[player]
	local p = DataService.get(player)
	if not plot or not p or plot.busy then
		return false
	end
	local cost = Config.RebirthCost(p.Rebirths)
	if p.Cash < cost then
		Fx:FireClient(player, "Denied", "Rebirth needs " .. Format.cash(cost))
		return false
	end
	plot.busy = true
	local from = Config.RebirthMultiplier(p.Rebirths)
	local to = Config.RebirthMultiplier(p.Rebirths + 1)
	Fx:FireAllClients("RebirthStart", plot.model, from, to)
	task.wait(0.9) -- the clients play the build-up; the reset lands on the flash
	-- Re-check everything after the wait: the player may have left or spent the cash.
	if plotOf[player] ~= plot or DataService.get(player) ~= p or p.Cash < cost then
		plot.busy = false
		return false
	end
	p.Rebirths += 1
	p.Cash = Config.StartCash
	p.Droppers = 1
	plot.bank = 0
	clearDrops(plot)
	buildDroppers(plot, 1)
	publish(plot)
	setSign(plot)
	Fx:FireAllClients("RebirthDone", plot.model, p.Rebirths, to)
	plot.busy = false
	return true
end

-- Called when passes change: re-applies effects and refreshes the display.
function TycoonService.refresh(player: Player)
	local plot = plotOf[player]
	if not plot then
		return
	end
	-- Auto Collect just turned on: pay out what is waiting in the collector.
	if plot.bank > 0 and autoCollect(player) then
		TycoonService.claimBank(player)
	end
	publish(plot)
	updateNameTag(player)
end

-- Gives the player the first free plot. Returns false when every plot is taken.
function TycoonService.claimPlot(player: Player): boolean
	if plotOf[player] then
		return true
	end
	for _, plot in ipairs(plots) do
		if not plot.owner then
			plot.owner = player
			plotOf[player] = plot
			plot.model:SetAttribute("OwnerUserId", player.UserId)
			local p = DataService.get(player)
			buildDroppers(plot, if p then p.Droppers else 1)
			publish(plot)
			setSign(plot)
			player:SetAttribute("HasPlot", true)
			return true
		end
	end
	player:SetAttribute("HasPlot", false)
	warn("[TycoonKit] No free plot for " .. player.Name .. ". Add more plots (duplicate the Plot model).")
	return false
end

-- Frees the player's plot. The cash waiting in the collector goes to the wallet first,
-- so it is included in the final save.
function TycoonService.releasePlot(player: Player)
	local plot = plotOf[player]
	if not plot then
		return
	end
	local p = DataService.get(player)
	if p and plot.bank > 0 then
		p.Cash += plot.bank
	end
	plotOf[player] = nil
	plot.owner = nil
	plot.bank = 0
	plot.busy = false
	plot.model:SetAttribute("OwnerUserId", 0)
	clearDrops(plot)
	buildDroppers(plot, 0)
	setSign(plot)
end

-- Character spawned: place it on the plot and re-apply the name tag.
function TycoonService.onCharacter(player: Player, character: Model)
	local plot = plotOf[player]
	if plot and Config.TeleportToPlotOnSpawn then
		local spawn = plot.model:FindFirstChild("Spawn")
		if spawn and spawn:IsA("BasePart") then
			character:WaitForChild("HumanoidRootPart", 5)
			task.wait() -- let the default spawn finish first
			if character.Parent then
				character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
			end
		end
	end
	updateNameTag(player)
end

---------------------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------------------

local function need(parent: Instance, path: { string }): Instance
	local node = parent
	for _, name in ipairs(path) do
		local child = node:FindFirstChild(name)
		if not child then
			error(string.format("[TycoonKit] Plot '%s' is missing %s", parent:GetFullName(), table.concat(path, ".")))
		end
		node = child
	end
	return node
end

local function setupPlot(model: Model, padTouched: (PlotState, string, BasePart) -> ()): PlotState?
	local ok, result = pcall(function()
		local slots: { BasePart } = {}
		local slotFolder = need(model, { "DropperSlots" })
		local i = 1
		while slotFolder:FindFirstChild("Slot" .. i) do
			table.insert(slots, slotFolder:FindFirstChild("Slot" .. i) :: BasePart)
			i += 1
		end
		if #slots == 0 then
			error("[TycoonKit] Plot '" .. model:GetFullName() .. "' has no DropperSlots.Slot1")
		end
		local old = model:FindFirstChild("Drops")
		if old then
			old:Destroy()
		end
		local dropFolder = Instance.new("Folder")
		dropFolder.Name = "Drops"
		dropFolder.Parent = model
		local state: PlotState = {
			model = model,
			owner = nil,
			bank = 0,
			busy = false,
			droppers = {},
			nextDrop = {},
			live = {},
			liveCount = 0,
			dropFolder = dropFolder,
			belt = need(model, { "Conveyor", "Belt" }) :: BasePart,
			sensor = need(model, { "Collector", "Sensor" }) :: BasePart,
			collectPad = need(model, { "CollectPad" }) :: BasePart,
			buyPad = need(model, { "BuyDropperPad" }) :: BasePart,
			rebirthPad = need(model, { "RebirthPad" }) :: BasePart,
			slots = slots,
			maxDroppers = math.min(Config.MaxDroppers, #slots),
		}
		return state
	end)
	if not ok then
		warn(tostring(result))
		return nil
	end
	local plot = result :: PlotState

	-- Belt pushes along its own X axis, toward the collector (works for rotated plots).
	local dir = plot.belt.CFrame.RightVector
	if dir:Dot(plot.sensor.Position - plot.belt.Position) < 0 then
		dir = -dir
	end
	plot.belt.AssemblyLinearVelocity = dir * Config.ConveyorSpeed

	plot.sensor.CanTouch = true
	plot.sensor.Touched:Connect(function(hit)
		onSensorTouched(plot, hit)
	end)
	for _, pair in ipairs({ { plot.collectPad, "Collect" }, { plot.buyPad, "BuyDropper" }, { plot.rebirthPad, "Rebirth" } }) do
		local pad, action = pair[1] :: BasePart, pair[2] :: string
		pad.Touched:Connect(function(hit)
			padTouched(plot, action, hit)
		end)
	end
	model:SetAttribute("OwnerUserId", 0)
	setSign(plot)
	return plot
end

function TycoonService.start()
	-- Floor pads: only the plot's owner can use them, with a short per-player cooldown.
	local padCooldown: { [Player]: number } = {}
	local function padTouched(plot: PlotState, action: string, hit: BasePart)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or player ~= plot.owner then
			return
		end
		local now = os.clock()
		if (padCooldown[player] or 0) > now then
			return
		end
		padCooldown[player] = now + Config.PadCooldown
		if action == "Collect" then
			TycoonService.claimBank(player)
		elseif action == "BuyDropper" then
			TycoonService.buyDropper(player)
		elseif action == "Rebirth" then
			TycoonService.rebirth(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		padCooldown[player] = nil
	end)

	for _, model in ipairs(CollectionService:GetTagged(PLOT_TAG)) do
		if model:IsA("Model") and model:IsDescendantOf(workspace) then
			local plot = setupPlot(model, padTouched)
			if plot then
				table.insert(plots, plot)
			end
		end
	end
	-- Stable order: plots sorted by name, so "first free plot" is predictable.
	table.sort(plots, function(a, b)
		return a.model:GetFullName() < b.model:GetFullName()
	end)
	if #plots == 0 then
		warn("[TycoonKit] No plot found. Keep the Plot model (tag 'TycoonPlot') in Workspace.")
	end

	-- One scheduler for every dropper of every plot.
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for _, plot in ipairs(plots) do
			local player = plot.owner
			if player and not plot.busy then
				local interval = dropInterval(player)
				local golden = ShopService.effect(player, "GoldenDrops") == true
				for i, dropper in ipairs(plot.droppers) do
					if now >= plot.nextDrop[i] then
						plot.nextDrop[i] = now + interval
						spawnDrop(plot, dropper, golden)
					end
				end
			end
		end
	end)
end

return TycoonService
