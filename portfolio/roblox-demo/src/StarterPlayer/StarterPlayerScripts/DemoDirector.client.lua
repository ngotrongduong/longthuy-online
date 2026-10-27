-- DemoDirector: client side of the portfolio recording (camera shots, captions, cards).
-- It only runs while the server script AutoDemo_ForRecording sets the attribute
-- ReplicatedStorage.DemoActive. In normal play this script does nothing.
-- Button presses go through the HUD's own handlers, so the server sees normal requests.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Demo = Remotes:WaitForChild("Demo")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = {
	Teal = Color3.fromRGB(46, 214, 170),
	Gold = Color3.fromRGB(255, 196, 64),
	Purple = Color3.fromRGB(170, 110, 255),
}
local TEXT = Color3.fromRGB(246, 247, 252)
local SUB = Color3.fromRGB(170, 176, 196)
local PANEL = Color3.fromRGB(14, 16, 24)

local function la(pos: Vector3, look: Vector3)
	return { pos = pos, look = look }
end
local SHOTS = {
	Establish = { la(Vector3.new(-40, 30, 60), Vector3.new(2, 3, 2)), la(Vector3.new(-6, 21, 52), Vector3.new(4, 3, 2)) },
	Droppers = { la(Vector3.new(-26, 13, 25), Vector3.new(-5, 7, -2)), la(Vector3.new(-15, 12, 24), Vector3.new(1, 7, -2)) },
	ShopView = { la(Vector3.new(2, 23, 48), Vector3.new(2, 4, 0)), la(Vector3.new(2, 20, 42), Vector3.new(2, 4, 0)) },
	Belt = { la(Vector3.new(-1, 9, 8), Vector3.new(19, 4, -1)), la(Vector3.new(5, 8.5, 7.5), Vector3.new(20, 4, -1)) },
	RebirthWide = { la(Vector3.new(0, 30, 48), Vector3.new(0, 4, -1)), la(Vector3.new(0, 25, 41), Vector3.new(0, 5, -1)) },
	DataShot = { la(Vector3.new(28, 22, 42), Vector3.new(-6, 4, 0)), la(Vector3.new(23, 19, 36), Vector3.new(-6, 4, 0)) },
	FinalSweep = { la(Vector3.new(44, 28, 48), Vector3.new(0, 4, 0)), la(Vector3.new(-44, 28, 48), Vector3.new(0, 4, 0)) },
}

local active = false
local shot: { from: any, to: any, t0: number, dur: number }? = nil
local hudApi: BindableFunction? = nil
local frameRect = { x = 0, y = 0, w = 0, h = 0 }

local gui = Instance.new("ScreenGui")
gui.Name = "DemoGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Enabled = false
gui.Parent = playerGui
local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = gui
local rootScale = Instance.new("UIScale")

