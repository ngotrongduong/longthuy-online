-- Hud: the player's HUD (cash, multiplier, rebirths), action buttons, toasts and shop.
-- Installed at: StarterPlayer.StarterPlayerScripts.TycoonKit.Hud
--
-- Display only: every value comes from player attributes the server sets; every button
-- sends a request the server checks. One UIScale keeps the layout readable from a phone
-- in landscape to a 4K monitor. On touch screens the action buttons sit at the top
-- right, away from Roblox's jump button and thumbstick.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
-- The Installer may also start this script from PlayerGui for players who were already
-- in the server; this flag makes sure only one copy ever runs.
if player:GetAttribute("TycoonKitHud") then
	return
end
player:SetAttribute("TycoonKitHud", true)

local Shared = ReplicatedStorage:WaitForChild("TycoonKit")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = Shared:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local Fx = Remotes:WaitForChild("Fx")

local playerGui = player:WaitForChild("PlayerGui")
local isTouch = UserInputService.TouchEnabled

local THEME = {
	Panel = Color3.fromRGB(16, 18, 26),
	Text = Color3.fromRGB(246, 247, 252),
	Sub = Color3.fromRGB(150, 158, 180),
	Cash = Color3.fromRGB(64, 226, 146),
	Teal = Color3.fromRGB(46, 214, 170),
	Purple = Color3.fromRGB(160, 96, 255),
	Gold = Color3.fromRGB(255, 196, 64),
	Red = Color3.fromRGB(255, 92, 92),
	Ink = Color3.fromRGB(18, 20, 28),
}
local BOLD, BLACK, MEDIUM = Enum.Font.GothamBold, Enum.Font.GothamBlack, Enum.Font.GothamMedium
local ROBUX = "rbxasset://textures/ui/common/robux@3x.png" -- built-in Roblox texture

-- Small UI helpers ----------------------------------------------------------------
local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do
		(o :: any)[k] = v
	end
	if (o:IsA("TextLabel") or o:IsA("TextButton")) and props.BackgroundTransparency == nil then
		(o :: any).BackgroundTransparency = 1
	end
	o.Parent = parent
	return o
end
local function corner(o: Instance, px: number)
	new("UICorner", { CornerRadius = UDim.new(0, px) }, o)
end
local function stroke(o: Instance, color: Color3, transparency: number, thickness: number?)
	return new("UIStroke", {
		Color = color,
		Transparency = transparency,
		Thickness = thickness or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, o)
end
local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- Root ----------------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "TycoonKitHud",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
}, playerGui)
local root = new("Frame", { Name = "Root", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, gui)

local scales: { UIScale } = {}
local uiScale = 1
local function scaled(o: Instance)
	table.insert(scales, new("UIScale", {}, o))
end

-- Stat cards (top-left) -------------------------------------------------------------
local stats = new("Frame", {
	Name = "Stats",
	Position = UDim2.new(0, 22, 0, 22),
	Size = UDim2.fromOffset(260, 214),
	BackgroundTransparency = 1,
}, root)
scaled(stats)
new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, stats)

