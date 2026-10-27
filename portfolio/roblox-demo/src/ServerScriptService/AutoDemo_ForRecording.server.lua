-- AutoDemo_ForRecording
-- Plays the ~34 s showcase used for the portfolio video. NOT part of the game.
--
--   To turn it off: set ENABLED = false below, or disable / delete this Script.
--   Nothing else in the place depends on it.
--
-- What it does differently from real play (all listed here, nothing hidden):
--   * DEMO SEED: the first player starts with 2 droppers and some cash so the clip is short.
--   * Game passes cannot be bought in Studio, so it calls ShopService.grantForDemo(),
--     which uses the same server path as PromptGamePassPurchaseFinished.
--   * Buttons are pressed by telling the client to run the HUD's own button handler,
--     so the server receives the normal "BuyDropper" / "Rebirth" requests and checks them.
--   * The character walks onto the real Collect pad.
--
-- Start: when AUTO_START is false it waits for ReplicatedStorage attribute DemoGo = true
-- (set from the command bar), which lets the recording start exactly on cue.

local ENABLED = false -- set to true to play the recording showcase
local AUTO_START = false

if not ENABLED then
	return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = game:GetService("ServerScriptService"):WaitForChild("Services")
local DataService = require(Services.DataService)
local ShopService = require(Services.ShopService)
local TycoonService = require(Services.TycoonService)
local Config = require(ReplicatedStorage.Shared.Config)
local Demo = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Demo") :: RemoteEvent

local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
while not player:GetAttribute("Ready") do
	task.wait(0.1)
end
local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")
task.wait(1)

-- DEMO SEED (see header)
local profile = DataService.get(player)
if profile then
	profile.Cash = 520
	profile.Droppers = 2
	-- re-claim the plot so it is rebuilt for the seeded dropper count, like a fresh load
	TycoonService.releasePlot(player)
	TycoonService.claimPlot(player)
end

ReplicatedStorage:SetAttribute("DemoActive", true)
Demo:FireClient(player, "Activate")
Demo:FireClient(player, "Shot", "Establish", 0.01)

if not AUTO_START then
	while not ReplicatedStorage:GetAttribute("DemoGo") do
		task.wait(0.05)
	end
end

local t0 = os.clock()
local function at(t: number)
	local dt = t0 + t - os.clock()
	if dt > 0 then
		task.wait(dt)
	end
end
local function send(...)
	Demo:FireClient(player, ...)
end

-- 0 s: establishing shot, walk to the collect pad
send("Shot", "Establish", 4.8)
send("Caption", "Tycoon Systems Demo", "Droppers, conveyor and collector, simulated on the server", "Teal")
at(1.2)
send("Walk", workspace.Plot.CollectPad.Position + Vector3.new(0, 2, 0))
at(3.9)
send("Walk", Vector3.new(11, 3, 19)) -- step off the pad, out of the later shots

-- 4.6 s: upgrades
at(4.6)
send("Shot", "Droppers", 4.6)
send("Caption", "Upgrades: buy droppers", "Cost checked and charged on the server, never on the client", "Teal")
at(5.4)
send("Hud", "Press", "BuyDropper")
at(7.2)
send("Hud", "Press", "BuyDropper")

-- 9.2 s: shop
at(9.2)
send("Shot", "ShopView", 5.8)
send("Caption", "Server-side Robux shop", "Passes verified with MarketplaceService, receipts granted once", "Gold")
at(9.5)
send("Hud", "Press", "Shop")
at(10.9)
send("Hud", "HoverPass", "DoubleCash")
at(11.4)
ShopService.grantForDemo(player, "DoubleCash")
at(12.6)
send("Hud", "HoverPass", "AutoCollect")
at(13.1)
ShopService.grantForDemo(player, "AutoCollect")
at(14.7)
send("Hud", "Press", "CloseShop")

-- 15 s: pass effects on the belt
at(15.0)
send("Shot", "Belt", 3.8)
send("Caption", "Pass effects applied on the server", "2x Cash doubles every drop, Auto Collect pays straight to the wallet", "Gold")

-- 18.8 s: rebirth
at(18.8)
send("Shot", "RebirthWide", 5)
send("Caption", "Rebirth: permanent multiplier", "Plot resets, the multiplier stays and is saved in the profile", "Purple")
at(19.4)
local deadline = os.clock() + 3
while os.clock() < deadline do
	local p = DataService.get(player)
	if p and p.Cash >= Config.RebirthCost(p.Rebirths) then
		break
	end
	task.wait(0.05)
end
send("Hud", "Press", "Rebirth")

-- 24 s: data
at(24.0)
send("Shot", "DataShot", 4.6)
send("Caption", "DataStore saving with session lock", "UpdateAsync lock, retries with backoff, autosave, BindToClose", "Teal")
send("DataCard", true)

-- 28.6 s: devices
at(28.6)
send("DataCard", false)
send("Shot", "FinalSweep", 4.4)
send("Caption", "Works on mobile and PC", "One scaled layout, touch-sized buttons, safe-area aware", "Teal")
at(28.9)
send("DeviceCard", true)
at(29.6)
send("Hud", "PulseActions")

-- 32 s: end card
at(32.0)
send("DeviceCard", false)
send("Caption", nil)
send("EndCard")
at(35.0)
ReplicatedStorage:SetAttribute("DemoFinished", true)