local function new(class: string, props, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do
		(o :: any)[k] = v
	end
	if (o:IsA("TextLabel")) and props.BackgroundTransparency == nil then
		(o :: any).BackgroundTransparency = 1
	end
	o.Parent = parent
	return o
end
local function corner(o: Instance, px: number)
	new("UICorner", { CornerRadius = UDim.new(0, px) }, o)
end
local function tween(o: Instance, t: number, props, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- Every panel lives in a 1280x720 "design canvas" that is scaled into the 16:9 frame.
local canvas = new("Frame", {
	Name = "Canvas",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(1280, 720),
	BackgroundTransparency = 1,
}, root)
rootScale.Parent = canvas

-- Caption (lower third) ---------------------------------------------------------
local caption = new("Frame", {
	Name = "Caption",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, -120, 1, -34),
	Size = UDim2.fromOffset(0, 84),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0.08,
	Visible = false,
}, canvas)
corner(caption, 18)
local capStroke = new("UIStroke", { Color = COLORS.Teal, Transparency = 0.4, Thickness = 2 }, caption)
new("UIPadding", { PaddingLeft = UDim.new(0, 30), PaddingRight = UDim.new(0, 26) }, caption)
local capBar = new("Frame", {
	Position = UDim2.new(0, -16, 0.5, -26),
	Size = UDim2.fromOffset(5, 52),
	BackgroundColor3 = COLORS.Teal,
	BorderSizePixel = 0,
}, caption)
corner(capBar, 3)
local capTitle = new("TextLabel", {
	Position = UDim2.fromOffset(0, 12),
	Size = UDim2.fromOffset(0, 34),
	AutomaticSize = Enum.AutomaticSize.X,
	Font = Enum.Font.GothamBlack,
	TextSize = 30,
	TextColor3 = TEXT,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
}, caption)
local capSub = new("TextLabel", {
	Position = UDim2.fromOffset(0, 50),
	Size = UDim2.fromOffset(0, 20),
	AutomaticSize = Enum.AutomaticSize.X,
	Font = Enum.Font.GothamMedium,
	TextSize = 16,
	TextColor3 = SUB,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
}, caption)
local capScale = new("UIScale", {}, caption)

local function setCaption(title: string?, sub: string?, colorKey: string?)
	if not title then
		tween(capScale, 0.25, { Scale = 0.9 }, Enum.EasingStyle.Quad)
		tween(caption, 0.25, { BackgroundTransparency = 1 })
		tween(capTitle, 0.25, { TextTransparency = 1 })
		tween(capSub, 0.25, { TextTransparency = 1 })
		tween(capStroke, 0.25, { Transparency = 1 })
		tween(capBar, 0.25, { BackgroundTransparency = 1 })
		return
	end
	local color = COLORS[colorKey or "Teal"] or COLORS.Teal
	capTitle.Text = title
	capSub.Text = sub or ""
	capStroke.Color = color
	capBar.BackgroundColor3 = color
	caption.Visible = true
	caption.BackgroundTransparency = 1
	capTitle.TextTransparency = 1
	capSub.TextTransparency = 1
	capStroke.Transparency = 1
	capBar.BackgroundTransparency = 1
	caption.Position = UDim2.new(0.5, -120, 1, -18)
	capScale.Scale = 0.96
	tween(caption, 0.45, { Position = UDim2.new(0.5, -120, 1, -34), BackgroundTransparency = 0.08 })
	tween(capScale, 0.45, { Scale = 1 })
	tween(capTitle, 0.4, { TextTransparency = 0 })
	tween(capStroke, 0.4, { Transparency = 0.4 })
	tween(capBar, 0.4, { BackgroundTransparency = 0 })
	task.delay(0.12, function()
		tween(capSub, 0.4, { TextTransparency = 0 })
	end)
end

-- Data card (left) ------------------------------------------------------------------
local dataCard = new("Frame", {
	Name = "DataCard",
	Position = UDim2.fromOffset(22, 262),
	Size = UDim2.fromOffset(470, 238),
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0.06,
	Visible = false,
}, canvas)
corner(dataCard, 18)
new("UIStroke", { Color = COLORS.Teal, Transparency = 0.5, Thickness = 2 }, dataCard)
new("TextLabel", {
	Position = UDim2.fromOffset(22, 16),
	Size = UDim2.fromOffset(420, 22),
	Text = "DataService.load(player)",
	Font = Enum.Font.Code,
	TextSize = 20,
	TextColor3 = COLORS.Teal,
	TextXAlignment = Enum.TextXAlignment.Left,
}, dataCard)
local DATA_LINES = {
	"1  UpdateAsync -> write lock {JobId, time}",
	"2  lock held by another server? retry, backoff",
	"3  autosave every 60 s, flush on BindToClose",
	"4  save refuses to write if the lock was lost",
	"5  receipts stored, granted once, then saved",
}
local dataLabels = {}
for i, line in ipairs(DATA_LINES) do
	dataLabels[i] = new("TextLabel", {
		Position = UDim2.fromOffset(22, 22 + i * 28),
		Size = UDim2.fromOffset(430, 22),
		Text = line,
		Font = Enum.Font.Code,
		TextSize = 16,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1,
	}, dataCard)
end
local dataStatus = new("TextLabel", {
	Position = UDim2.fromOffset(22, 200),
	Size = UDim2.fromOffset(430, 22),
	Text = "",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = COLORS.Gold,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTransparency = 1,
}, dataCard)

local function showDataCard(on: boolean)
	if on then
		dataCard.Visible = true
		dataCard.Position = UDim2.fromOffset(-10, 262)
		tween(dataCard, 0.45, { Position = UDim2.fromOffset(22, 262) })
		local mode = player:GetAttribute("SaveMode")
		dataStatus.Text = "This session: "
			.. tostring(player:GetAttribute("SaveStatus") or "?")
		dataStatus.TextColor3 = if mode == "DataStore" then COLORS.Teal else COLORS.Gold
		for i, l in ipairs(dataLabels) do
			task.delay(0.15 + i * 0.22, function()
				tween(l, 0.3, { TextTransparency = 0 })
			end)
		end
		task.delay(0.15 + (#dataLabels + 1) * 0.22, function()
			tween(dataStatus, 0.3, { TextTransparency = 0 })
		end)
	else
		tween(dataCard, 0.3, { Position = UDim2.fromOffset(-500, 262) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
end

-- Devices card (left): same layout on a phone and a monitor -------------------------
local deviceCard = new("Frame", {
	Name = "DeviceCard",
	Position = UDim2.fromOffset(22, 262),
	Size = UDim2.fromOffset(470, 238),
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0.06,
	Visible = false,
}, canvas)
corner(deviceCard, 18)
new("UIStroke", { Color = COLORS.Teal, Transparency = 0.5, Thickness = 2 }, deviceCard)

local function miniHud(screen: Frame, k: number)
	-- tiny blocks at the same anchors the real HUD uses
	local function block(anchor: Vector2, pos: UDim2, size: Vector2, color: Color3)
		local b = new("Frame", {
			AnchorPoint = anchor,
			Position = pos,
			Size = UDim2.fromOffset(size.X * k, size.Y * k),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
		}, screen)
		corner(b, math.max(2, math.floor(4 * k)))
	end
	for i = 0, 2 do
		block(Vector2.zero, UDim2.fromOffset(4 * k, (4 + i * 13) * k), Vector2.new(46, 10), Color3.fromRGB(60, 66, 86))
	end
	for i = 0, 2 do
		local c = ({ COLORS.Teal, COLORS.Purple, COLORS.Gold })[i + 1]
		block(Vector2.new(1, 1), UDim2.new(1, -4 * k, 1, -(4 + (2 - i) * 15) * k), Vector2.new(46, 12), c)
	end
	block(Vector2.new(0.5, 1), UDim2.new(0.5, -10 * k, 1, -5 * k), Vector2.new(70, 12), Color3.fromRGB(90, 96, 120))
end

local function device(name: string, x: number, w: number, h: number, bezel: number, label: string, k: number)
	local body = new("Frame", {
		Name = name,
		Position = UDim2.fromOffset(x, 30 + (150 - h) / 2),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Color3.fromRGB(40, 44, 58),
	}, deviceCard)
	corner(body, bezel + 4)
	local screen = new("Frame", {
		Position = UDim2.fromOffset(bezel, bezel),
		Size = UDim2.new(1, -2 * bezel, 1, -2 * bezel),
		BackgroundColor3 = Color3.fromRGB(96, 168, 92),
		ClipsDescendants = true,
	}, body)
	corner(screen, bezel)
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(150, 205, 255), Color3.fromRGB(120, 190, 110)),
	}, screen)
	miniHud(screen, k)
	new("TextLabel", {
		Position = UDim2.fromOffset(x, 196),
		Size = UDim2.fromOffset(w, 20),
		Text = label,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = SUB,
	}, deviceCard)
	return body
end
local phone = device("Phone", 24, 190, 92, 7, "Phone (landscape, touch)", 0.62)
local monitor = device("Monitor", 236, 210, 132, 6, "PC (mouse, any resolution)", 0.85)

local function showDeviceCard(on: boolean)
	if on then
		deviceCard.Visible = true
		deviceCard.Position = UDim2.fromOffset(-10, 262)
		tween(deviceCard, 0.45, { Position = UDim2.fromOffset(22, 262) })
		for _, d in ipairs({ phone, monitor }) do
			local s = d:FindFirstChildOfClass("UIScale") or new("UIScale", {}, d)
			s.Scale = 0.7
			tween(s, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	else
		tween(deviceCard, 0.3, { Position = UDim2.fromOffset(-500, 262) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
end

-- End card -------------------------------------------------------------------------
local endCard = new("Frame", {
	Name = "EndCard",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(10, 11, 17),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 50,
}, root)
local endInner = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(1280, 720),
	BackgroundTransparency = 1,
	ZIndex = 51,
}, endCard)
local endScale = new("UIScale", {}, endInner)
local endTitle = new("TextLabel", {
	Position = UDim2.fromOffset(0, 250),
	Size = UDim2.fromOffset(1280, 90),
	Text = "LONG THUY",
	Font = Enum.Font.GothamBlack,
	TextSize = 84,
	TextColor3 = TEXT,
	TextTransparency = 1,
	ZIndex = 52,
}, endInner)
local endSub = new("TextLabel", {
	Position = UDim2.fromOffset(0, 346),
	Size = UDim2.fromOffset(1280, 34),
	Text = "Roblox systems built to hold up in a live game",
	Font = Enum.Font.GothamBold,
	TextSize = 28,
	TextColor3 = COLORS.Teal,
	TextTransparency = 1,
	ZIndex = 52,
}, endInner)
local endList = new("TextLabel", {
	Position = UDim2.fromOffset(0, 404),
	Size = UDim2.fromOffset(1280, 26),
	Text = "Robux shops  ·  DataStore sessions  ·  Tycoons & rebirth  ·  Pets & eggs",
	Font = Enum.Font.GothamMedium,
	TextSize = 22,
	TextColor3 = SUB,
	TextTransparency = 1,
	ZIndex = 52,
}, endInner)
local endLine = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromOffset(640, 388),
	Size = UDim2.fromOffset(0, 3),
	BackgroundColor3 = COLORS.Teal,
	BorderSizePixel = 0,
	ZIndex = 52,
}, endInner)