local function statCard(order: number, color: Color3, glyph: string, label: string)
	local card = new("Frame", {
		Name = label,
		Size = UDim2.fromOffset(260, 64),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.14,
		LayoutOrder = order,
	}, stats)
	corner(card, 16)
	stroke(card, Color3.new(1, 1, 1), 0.88)
	local icon = new("Frame", { Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(9, 9), BackgroundColor3 = color }, card)
	corner(icon, 13)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)) }, icon)
	new("TextLabel", { Size = UDim2.fromScale(1, 1), Text = glyph, Font = BLACK, TextSize = 22, TextColor3 = THEME.Ink }, icon)
	new("TextLabel", {
		Name = "Label",
		Position = UDim2.fromOffset(68, 11),
		Size = UDim2.fromOffset(180, 14),
		Text = label,
		Font = BOLD,
		TextSize = 12,
		TextColor3 = THEME.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)
	local value = new("TextLabel", {
		Name = "Value",
		Position = UDim2.fromOffset(68, 25),
		Size = UDim2.fromOffset(184, 30),
		Text = "0",
		Font = BLACK,
		TextSize = 27,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)
	return card, value
end

local cashCard, cashValue = statCard(1, THEME.Cash, "$", "CASH")
local multCard, multValue = statCard(2, THEME.Purple, "x", "MULTIPLIER")
local _, rebValue = statCard(3, THEME.Gold, "R", "REBIRTHS")
-- Where the multiplier comes from, two short lines at the right of the value.
local multDetail = new("TextLabel", {
	Name = "Detail",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 24),
	Size = UDim2.fromOffset(84, 32),
	Text = "",
	Font = BOLD,
	TextSize = 11,
	TextColor3 = THEME.Purple,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextYAlignment = Enum.TextYAlignment.Center,
}, multCard)

-- Save status + active boosts (top-right) ------------------------------------------------
local topRight = new("Frame", {
	Name = "TopRight",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -22, 0, 22),
	Size = UDim2.fromOffset(420, 70),
	BackgroundTransparency = 1,
}, root)
scaled(topRight)
new("UIListLayout", {
	Padding = UDim.new(0, 8),
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, topRight)
local savePill = new("Frame", {
	Name = "SavePill",
	Size = UDim2.fromOffset(0, 32),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = THEME.Panel,
	BackgroundTransparency = 0.14,
	LayoutOrder = 1,
}, topRight)
corner(savePill, 16)
stroke(savePill, Color3.new(1, 1, 1), 0.88)
new("UIPadding", { PaddingLeft = UDim.new(0, 34), PaddingRight = UDim.new(0, 14) }, savePill)
local saveDot = new("Frame", { Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, -22, 0.5, -5), BackgroundColor3 = THEME.Gold }, savePill)
corner(saveDot, 5)
local saveText = new("TextLabel", {
	Size = UDim2.fromOffset(0, 32),
	AutomaticSize = Enum.AutomaticSize.X,
	Text = "Loading profile...",
	Font = BOLD,
	TextSize = 13,
	TextColor3 = THEME.Text,
}, savePill)

local boosts = new("Frame", { Name = "Boosts", Size = UDim2.fromOffset(420, 30), BackgroundTransparency = 1, LayoutOrder = 2 }, topRight)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, boosts)

local boostChips: { [string]: Frame } = {}
for i, pass in ipairs(Config.Passes) do
	local chip = new("Frame", {
		Name = pass.Key,
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = pass.Color,
		Visible = false,
		LayoutOrder = i,
	}, boosts)
	corner(chip, 15)
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, chip)
	new("TextLabel", {
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = string.upper(pass.Name),
		Font = BLACK,
		TextSize = 13,
		TextColor3 = THEME.Ink,
	}, chip)
	new("UIScale", {}, chip) -- used for the pop-in
	boostChips[pass.Key] = chip
end

-- Action buttons --------------------------------------------------------------------
-- PC: bottom-right. Touch: top-right under the boosts (the jump button owns bottom-right).
local actions = new("Frame", {
	Name = "Actions",
	AnchorPoint = if isTouch then Vector2.new(1, 0) else Vector2.new(1, 1),
	Position = if isTouch then UDim2.new(1, -22, 0, 22) else UDim2.new(1, -22, 1, -22),
	Size = UDim2.fromOffset(262, 3 * 70 + 2 * 10),
	BackgroundTransparency = 1,
}, root)
scaled(actions)
new("UIListLayout", {
	Padding = UDim.new(0, 10),
	VerticalAlignment = if isTouch then Enum.VerticalAlignment.Top else Enum.VerticalAlignment.Bottom,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, actions)

local function actionButton(order: number, name: string, color: Color3, title: string)
	local b = new("TextButton", {
		Name = name,
		AutoButtonColor = false,
		Size = UDim2.fromOffset(262, 70),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.1,
		Text = "",
		LayoutOrder = order,
		ClipsDescendants = true,
	}, actions)
	corner(b, 18)
	stroke(b, color, 0.35, 2)
	local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = color, BackgroundTransparency = 0.78 }, b)
	corner(fill, 18)
	local titleLabel = new("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(20, 12),
		Size = UDim2.fromOffset(170, 24),
		Text = title,
		Font = BLACK,
		TextSize = 21,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, b)
	local cost = new("TextLabel", {
		Name = "Cost",
		Position = UDim2.fromOffset(20, 38),
		Size = UDim2.fromOffset(170, 20),
		Text = "",
		Font = BOLD,
		TextSize = 16,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, b)
	local badge = new("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = color,
	}, b)
	corner(badge, 14)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(175, 175, 175)) }, badge)
	local press = new("UIScale", {}, b)
	return b, cost, fill, badge, press, titleLabel
