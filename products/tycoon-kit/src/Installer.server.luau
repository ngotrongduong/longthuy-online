-- Installer: sets the Tycoon Systems Kit up when the game starts.
--
-- Leave the TycoonSystemsKit model in Workspace and press Play. On the server this
-- script moves every part of the kit to the place where Roblox runs it:
--
--   TycoonSystemsKit.Shared  ->  ReplicatedStorage.TycoonKit            (Config, Format, Remotes)
--   TycoonSystemsKit.Server  ->  ServerScriptService.TycoonKit          (Main + services; Main is enabled)
--   TycoonSystemsKit.Client  ->  StarterPlayer.StarterPlayerScripts.TycoonKit  (Hud, Effects)
--   every plot (tag "TycoonPlot") inside the kit  ->  Workspace.TycoonPlots
--
-- Then the empty kit model is removed. Nothing is changed in your saved place: the move
-- happens again, the same way, every time a server starts.
--
-- Prefer a permanent install? In Studio (not playing) drag the folders to the places
-- above yourself, rename each to "TycoonKit", set ServerScriptService.TycoonKit.Main
-- Enabled = true, move the Plot to Workspace and delete this model. See README.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")

local kit = script.Parent
local playerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

if ReplicatedStorage:FindFirstChild("TycoonKit") or ServerScriptService:FindFirstChild("TycoonKit") then
	warn("[TycoonKit] The kit is already installed in this place; the TycoonSystemsKit model was ignored. Delete one of the two copies.")
	return
end

local function move(name: string, destination: Instance): Instance?
	local folder = kit:FindFirstChild(name)
	if not folder then
		warn("[TycoonKit] Installer: '" .. name .. "' is missing from the TycoonSystemsKit model.")
		return nil
	end
	folder.Name = "TycoonKit"
	folder.Parent = destination
	return folder
end

-- 1. Shared code and remotes first: everything else waits for them.
move("Shared", ReplicatedStorage)

-- 2. Plots: out of the kit, into one folder, at the same world position.
local plotFolder = workspace:FindFirstChild("TycoonPlots") or Instance.new("Folder")
plotFolder.Name = "TycoonPlots"
plotFolder.Parent = workspace
for _, plot in ipairs(CollectionService:GetTagged("TycoonPlot")) do
	if plot:IsDescendantOf(kit) then
		plot.Parent = plotFolder
	end
end

-- 3. Client scripts. Players who are already in the server (possible in Studio) got
--    their StarterPlayerScripts before this ran, so they get a copy in PlayerGui. The
--    scripts themselves make sure only one copy runs per player.
local client = move("Client", playerScripts)
if client then
	for _, player in ipairs(Players:GetPlayers()) do
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			local holder = Instance.new("ScreenGui")
			holder.Name = "TycoonKitLateJoin"
			holder.ResetOnSpawn = false
			for _, child in ipairs(client:GetChildren()) do
				child:Clone().Parent = holder
			end
			holder.Parent = playerGui
		end
	end
end

-- 4. Server code last, then start it.
local server = move("Server", ServerScriptService)
local main = server and server:FindFirstChild("Main")
if main and main:IsA("Script") then
	main.Enabled = true
else
	warn("[TycoonKit] Installer: ServerScriptService.TycoonKit.Main not found; the kit is not running.")
end

-- 5. The README and this Installer are not needed at run time.
kit:Destroy()