local function showEndCard()
	endCard.Visible = true
	tween(endCard, 0.7, { BackgroundTransparency = 0.05 }, Enum.EasingStyle.Quad)
	task.delay(0.35, function()
		tween(endTitle, 0.6, { TextTransparency = 0 })
		tween(endLine, 0.8, { Size = UDim2.fromOffset(420, 3) })
	end)
	task.delay(0.6, function()
		tween(endSub, 0.6, { TextTransparency = 0 })
	end)
	task.delay(0.85, function()
		tween(endList, 0.6, { TextTransparency = 0 })
	end)
end

-- Frame + camera ------------------------------------------------------------------------
local calib: Frame? = nil
local function applyFrame()
	local vp = workspace.CurrentCamera.ViewportSize
	local w, h = vp.X, vp.Y
	if w / h > 16 / 9 then
		w = math.floor(h * 16 / 9)
	else
		h = math.floor(w * 9 / 16)
	end
	local x = math.floor((vp.X - w) / 2)
	local y = math.floor((vp.Y - h) / 2)
	frameRect = { x = x, y = y, w = w, h = h }
	local hudGui = playerGui:FindFirstChild("HUD")
	if hudGui then
		hudGui.ScreenInsets = Enum.ScreenInsets.None
		hudGui.IgnoreGuiInset = true
	end
	for _, r in ipairs({ root, (playerGui:FindFirstChild("HUD") and playerGui.HUD:FindFirstChild("Root")) :: any }) do
		if r then
			r.Position = UDim2.fromOffset(x, y)
			r.Size = UDim2.fromOffset(w, h)
		end
	end
	rootScale.Scale = w / 1280
	endScale.Scale = w / 1280
	ReplicatedStorage:SetAttribute("DemoFrameClient", string.format("%d,%d,%d,%d,%d,%d", x, y, w, h, vp.X, vp.Y))