end

local buyBtn, buyCost, buyFill, buyBadge, buyPress = actionButton(1, "BuyDropper", THEME.Teal, "BUY DROPPER")
local rebBtn, rebCost, rebFill, rebBadge, rebPress, rebTitle = actionButton(2, "Rebirth", THEME.Purple, "REBIRTH")
local shopBtn, shopCost, _, shopBadge, shopPress = actionButton(3, "Shop", THEME.Gold, "SHOP")
shopCost.Text = "Passes & items"
new("TextLabel", { Size = UDim2.fromScale(1, 1), Text = "+", Font = BLACK, TextSize = 30, TextColor3 = THEME.Ink }, buyBadge)
new("TextLabel", { Size = UDim2.fromScale(1, 1), Text = "R", Font = BLACK, TextSize = 24, TextColor3 = THEME.Ink }, rebBadge)
new("ImageLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(26, 26),
	BackgroundTransparency = 1,
	Image = ROBUX,
	ImageColor3 = THEME.Ink,
}, shopBadge)

local function ripple(button: GuiObject, press: UIScale)
	local r = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.6,
		ZIndex = 5,
	}, button)
	corner(r, 999)
	tween(r, 0.5, { Size = UDim2.fromOffset(320, 320), BackgroundTransparency = 1 })
	task.delay(0.55, function()
		r:Destroy()
	end)
	tween(press, 0.08, { Scale = 0.93 }).Completed:Connect(function()
		tween(press, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
end

-- Toasts (top-centre) -----------------------------------------------------------------
local toastHolder = new("Frame", {
	Name = "Toasts",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 22),
	Size = UDim2.fromOffset(520, 200),
	BackgroundTransparency = 1,
	ZIndex = 40,
}, root)
scaled(toastHolder)
new("UIListLayout", {
	Padding = UDim.new(0, 8),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, toastHolder)
local toastCount = 0
local liveToasts = 0
local function toast(text: string, color: Color3)
	if liveToasts >= 3 then
		return -- never bury the screen in messages
	end
	liveToasts += 1
	toastCount += 1
	local t = new("Frame", {
		Size = UDim2.fromOffset(0, 42),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.08,
		LayoutOrder = toastCount,
		ZIndex = 40,
	}, toastHolder)
	corner(t, 21)
	local st = stroke(t, color, 0.2, 2)
	new("UIPadding", { PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20) }, t)
	local label = new("TextLabel", {
		Size = UDim2.fromOffset(0, 42),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = text,
		Font = BLACK,
		TextSize = 18,
		TextColor3 = color,
		ZIndex = 41,
	}, t)
	local s = new("UIScale", { Scale = 0.6 }, t)
	tween(s, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(2.6, function()
		tween(t, 0.35, { BackgroundTransparency = 1 })
		tween(label, 0.35, { TextTransparency = 1 })
		tween(st, 0.35, { Transparency = 1 })
		task.wait(0.4)
		t:Destroy()
		liveToasts -= 1
	end)
end

-- Floating +/- numbers next to the cash card ------------------------------------------------
local liveFlyouts = 0
local function flyout(text: string, color: Color3)
	if liveFlyouts >= 4 then
		return
	end
	liveFlyouts += 1
	local l = new("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 12, 0.5, 0),
		Size = UDim2.fromOffset(160, 30),
		Text = text,
		Font = BLACK,
		TextSize = 24,
		TextColor3 = color,
		TextStrokeTransparency = 0.6,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, cashCard)
	tween(l, 1.1, {
		Position = UDim2.new(1, 22, 0.5, if color == THEME.Red then 26 else -26),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}, Enum.EasingStyle.Quad)
	task.delay(1.15, function()
		l:Destroy()
		liveFlyouts -= 1
	end)
end

-- Shop --------------------------------------------------------------------------------
-- One card per game pass, then one per developer product, all from Config.
type ShopItem = { kind: string, data: any }
local items: { ShopItem } = {}
for _, pass in ipairs(Config.Passes) do
	table.insert(items, { kind = "Pass", data = pass })
end
for _, product in ipairs(Config.Products) do
	table.insert(items, { kind = "Product", data = product })
end

local CARD_W, CARD_H, GAP, PAD = 236, 314, 18, 34
local SHOP_W = PAD * 2 + math.max(1, #items) * CARD_W + math.max(0, #items - 1) * GAP
local SHOP_H = 452

local blur = new("BlurEffect", { Name = "TycoonKitShopBlur", Size = 0 }, Lighting)
local shade = new("TextButton", {
	Name = "Shade",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
	ZIndex = 20,
}, root)
local shop = new("Frame", {
	Name = "Shop",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(SHOP_W, SHOP_H),
	BackgroundColor3 = Color3.fromRGB(14, 16, 24),
	BackgroundTransparency = 0.03,
	Visible = false,
	ZIndex = 21,
}, root)
corner(shop, 26)
stroke(shop, THEME.Gold, 0.55, 2)
local shopScale = new("UIScale", {}, shop)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 215)) }, shop)
new("TextLabel", {
	Position = UDim2.fromOffset(PAD, 24),
	Size = UDim2.fromOffset(400, 38),
	Text = "SHOP",
	Font = BLACK,
	TextSize = 36,
	TextColor3 = THEME.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 22,
}, shop)
new("TextLabel", {
	Position = UDim2.fromOffset(PAD, 64),
	Size = UDim2.fromOffset(600, 20),
	Text = "Game passes and items  ·  paid with Robux",
	Font = MEDIUM,
	TextSize = 15,
	TextColor3 = THEME.Sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 22,
}, shop)
local closeBtn = new("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -24, 0, 24),
	Size = UDim2.fromOffset(46, 46),
	BackgroundColor3 = Color3.fromRGB(40, 44, 58),
	BackgroundTransparency = 0,
	Text = "X",
	Font = BLACK,
	TextSize = 20,
	TextColor3 = THEME.Text,
	AutoButtonColor = true,
	ZIndex = 22,
}, shop)
corner(closeBtn, 14)

