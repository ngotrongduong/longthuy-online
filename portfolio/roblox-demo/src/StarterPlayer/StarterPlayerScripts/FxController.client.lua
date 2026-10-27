-- FxController: every visual effect is made here, on the client. The server only says
-- WHAT happened (remote events); it never builds or replicates effect instances.
-- Each effect has a bounded lifetime and cleans up after itself. Camera/lighting changes
-- made by an effect are put back by one cleanup function.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Fx = Remotes:WaitForChild("Fx")
local FxFast = Remotes:WaitForChild("FxFast")

local player = Players.LocalPlayer
local plot = workspace:WaitForChild("Plot")
local collector = plot:WaitForChild("Collector")
local intake = collector:WaitForChild("Intake") :: BasePart
local collectPad = plot:WaitForChild("CollectPad") :: BasePart

local TEX = {
	Spark = "rbxasset://textures/particles/sparkles_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	Glow = "rbxasset://textures/particles/forcefield_glow_main.dds",
	Shock = "rbxasset://textures/particles/explosion01_shockwave_main.dds",
}
local TEAL = Color3.fromRGB(46, 214, 170)
local PURPLE = Color3.fromRGB(160, 96, 255)
local GOLD = Color3.fromRGB(255, 200, 70)
local PLOT_CENTER = Vector3.new(0, 1.2, 2)

local fxFolder = Instance.new("Folder")
fxFolder.Name = "ClientFx"
fxFolder.Parent = workspace

local function tween(o: Instance, t: number, props, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function seq(points: { { number } }): NumberSequence
	local kps = {}
	for _, p in ipairs(points) do
		table.insert(kps, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(kps)
end

-- An invisible, anchored, non-colliding holder part for emitters, removed after `life` s.
local function holder(cf: CFrame, size: Vector3, life: number): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = size
	p.CFrame = cf
	p.Parent = fxFolder
	task.delay(life, function()
		p:Destroy()
	end)
	return p
end

local function emitter(parent: Instance, props): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Texture = TEX.Spark
	for k, v in pairs(props) do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

-- Flat shockwave ring on the ground: one particle lying flat (VelocityPerpendicular,
-- tiny upward velocity) that grows and fades.
local function ring(center: Vector3, color: Color3, from: number, to: number, t: number, _thickness: number?)
	local h = holder(CFrame.new(center), Vector3.new(0.2, 0.2, 0.2), t + 0.2)
	emitter(h, {
		Texture = TEX.Shock,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Top,
		Speed = NumberRange.new(0.01),
		Lifetime = NumberRange.new(t),
		Size = seq({ { 0, from }, { 0.35, from + (to - from) * 0.75 }, { 1, to } }),
		Transparency = seq({ { 0, 0.05 }, { 0.5, 0.35 }, { 1, 1 } }),
		Color = ColorSequence.new(color),
		ZOffset = 0.5,
	}):Emit(1)
end

local function floatText(pos: Vector3, text: string, color: Color3, size: number, rise: number, life: number)
	local att = holder(CFrame.new(pos), Vector3.one, life + 0.1)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 60)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 200
	bb.Parent = att
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Text = text
	l.Font = Enum.Font.GothamBlack
	l.TextSize = size
	l.TextColor3 = color
	l.TextStrokeColor3 = Color3.fromRGB(10, 12, 18)
	l.TextStrokeTransparency = 0.35
	l.Parent = bb
	local sc = Instance.new("UIScale")
	sc.Scale = 0.5
	sc.Parent = l
	tween(sc, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(bb, life, { StudsOffsetWorldSpace = Vector3.new(0, rise, 0) }, Enum.EasingStyle.Quad)
	task.delay(life * 0.55, function()
		tween(l, life * 0.45, { TextTransparency = 1, TextStrokeTransparency = 1 }, Enum.EasingStyle.Quad)
	end)
end

-- Collector ---------------------------------------------------------------------
local intakeEmitter = emitter(intake, {
	Color = ColorSequence.new(TEAL),
	Size = seq({ { 0, 0.5 }, { 1, 0 } }),
	Transparency = seq({ { 0, 0.1 }, { 1, 1 } }),
	Lifetime = NumberRange.new(0.4, 0.7),
	Speed = NumberRange.new(6, 10),
	SpreadAngle = Vector2.new(40, 40),
	EmissionDirection = Enum.NormalId.Left, -- the intake faces -X, towards the belt
	Acceleration = Vector3.new(0, -12, 0),
})
local intakeBase = intake.Color
local liveTexts = 0

local function onCollect(value: number, pos: Vector3, golden: boolean)
	intakeEmitter.Color = ColorSequence.new(if golden then GOLD else TEAL)
	intakeEmitter:Emit(3)
	intake.Color = if golden then GOLD else Color3.fromRGB(120, 255, 220)
	tween(intake, 0.25, { Color = intakeBase }, Enum.EasingStyle.Quad)
	if liveTexts < 10 then
		liveTexts += 1
		floatText(pos + Vector3.new(-0.5, 2.2, 0), "+" .. Format.cash(value), if golden then GOLD else Color3.fromRGB(120, 255, 200), 26, 4, 0.9)
		task.delay(0.9, function()
			liveTexts -= 1
		end)
	end
end

local function onBankClaimed(amount: number)
	local pos = collectPad.Position + Vector3.new(0, 0.6, 0)
	local h = holder(CFrame.new(pos), Vector3.new(6, 0.2, 6), 2.5)
	local burst = emitter(h, {
		Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 240, 180)),
		Size = seq({ { 0, 0.9 }, { 0.6, 0.6 }, { 1, 0 } }),
		Transparency = seq({ { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } }),
		Lifetime = NumberRange.new(0.8, 1.3),
		Speed = NumberRange.new(16, 28),
		SpreadAngle = Vector2.new(35, 35),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, -40, 0),
		Drag = 1.5,
		RotSpeed = NumberRange.new(-200, 200),
		Shape = Enum.ParticleEmitterShape.Box,
	})
	burst:Emit(36)
	ring(pos, GOLD, 4, 18, 0.6)
	floatText(pos + Vector3.new(0, 5, 0), "+" .. Format.cash(amount), GOLD, 40, 5, 1.4)
