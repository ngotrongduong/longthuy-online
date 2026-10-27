--[[
	Builds the Tycoon Systems Kit files with Lune (https://lune-org.github.io).

	  lune run build/build.luau      (run from products/tycoon-kit)

	Inputs
	  src/**                                   the kit's scripts as text
	  ../../portfolio/roblox-demo/TycoonSystemsDemo.rbxlx   the demo place (plot, dropper, decor)
	Outputs
	  TycoonSystemsKit.rbxm     the model a buyer inserts (Creator Store upload)
	  TycoonKitDev.rbxlx        the demo scene with the kit in Workspace (dev + screenshots)
	  KitInsertTest.rbxlx       an empty baseplate with only the kit inserted (insert test)
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3

-- Project folder: first argument, or the folder this is run from.
local root = (process.args[1] or process.cwd):gsub("\\", "/")
if root:sub(-1) ~= "/" then
	root ..= "/"
end
if not fs.isFile(root .. "src/Installer.server.luau") then
	root ..= "products/tycoon-kit/"
end
local function path(rel: string): string
	return root .. rel
end

local function readSource(rel: string): string
	return fs.readFile(path("src/" .. rel))
end

local function script(class: string, name: string, rel: string, parent: any, enabled: boolean?)
	local s = Instance.new(class)
	s.Name = name
	s.Source = readSource(rel)
	if enabled == false then
		s.Disabled = true -- the saved property ("Enabled" is not written to files)
	end
	s.Parent = parent
	return s
end

local function folder(name: string, parent: any)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- Demo place: source of the plot geometry, the dropper model and the dev scene --------
local demo = roblox.deserializePlace(fs.readFile(path("../../portfolio/roblox-demo/TycoonSystemsDemo.rbxlx")))
local demoWorkspace = demo:GetService("Workspace")

local function buildKit()
	local kit = Instance.new("Model")
	kit.Name = "TycoonSystemsKit"

	script("ModuleScript", "README", "README.luau", kit)
	script("Script", "Installer", "Installer.server.luau", kit)

	local shared = folder("Shared", kit)
	script("ModuleScript", "Config", "Shared/Config.luau", shared)
	script("ModuleScript", "Format", "Shared/Format.luau", shared)
	local remotes = folder("Remotes", shared)
	local action = Instance.new("RemoteEvent")
	action.Name = "Action"
	action.Parent = remotes
	local fx = Instance.new("RemoteEvent")
	fx.Name = "Fx"
	fx.Parent = remotes
	local fxFast = Instance.new("UnreliableRemoteEvent")
	fxFast.Name = "FxFast"
	fxFast.Parent = remotes

	local server = folder("Server", kit)
	script("Script", "Main", "Server/Main.server.luau", server, false) -- enabled by the Installer
	script("ModuleScript", "DataService", "Server/DataService.luau", server)
	script("ModuleScript", "ShopService", "Server/ShopService.luau", server)
	script("ModuleScript", "TycoonService", "Server/TycoonService.luau", server)
	local assets = folder("Assets", server)
	local dropper = demo:GetService("ServerStorage"):FindFirstChild("DropperTemplate"):Clone()
	-- The pivot is where a slot puts the dropper: centre of the footing's bottom face.
	-- Lune cannot read or write a model's WorldPivot, so the pivot is set through the
	-- PrimaryPart: Footing (centre 0, 1.3, -6.5) with an offset to (0, 1, 0).
	local footing = dropper:FindFirstChild("Footing")
	dropper.PrimaryPart = footing
	footing.PivotOffset = CFrame.new(0, -0.3, 6.5)
	dropper.Parent = assets

	local client = folder("Client", kit)
	script("LocalScript", "Hud", "Client/Hud.client.luau", client)
	script("LocalScript", "Effects", "Client/Effects.client.luau", client)

	-- Example plot, from the demo, with the kit's names and a spawn point.
	local plot = demoWorkspace:FindFirstChild("Plot"):Clone()
	plot:AddTag("TycoonPlot")
	local sign = plot:FindFirstChild("Sign")
	local surface = sign and sign:FindFirstChildOfClass("SurfaceGui")
	if surface then
		for _, label in surface:GetChildren() do
			if label.ClassName == "TextLabel" then
				if label.Position.Y.Scale < 0.5 then
					label.Name = "Title"
					label.Text = "FREE PLOT"
				else
					label.Name = "Subtitle"
					label.Text = "WAITING FOR AN OWNER"
				end
			end
		end
	end
	local spawn = Instance.new("Part")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.CanTouch = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(4, 1, 4)
	spawn.CFrame = CFrame.new(0, 1.6, 19)
	spawn.Parent = plot
	plot.Parent = kit

	-- The plot's pivot is its Floor (so "Move" and "Pivot To" act on the floor).
	plot.PrimaryPart = plot:FindFirstChild("Floor")
	return kit
end

-- Report any content id that is not a built-in rbxasset:// (the kit must not need uploads).
local function scanContent(inst: any)
	local found = {}
	local props = {
		ParticleEmitter = { "Texture" },
		Decal = { "Texture" },
		Texture = { "Texture" },
		MeshPart = { "MeshId", "TextureID" },
		ImageLabel = { "Image" },
		ImageButton = { "Image" },
		Sound = { "SoundId" },
		Sky = { "SkyboxBk" },
	}
	for _, d in { inst, table.unpack(inst:GetDescendants()) } do
		local list = props[d.ClassName]
		if list then
			for _, p in list do
				local ok, v = pcall(function()
					return tostring(d[p])
				end)
				if ok and v ~= "" and not v:find("^rbxasset://") then
					table.insert(found, d:GetFullName() .. "." .. p .. " = " .. v)
				end
			end
		end
	end
	return found
end

-- 1. The model --------------------------------------------------------------------
local kit = buildKit()
local devKit = buildKit() -- copies for the two places, made before the demo is trimmed
local testKit = buildKit()
local content = scanContent(kit)
if #content > 0 then
	print("Content ids that are not built in:")
	for _, line in content do
		print("  " .. line)
	end
end
fs.writeFile(path("TycoonSystemsKit.rbxm"), roblox.serializeModel({ kit }))
print("wrote TycoonSystemsKit.rbxm")

-- 2. Dev place: the demo scene, its old scripts removed, the kit in Workspace --------
local function clearChildren(parent: any, names: { string })
	for _, name in names do
		local child = parent:FindFirstChild(name)
		while child do
			child:Destroy()
			child = parent:FindFirstChild(name)
		end
	end
end
clearChildren(demo:GetService("ServerScriptService"), { "Main", "Services", "AutoDemo_ForRecording" })
clearChildren(demo:GetService("ReplicatedStorage"), { "Shared", "Remotes" })
clearChildren(demo:GetService("ServerStorage"), { "DropperTemplate" })
clearChildren(demo:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"), { "HudController", "FxController", "DemoDirector" })
clearChildren(demoWorkspace, { "Plot" })
local spawnLocation = demoWorkspace:FindFirstChild("SpawnLocation")
if spawnLocation then
	spawnLocation.CFrame = CFrame.new(0, 1.1, 34) -- just outside the plot
end
devKit.Parent = demoWorkspace
fs.writeFile(path("TycoonKitDev.rbxlx"), roblox.serializePlace(demo, true))
print("wrote TycoonKitDev.rbxlx")

-- 3. Insert test: an empty baseplate with only the kit ----------------------------------
local game = Instance.new("DataModel")
local ws = game:GetService("Workspace")
ws.StreamingEnabled = true -- the default of a new place made in Studio
game:GetService("Lighting")
game:GetService("ReplicatedStorage")
game:GetService("ServerScriptService")
game:GetService("ServerStorage")
game:GetService("StarterPlayer")
game:GetService("StarterGui")
game:GetService("Players")
local starterPlayer = game:GetService("StarterPlayer")
if not starterPlayer:FindFirstChild("StarterPlayerScripts") then
	local sps = Instance.new("StarterPlayerScripts")
	sps.Parent = starterPlayer
end
if not starterPlayer:FindFirstChild("StarterCharacterScripts") then
	local scs = Instance.new("StarterCharacterScripts")
	scs.Parent = starterPlayer
end
local baseplate = Instance.new("Part")
baseplate.Name = "Baseplate"
baseplate.Anchored = true
baseplate.Locked = true
baseplate.Size = Vector3.new(512, 16, 512)
baseplate.CFrame = CFrame.new(0, -8, 0)
baseplate.Color = Color3.fromRGB(91, 93, 105)
baseplate.Parent = ws
local spawnPad = Instance.new("SpawnLocation")
spawnPad.Name = "SpawnLocation"
spawnPad.Anchored = true
spawnPad.Size = Vector3.new(12, 1, 12)
spawnPad.CFrame = CFrame.new(0, 0.5, 60)
spawnPad.Parent = ws
testKit.Parent = ws
fs.writeFile(path("KitInsertTest.rbxlx"), roblox.serializePlace(game, true))
print("wrote KitInsertTest.rbxlx")