local cardRow = new("Frame", {
	Name = "Cards",
	Position = UDim2.fromOffset(PAD, 108),
	Size = UDim2.fromOffset(SHOP_W - PAD * 2, CARD_H),
	BackgroundTransparency = 1,
	ZIndex = 22,
}, shop)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder }, cardRow)

type PassCard = { buy: TextButton, price: TextLabel, icon: ImageLabel, check: Frame, stroke: UIStroke, scale: UIScale }
local passCards: { [string]: PassCard } = {}

local function checkMark(parent: Instance, color: Color3, size: number, z: number)
	local holder = new("Frame", { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = z }, parent)
	local w = math.max(3, math.floor(size * 0.14))
	new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.36, 0.6),
		Size = UDim2.fromOffset(math.floor(size * 0.36), w),
		Rotation = 45,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = z,
	}, holder)
	new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.6, 0.48),
		Size = UDim2.fromOffset(math.floor(size * 0.62), w),
		Rotation = -50,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = z,
	}, holder)
	return holder
end

for i, item in ipairs(items) do
	local data = item.data
	local card = new("Frame", {
		Name = data.Key,
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		BackgroundColor3 = Color3.fromRGB(26, 29, 41),
		LayoutOrder = i,
		ZIndex = 22,
	}, cardRow)
	corner(card, 20)
	local st = stroke(card, data.Color, 0.65, 2)
	local cardScale = new("UIScale", {}, card)
	local art = new("Frame", { Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(208, 124), BackgroundColor3 = data.Color, ZIndex = 23 }, card)
	corner(art, 16)
	new("UIGradient", { Rotation = 120, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(120, 120, 135)) }, art)
	new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = data.Icon,
		Font = BLACK,
		TextSize = 58,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.75,
		ZIndex = 24,
	}, art)
	if item.kind == "Product" then
		new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 8),
			Size = UDim2.fromOffset(84, 22),
			BackgroundTransparency = 0.35,
			BackgroundColor3 = THEME.Panel,
			Text = "BUY AGAIN",
			Font = BLACK,
			TextSize = 11,
			TextColor3 = THEME.Text,
			ZIndex = 25,
		}, art)
	end
	new("TextLabel", {
		Position = UDim2.fromOffset(16, 150),
		Size = UDim2.fromOffset(204, 26),
		Text = data.Name,
		Font = BLACK,
		TextSize = 23,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 23,
	}, card)
	new("TextLabel", {
		Position = UDim2.fromOffset(16, 180),
		Size = UDim2.fromOffset(204, 44),
		Text = data.Blurb,
		Font = MEDIUM,
		TextSize = 14,
		TextWrapped = true,
		TextColor3 = THEME.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 23,
	}, card)
	local buy = new("TextButton", {
		Name = "Buy",
		Position = UDim2.fromOffset(14, 248),
		Size = UDim2.fromOffset(208, 52),
		BackgroundColor3 = data.Color,
		BackgroundTransparency = 0,
		Text = "",
		AutoButtonColor = true,
		ZIndex = 23,
	}, card)
	corner(buy, 14)
	local icon = new("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.5, -46, 0.5, 0),
		Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1,
		Image = ROBUX,
		ImageColor3 = THEME.Ink,
		ZIndex = 24,
	}, buy)
	local price = new("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.5, -16, 0.5, 0),
		Size = UDim2.fromOffset(80, 30),
		Text = tostring(data.Price),
		Font = BLACK,
		TextSize = 23,
		TextColor3 = THEME.Ink,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 24,
	}, buy)
	if item.kind == "Pass" then
		local check = new("Frame", {
			Name = "Owned",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -16, 0, 16),
			Size = UDim2.fromOffset(48, 48),
			BackgroundColor3 = THEME.Cash,
			Visible = false,
			ZIndex = 30,
		}, card)
		corner(check, 24)
		stroke(check, Color3.fromRGB(14, 16, 24), 0, 4)
		checkMark(check, Color3.fromRGB(14, 16, 24), 48, 31)
		new("UIScale", { Scale = 0 }, check)
		passCards[data.Key] = { buy = buy, price = price, icon = icon, check = check, stroke = st, scale = cardScale }
		buy.Activated:Connect(function()
			if player:GetAttribute("Pass_" .. data.Key) ~= true then
				Action:FireServer("PromptPass", data.Key)
			end
		end)
	else
		buy.Activated:Connect(function()
			Action:FireServer("PromptProduct", data.Key)
		end)
	end