end

-- Dropper build-in ----------------------------------------------------------------
local function onDropperBuilt(model: Model)
	if not model or not model.Parent then
		return
	end
	local parts = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	table.sort(parts, function(a, b)
		return a.Position.Y < b.Position.Y
	end)
	for i, p in ipairs(parts) do
		local final = p.CFrame
		local finalT = p.Transparency
		p.CFrame = final + Vector3.new(0, 9, 0)
		p.Transparency = 1
		task.delay((i - 1) * 0.045, function()
			tween(p, 0.5, { CFrame = final }, Enum.EasingStyle.Back)
			tween(p, 0.25, { Transparency = finalT }, Enum.EasingStyle.Quad)
		end)
	end
	local base = model:GetPivot().Position + Vector3.new(0, 0.3, -6.5)
	task.delay(0.42, function()
		local h = holder(CFrame.new(base), Vector3.new(4, 0.2, 4), 2.5)
		emitter(h, {
			Texture = TEX.Smoke,
			LightEmission = 0,
			LightInfluence = 1,
			Color = ColorSequence.new(Color3.fromRGB(240, 238, 232)),
			Size = seq({ { 0, 1.5 }, { 1, 4.5 } }),
			Transparency = seq({ { 0, 0.45 }, { 1, 1 } }),
			Lifetime = NumberRange.new(0.6, 1.0),
			Speed = NumberRange.new(6, 10),
			SpreadAngle = Vector2.new(80, 80),
			EmissionDirection = Enum.NormalId.Top,
			Drag = 4,
			Rotation = NumberRange.new(0, 360),
			Shape = Enum.ParticleEmitterShape.Box,
		}):Emit(14)
		emitter(h, {
			Color = ColorSequence.new(TEAL, Color3.fromRGB(220, 255, 245)),
			Size = seq({ { 0, 0.7 }, { 1, 0 } }),
			Lifetime = NumberRange.new(0.6, 1.1),
			Speed = NumberRange.new(10, 22),
			SpreadAngle = Vector2.new(60, 60),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0, -30, 0),
			Drag = 2,
		}):Emit(26)
		ring(base, TEAL, 2, 14, 0.55)
	end)
end

-- Rebirth -------------------------------------------------------------------------
local flash = Lighting:FindFirstChild("RebirthFlash") or Instance.new("ColorCorrectionEffect")
flash.Name = "RebirthFlash"
flash.Enabled = true
flash.Brightness = 0
flash.Contrast = 0
flash.TintColor = Color3.new(1, 1, 1)
flash.Parent = Lighting

local rebirthCleanup: (() -> ())? = nil
local fxGui = Instance.new("ScreenGui")
fxGui.Name = "FxGui"
fxGui.IgnoreGuiInset = true
fxGui.ResetOnSpawn = false
fxGui.DisplayOrder = 5
fxGui.Parent = player:WaitForChild("PlayerGui")