end

local function setCalibration(on: boolean)
	if on and not calib then
		-- solid magenta over the exact 16:9 frame, so the recorder can find the crop
		calib = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(255, 0, 255),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ZIndex = 100,
		}, root)
	elseif not on and calib then
		calib:Destroy()
		calib = nil
	end
end

local function ease(a: number): number
	return a * a * (3 - 2 * a) -- smoothstep
end

RunService:BindToRenderStep("DemoCamera", Enum.RenderPriority.Camera.Value + 1, function()
	if not active or not shot then
		return
	end
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	local a = ease(math.clamp((os.clock() - shot.t0) / shot.dur, 0, 1))
	local pos = shot.from.pos:Lerp(shot.to.pos, a)
	local look = shot.from.look:Lerp(shot.to.look, a)
	camera.CFrame = CFrame.lookAt(pos, look)
end)

local function getHud(): BindableFunction?
	if hudApi and hudApi.Parent then
		return hudApi
	end
	local hud = playerGui:FindFirstChild("HUD")
	hudApi = hud and hud:FindFirstChild("HudApi") :: BindableFunction?
	return hudApi
end

local function activate()
	if active then
		return
	end
	active = true
	gui.Enabled = true
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end)
	applyFrame()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyFrame)
	shot = { from = SHOTS.Establish[1], to = SHOTS.Establish[1], t0 = os.clock(), dur = 1 }
end

Demo.OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "Activate" then
		activate()
	elseif kind == "Calibrate" then
		setCalibration(a == true)
	elseif kind == "Shot" then
		local s = SHOTS[a]
		if s then
			shot = { from = s[1], to = s[2], t0 = os.clock(), dur = b or 5 }
		end
	elseif kind == "Caption" then
		setCaption(a, b, c)
	elseif kind == "DataCard" then
		showDataCard(a == true)
	elseif kind == "DeviceCard" then
		showDeviceCard(a == true)
	elseif kind == "EndCard" then
		showEndCard()
	elseif kind == "Walk" then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:MoveTo(a)
		end
	elseif kind == "Hud" then
		local api = getHud()
		if api then
			task.spawn(function()
				api:Invoke(a, b)
			end)
		end
	end
end)

if ReplicatedStorage:GetAttribute("DemoActive") then
	activate()
end
ReplicatedStorage:GetAttributeChangedSignal("DemoActive"):Connect(function()
	if ReplicatedStorage:GetAttribute("DemoActive") then
		activate()
	end
end)