end

local shopOpen = false
local function shopFitScale(): number
	local size = root.AbsoluteSize
	-- On phones the shop may use the whole screen (the touch controls are hidden then).
	local base = if isTouch then math.max(uiScale, 0.75) else uiScale
	return math.min(base, size.X * 0.96 / SHOP_W, size.Y * 0.94 / SHOP_H)
end
local function setShop(open: boolean)
	if open == shopOpen then
		return
	end
	shopOpen = open
	if isTouch then
		-- The thumbstick and jump button would cover the buy buttons on small phones.
		GuiService.TouchControlsEnabled = not open
	end
	local k = shopFitScale()
	if open then
		shop.Visible = true
		shade.Visible = true
		shopScale.Scale = k * 0.85
		tween(shopScale, 0.45, { Scale = k }, Enum.EasingStyle.Back)
		tween(shade, 0.3, { BackgroundTransparency = 0.55 })
		tween(blur, 0.3, { Size = 14 })
	else
		tween(shopScale, 0.22, { Scale = k * 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(shade, 0.25, { BackgroundTransparency = 1 })
		tween(blur, 0.25, { Size = 0 })
		task.delay(0.22, function()
			if not shopOpen then
				shop.Visible = false
				shade.Visible = false
			end
		end)
	end
end

local function setOwnedVisual(key: string, owned: boolean, animate: boolean)
	local pc = passCards[key]
	if not pc then
		return
	end
	local checkScale = pc.check:FindFirstChildOfClass("UIScale") :: UIScale
	if owned then
		pc.price.Text = "OWNED"
		pc.icon.Visible = false
		pc.price.AnchorPoint = Vector2.new(0.5, 0.5)
		pc.price.Position = UDim2.fromScale(0.5, 0.5)
		pc.price.TextXAlignment = Enum.TextXAlignment.Center
		pc.buy.BackgroundColor3 = THEME.Cash
		pc.buy.AutoButtonColor = false
		pc.stroke.Color = THEME.Cash
		pc.stroke.Transparency = 0.1
		pc.check.Visible = true
		if animate then
			checkScale.Scale = 0
			tween(checkScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
			pc.scale.Scale = 1.06
			tween(pc.scale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
		else
			checkScale.Scale = 1
		end
	else
		pc.check.Visible = false
	end
end

-- Layout scale ------------------------------------------------------------------------
local JUMP_RESERVE = 110 -- px kept free at the bottom right for Roblox's touch jump button
local function updateScale()
	local size = root.AbsoluteSize
	-- Keep the stat cards below Roblox's own top bar buttons.
	local top = GuiService.TopbarInset.Height
	if top <= 0 then
		top = GuiService:GetGuiInset().Y
	end
	local rootScreenY = root.AbsolutePosition.Y + GuiService:GetGuiInset().Y
	local y = math.max(22, top - rootScreenY + 14)

	local k = math.min(size.X / 1280, size.Y / 720) * 0.85
	if isTouch then
		k = math.max(k, 0.62) -- keep touch targets big on small phones...
		-- ...but the right column (status 78 + buttons 230) must end above the jump button.
		k = math.min(k, (size.Y - y - JUMP_RESERVE) / 308)
	end
	k = math.clamp(k, 0.45, 3)
	uiScale = k
	for _, s in ipairs(scales) do
		s.Scale = k
	end
	if shopOpen then
		shopScale.Scale = shopFitScale()
	end
	stats.Position = UDim2.new(0, 22, 0, y)
	if isTouch then
		-- Touch: actions sit under the save pill / boosts column on the right.
		topRight.Position = UDim2.new(1, -22, 0, y)
		actions.Position = UDim2.new(1, -22, 0, y + 78 * k)
	end
end

-- Live values -------------------------------------------------------------------------
local shownCash = 0
local targetCash = 0
local lastCash: number? = nil

local function pop(label: TextLabel, size: number)
	label.TextSize = size + 6
	tween(label, 0.35, { TextSize = size }, Enum.EasingStyle.Back)
end

local rebirthArmedUntil = 0
local function refreshButtons()
	local cash = (player:GetAttribute("Cash") or 0) :: number
	local dCost = (player:GetAttribute("DropperCost") or 0) :: number
	local rCost = (player:GetAttribute("RebirthCost") or 1) :: number
	if dCost < 0 then
		buyCost.Text = "MAX"
		buyFill.Size = UDim2.fromScale(1, 1)
	else
		buyCost.Text = Format.cash(dCost)
		tween(buyFill, 0.25, { Size = UDim2.fromScale(math.clamp(cash / math.max(dCost, 1), 0, 1), 1) })
	end
	local nextMult = Config.RebirthMultiplier(((player:GetAttribute("Rebirths") or 0) :: number) + 1)
	if os.clock() < rebirthArmedUntil then
		rebTitle.Text = "TAP TO CONFIRM"
		rebCost.Text = "Resets cash & droppers"
	else
		rebTitle.Text = "REBIRTH"
		rebCost.Text = Format.cash(rCost) .. "  ->  " .. Format.mult(nextMult)
	end
	tween(rebFill, 0.25, { Size = UDim2.fromScale(math.clamp(cash / math.max(rCost, 1), 0, 1), 1) })
end

local function onCash()
	local cash = (player:GetAttribute("Cash") or 0) :: number
	targetCash = cash
	if lastCash then
		local delta = cash - lastCash
		if delta >= 1 then
			flyout("+" .. Format.cash(delta), THEME.Cash)
		elseif delta <= -1 then
			flyout("-" .. Format.cash(-delta), THEME.Red)
		end
	end
	lastCash = cash
	refreshButtons()
end

local function onMultiplier()
	local m = (player:GetAttribute("Multiplier") or 1) :: number
	local r = (player:GetAttribute("RebirthMultiplier") or 1) :: number
	local before = multValue.Text
	multValue.Text = Format.mult(m)
	local parts = {}
	if r > 1 then
		table.insert(parts, "rebirth " .. Format.mult(r))
	end
	local passMult = m / math.max(r, 0.001)
	if passMult > 1.001 then
		table.insert(parts, "passes " .. Format.mult(math.floor(passMult * 100 + 0.5) / 100))
	end
	multDetail.Text = table.concat(parts, "\n")
	if before ~= multValue.Text then
		pop(multValue, 27)
	end
end

local function onRebirths()
	local before = rebValue.Text
	rebValue.Text = tostring(player:GetAttribute("Rebirths") or 0)
	if before ~= rebValue.Text then
		pop(rebValue, 27)
	end
	refreshButtons()
end

local function onSave()
	local mode = player:GetAttribute("SaveMode")
	saveText.Text = (player:GetAttribute("SaveStatus") or "Loading profile...") :: string
	saveDot.BackgroundColor3 = if mode == "DataStore" then THEME.Cash else THEME.Gold
end

local passKnown: { [string]: boolean } = {}
local function onPass(key: string)
	local owned = player:GetAttribute("Pass_" .. key) == true
	local was = passKnown[key]
	passKnown[key] = owned
	local justBought = was == false and owned
	setOwnedVisual(key, owned, justBought)
	local chip = boostChips[key]
	if chip then
		chip.Visible = owned
		if justBought then
			local s = chip:FindFirstChildOfClass("UIScale") :: UIScale
			s.Scale = 0.4
			tween(s, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	if justBought then
		for _, pass in ipairs(Config.Passes) do
			if pass.Key == key then
				toast(string.upper(pass.Name) .. " UNLOCKED", pass.Color)
			end
		end
	end
	onMultiplier()
end

player:GetAttributeChangedSignal("Cash"):Connect(onCash)
player:GetAttributeChangedSignal("DropperCost"):Connect(refreshButtons)
player:GetAttributeChangedSignal("RebirthCost"):Connect(refreshButtons)
player:GetAttributeChangedSignal("Multiplier"):Connect(onMultiplier)
player:GetAttributeChangedSignal("RebirthMultiplier"):Connect(onMultiplier)
player:GetAttributeChangedSignal("Rebirths"):Connect(onRebirths)
player:GetAttributeChangedSignal("SaveStatus"):Connect(onSave)
player:GetAttributeChangedSignal("SaveMode"):Connect(onSave)
player:GetAttributeChangedSignal("HasPlot"):Connect(function()
	if player:GetAttribute("HasPlot") == false then
		toast("All plots are taken in this server", THEME.Red)
	end
end)
for _, pass in ipairs(Config.Passes) do
	passKnown[pass.Key] = player:GetAttribute("Pass_" .. pass.Key) == true
	player:GetAttributeChangedSignal("Pass_" .. pass.Key):Connect(function()
		onPass(pass.Key)
	end)
end

-- Rolling cash counter
RunService.RenderStepped:Connect(function(dt)
	if math.abs(targetCash - shownCash) < 1 then
		shownCash = targetCash
	else
		shownCash += (targetCash - shownCash) * math.min(1, dt * 9)
	end
	cashValue.Text = Format.cash(shownCash)
end)

-- Buttons -----------------------------------------------------------------------------
buyBtn.Activated:Connect(function()
	ripple(buyBtn, buyPress)
	Action:FireServer("BuyDropper")
end)
rebBtn.Activated:Connect(function()
	ripple(rebBtn, rebPress)
	-- Rebirth wipes cash and droppers, so the button asks for a second tap.
	if os.clock() < rebirthArmedUntil then
		rebirthArmedUntil = 0
		refreshButtons()
		Action:FireServer("Rebirth")
		return
	end
	local cash = (player:GetAttribute("Cash") or 0) :: number
	local rCost = (player:GetAttribute("RebirthCost") or 1) :: number
	if cash < rCost then
		toast("Rebirth needs " .. Format.cash(rCost), THEME.Red)
		return
	end
	rebirthArmedUntil = os.clock() + 3
	refreshButtons()
	task.delay(3.05, refreshButtons)
end)
shopBtn.Activated:Connect(function()
	ripple(shopBtn, shopPress)
	setShop(not shopOpen)
end)
closeBtn.Activated:Connect(function()
	setShop(false)
end)
shade.Activated:Connect(function()
	setShop(false) -- tap outside the panel closes it
end)

-- Messages from the server
Fx.OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "Denied" then
		toast(tostring(a), THEME.Red)
	elseif kind == "ProductGranted" then
		toast("THANK YOU! " .. string.upper(tostring(a)) .. " RECEIVED", THEME.Cash)
	elseif kind == "RebirthDone" and typeof(a) == "Instance" and a:GetAttribute("OwnerUserId") == player.UserId then
		toast("REBIRTH " .. tostring(b) .. "  ·  PERMANENT " .. Format.mult(c), THEME.Purple)
	end
end)

root:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)
root:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateScale)
updateScale()
onCash()
onMultiplier()
onRebirths()
onSave()
for _, pass in ipairs(Config.Passes) do
	onPass(pass.Key)
end