local function onRebirthStart(from: number, to: number)
	if rebirthCleanup then
		rebirthCleanup()
	end
	local camera = workspace.CurrentCamera
	local fov0 = camera.FieldOfView
	local highlights = {}
	for _, m in ipairs(plot:GetChildren()) do
		if m:IsA("Model") and m.Name:match("^Dropper") then
			local hl = Instance.new("Highlight")
			hl.FillColor = PURPLE
			hl.OutlineColor = Color3.fromRGB(230, 200, 255)
			hl.FillTransparency = 1
			hl.OutlineTransparency = 1
			hl.DepthMode = Enum.HighlightDepthMode.Occluded
			hl.Parent = m
			tween(hl, 0.85, { FillTransparency = 0.35, OutlineTransparency = 0.1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			table.insert(highlights, hl)
		end
	end
	-- Anticipation: energy pulled into the plot centre
	local ball = holder(CFrame.new(PLOT_CENTER + Vector3.new(0, 5, 0)), Vector3.new(56, 56, 56), 3)
	ball.Shape = Enum.PartType.Ball
	local pull = emitter(ball, {
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		Color = ColorSequence.new(PURPLE, Color3.fromRGB(240, 220, 255)),
		Size = seq({ { 0, 0.9 }, { 0.7, 2.4 }, { 1, 0 } }),
		Transparency = seq({ { 0, 1 }, { 0.2, 0.05 }, { 1, 0.2 } }),
		Lifetime = NumberRange.new(0.8, 0.9),
		Speed = NumberRange.new(30, 34),
		Rate = 220,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
	})
	local core = holder(CFrame.new(PLOT_CENTER + Vector3.new(0, 5, 0)), Vector3.one, 3)
	local glow = emitter(core, {
		Texture = TEX.Glow,
		Color = ColorSequence.new(PURPLE),
		Size = seq({ { 0, 2 }, { 1, 9 } }),
		Transparency = seq({ { 0, 0.7 }, { 1, 1 } }),
		Lifetime = NumberRange.new(0.5),
		Speed = NumberRange.new(0),
		Rate = 18,
	})
	tween(camera, 0.9, { FieldOfView = fov0 - 6 }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

	local cleaned = false
	rebirthCleanup = function()
		if cleaned then
			return
		end
		cleaned = true
		pull.Enabled = false
		glow.Enabled = false
		for _, hl in ipairs(highlights) do
			hl:Destroy()
		end
		tween(camera, 0.6, { FieldOfView = fov0 }, Enum.EasingStyle.Quint)
		tween(flash, 0.5, { Brightness = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1) }, Enum.EasingStyle.Quad)
		rebirthCleanup = nil
	end
	task.delay(4, function()
		if not cleaned and rebirthCleanup then
			rebirthCleanup() -- safety net if RebirthDone never arrives
		end
	end)
end

local function bigTitle(title: string, sub: string)
	local holderFrame = Instance.new("Frame")
	holderFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	holderFrame.Position = UDim2.fromScale(0.5, 0.36)
	holderFrame.Size = UDim2.fromScale(0.4, 0.17)
	holderFrame.BackgroundTransparency = 1
	holderFrame.Parent = fxGui
	local sc = Instance.new("UIScale")
	sc.Scale = 0.4
	sc.Parent = holderFrame
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 0.62)
	t.Text = title
	t.TextScaled = true
	t.Font = Enum.Font.GothamBlack
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Parent = holderFrame
	local st = Instance.new("UIStroke")
	st.Color = PURPLE
	st.Thickness = 4
	st.Parent = t
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(225, 200, 255))
	g.Rotation = 90
	g.Parent = t
	local s = Instance.new("TextLabel")
	s.BackgroundTransparency = 1
	s.Position = UDim2.fromScale(0.15, 0.66)
	s.Size = UDim2.fromScale(0.7, 0.3)
	s.Text = sub
	s.TextScaled = true
	s.Font = Enum.Font.GothamBlack
	s.TextColor3 = GOLD
	s.Parent = holderFrame
	local st2 = Instance.new("UIStroke")
	st2.Color = Color3.fromRGB(20, 14, 34)
	st2.Thickness = 3
	st2.Parent = s
	tween(sc, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(1.7, function()
		tween(sc, 0.4, { Scale = 1.15 }, Enum.EasingStyle.Quad)
		tween(t, 0.4, { TextTransparency = 1 })
		tween(s, 0.4, { TextTransparency = 1 })
		tween(st, 0.4, { Transparency = 1 })
		tween(st2, 0.4, { Transparency = 1 })
		task.wait(0.45)
		holderFrame:Destroy()
	end)
end

local lastFrom = 1
local function onRebirthDone(rebirths: number, mult: number)
	-- Flash (tinted, not full white) then decay
	flash.TintColor = Color3.fromRGB(240, 228, 255)
	flash.Brightness = 0.16
	flash.Contrast = 0.04
	if rebirthCleanup then
		rebirthCleanup()
	end
	local c = PLOT_CENTER
	ring(c + Vector3.new(0, 0.2, 0), PURPLE, 6, 96, 0.9, 0.35)
	task.delay(0.08, function()
		ring(c + Vector3.new(0, 0.3, 0), Color3.fromRGB(255, 235, 255), 4, 70, 0.7, 0.2)
	end)
	-- Column of light
	local col = Instance.new("Part")
	col.Shape = Enum.PartType.Cylinder
	col.Material = Enum.Material.Neon
	col.Color = Color3.fromRGB(205, 160, 255)
	col.Anchored = true
	col.CanCollide = false
	col.CanQuery = false
	col.CanTouch = false
	col.CastShadow = false
	col.Size = Vector3.new(60, 7, 7)
	col.CFrame = CFrame.new(c + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	col.Transparency = 0.25
	col.Parent = fxFolder
	tween(col, 0.7, { Size = Vector3.new(60, 0.5, 0.5), Transparency = 1 }, Enum.EasingStyle.Quart)
	task.delay(0.75, function()
		col:Destroy()
	end)
	-- Burst of sparks, then a slow shower over the plot
	local h = holder(CFrame.new(c + Vector3.new(0, 2, 0)), Vector3.new(2, 2, 2), 4)
	emitter(h, {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 200)),
			ColorSequenceKeypoint.new(0.4, GOLD),
			ColorSequenceKeypoint.new(1, PURPLE),
		}),
		Size = seq({ { 0, 1.4 }, { 0.5, 1 }, { 1, 0 } }),
		Transparency = seq({ { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } }),
		Lifetime = NumberRange.new(1.2, 2.0),
		Speed = NumberRange.new(35, 70),
		SpreadAngle = Vector2.new(70, 70),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, -35, 0),
		Drag = 2.2,
		RotSpeed = NumberRange.new(-180, 180),
	}):Emit(90)
	local sky = holder(CFrame.new(c + Vector3.new(0, 26, 0)), Vector3.new(56, 1, 44), 4.5)
	local shower = emitter(sky, {
		Shape = Enum.ParticleEmitterShape.Box,
		Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 250, 230)),
		Size = seq({ { 0, 0 }, { 0.15, 0.6 }, { 1, 0 } }),
		Lifetime = NumberRange.new(1.6, 2.2),
		Speed = NumberRange.new(6, 10),
		EmissionDirection = Enum.NormalId.Bottom,
		Acceleration = Vector3.new(0, -6, 0),
		Rate = 70,
	})
	task.delay(1.4, function()
		shower.Enabled = false
	end)
	bigTitle("REBIRTH!", "CASH " .. Format.mult(lastFrom) .. "  >>  " .. Format.mult(mult))
end

Fx.OnClientEvent:Connect(function(kind, a, b)
	if kind == "BankClaimed" then
		onBankClaimed(a)
	elseif kind == "DropperBuilt" then
		onDropperBuilt(a)
	elseif kind == "RebirthStart" then
		lastFrom = a
		onRebirthStart(a, b)
	elseif kind == "RebirthDone" then
		onRebirthDone(a, b)
	end
end)

FxFast.OnClientEvent:Connect(function(kind, value, pos, golden)
	if kind == "Collect" then
		onCollect(value, pos, golden)
	end
end)

-- Golden drops (2x Cash) get a small sparkle so the boost is visible on the belt.
local drops = plot:WaitForChild("Drops")
drops.ChildAdded:Connect(function(part)
	if part:IsA("BasePart") and part:GetAttribute("Golden") then
		emitter(part, {
			Color = ColorSequence.new(Color3.fromRGB(255, 236, 170)),
			Size = seq({ { 0, 0.5 }, { 1, 0 } }),
			Lifetime = NumberRange.new(0.4, 0.6),
			Speed = NumberRange.new(1, 2),
			SpreadAngle = Vector2.new(180, 180),
			Rate = 5,
		})
	end
end)
