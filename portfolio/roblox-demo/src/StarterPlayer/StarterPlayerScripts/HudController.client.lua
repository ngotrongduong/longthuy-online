-- HudController: the player's HUD (cash, multiplier, rebirths), action buttons and the shop.
-- Display only: every value comes from attributes the server sets; every button sends a
-- request the server validates. One UIScale value keeps the layout readable from a
-- phone in landscape to a 4K monitor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local Fx = Remotes:WaitForChild("Fx")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local THEME = {
	Panel = Color3.fromRGB(16, 18, 26),
	Text = Color3.fromRGB(246, 247, 252),
	Sub = Color3.fromRGB(150, 158, 180),
	Cash = Color3.fromRGB(64, 226, 146),
	Teal = Color3.fromRGB(46, 214, 170),
	Purple = Color3.fromRGB(160, 96, 255),
	Gold = Color3.fromRGB(255, 196, 64),
	Red = Color3.fromRGB(255, 92, 92),
}
local BOLD, BLACK, MEDIUM = Enum.Font.GothamBold, Enum.Font.GothamBlack, Enum.Font.GothamMedium
local ROBUX = "rbxasset://textures/ui/common/robux@3x.png"

local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do
		(o :: any)[k] = v
	end
	if o:IsA("TextLabel") or o:IsA("TextButton") then
		if props.BackgroundTransparency == nil then
			(o :: any).BackgroundTransparency = 1
		end
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

-- Root ------------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "HUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
}, playerGui)
-- Root fills the screen. (The recording director may shrink it to a 16:9 frame.)
local root = new("Frame", { Name = "Root", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, gui)

local scales: { UIScale } = {}
local function scaled(o: Instance)
	table.insert(scales, new("UIScale", {}, o))
end
local function updateScale()
	local size = root.AbsoluteSize
	local k = math.min(size.X / 1280, size.Y / 720) * 0.85
	if UserInputService.TouchEnabled then
		k = math.max(k, 0.72) -- keep touch targets big on small phones
	end
	k = math.clamp(k, 0.6, 3)
	for _, s in ipairs(scales) do
		s.Scale = k
	end
	-- keep the stat cards below Roblox's own top bar buttons
	local stats = root:FindFirstChild("Stats") :: Frame?
	if stats then
		local top = GuiService.TopbarInset.Height
		if top <= 0 then
			top = GuiService:GetGuiInset().Y
		end
		-- AbsolutePosition is measured below the inset; convert to screen space first
		local rootScreenY = root.AbsolutePosition.Y + GuiService:GetGuiInset().Y
		stats.Position = UDim2.new(0, 22, 0, math.max(22, top - rootScreenY + 14))
	end
end

-- Stat cards (top-left) ----------------------------------------------------------
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
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)),
	}, icon)
	new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = glyph,
		Font = BLACK,
		TextSize = 22,
		TextColor3 = Color3.fromRGB(18, 20, 28),
	}, icon)
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
	return card, value, icon
end

local cashCard, cashValue = statCard(1, THEME.Cash, "$", "CASH")
local multCard, multValue = statCard(2, THEME.Purple, "x", "MULTIPLIER")
local rebCard, rebValue = statCard(3, THEME.Gold, "R", "REBIRTHS")
local multDetail = new("TextLabel", {
	Name = "Detail",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 11),
	Size = UDim2.fromOffset(120, 14),
	Text = "",
	Font = BOLD,
	TextSize = 11,
	TextColor3 = THEME.Purple,
	TextXAlignment = Enum.TextXAlignment.Right,
}, multCard)

-- Status + boosts (top-right) ---------------------------------------------------
local topRight = new("Frame", {
	Name = "TopRight",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -22, 0, 22),
	Size = UDim2.fromOffset(420, 90),
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
local saveDot = new("Frame", {
	Size = UDim2.fromOffset(10, 10),
	Position = UDim2.new(0, -22, 0.5, -5),
	BackgroundColor3 = THEME.Gold,
}, savePill)
corner(saveDot, 5)
local saveText = new("TextLabel", {
	Size = UDim2.fromOffset(0, 32),
	AutomaticSize = Enum.AutomaticSize.X,
	Text = "Loading profile...",
	Font = BOLD,
	TextSize = 13,
	TextColor3 = THEME.Text,
}, savePill)

local boosts = new("Frame", {
	Name = "Boosts",
	Size = UDim2.fromOffset(420, 30),
	BackgroundTransparency = 1,
	LayoutOrder = 2,
}, topRight)
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
		Text = string.upper(pass.Name) .. " ACTIVE",
		Font = BLACK,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(18, 20, 28),
	}, chip)
	new("UIScale", {}, chip) -- local scale for the pop-in (the parent carries the screen scale)
	boostChips[pass.Key] = chip
end

-- Action buttons (bottom-right) ------------------------------------------------
local actions = new("Frame", {
	Name = "Actions",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -22, 1, -22),
	Size = UDim2.fromOffset(262, 3 * 70 + 2 * 10),
	BackgroundTransparency = 1,
}, root)
scaled(actions)
new("UIListLayout", {
	Padding = UDim.new(0, 10),
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
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
	local fill = new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.78,
	}, b)
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
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(175, 175, 175)),
	}, badge)
	local press = new("UIScale", {}, b)
	return b, cost, fill, badge, press
end

local buyBtn, buyCost, buyFill, buyBadge, buyPress = actionButton(1, "BuyDropper", THEME.Teal, "BUY DROPPER")
local rebBtn, rebCost, rebFill, rebBadge, rebPress = actionButton(2, "Rebirth", THEME.Purple, "REBIRTH")
local shopBtn, shopCost, _, shopBadge, shopPress = actionButton(3, "Shop", THEME.Gold, "SHOP")
shopCost.Text = "Game passes"
new("TextLabel", { Size = UDim2.fromScale(1, 1), Text = "+", Font = BLACK, TextSize = 30, TextColor3 = Color3.fromRGB(18, 20, 28) }, buyBadge)
new("TextLabel", { Size = UDim2.fromScale(1, 1), Text = "R", Font = BLACK, TextSize = 24, TextColor3 = Color3.fromRGB(18, 20, 28) }, rebBadge)
new("ImageLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(26, 26),
	BackgroundTransparency = 1,
	Image = ROBUX,
	ImageColor3 = Color3.fromRGB(18, 20, 28),
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

-- Toasts (top-centre) -----------------------------------------------------------
local toastHolder = new("Frame", {
	Name = "Toasts",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 22),
	Size = UDim2.fromOffset(520, 200),
	BackgroundTransparency = 1,
}, root)
scaled(toastHolder)
new("UIListLayout", {
	Padding = UDim.new(0, 8),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, toastHolder)
local toastCount = 0
local function toast(text: string, color: Color3)
	toastCount += 1
	local t = new("Frame", {
		Size = UDim2.fromOffset(0, 42),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.08,
		LayoutOrder = toastCount,
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
	}, t)
	local s = new("UIScale", { Scale = 0.6 }, t)
	tween(s, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(2.6, function()
		tween(t, 0.35, { BackgroundTransparency = 1 })
		tween(label, 0.35, { TextTransparency = 1 })
		tween(st, 0.35, { Transparency = 1 })
		task.wait(0.4)
		t:Destroy()
	end)
end

-- Floating numbers next to the cash card -------------------------------------------
local function flyout(text: string, color: Color3)
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
	tween(l, 1.1, { Position = UDim2.new(1, 22, 0.5, if color == THEME.Red then 26 else -26), TextTransparency = 1, TextStrokeTransparency = 1 }, Enum.EasingStyle.Quad)
	task.delay(1.15, function()
		l:Destroy()
	end)
end

-- Shop ------------------------------------------------------------------------
local blur = Lighting:FindFirstChild("ShopBlur") or new("BlurEffect", { Name = "ShopBlur", Size = 0 }, Lighting)
local shade = new("Frame", {
	Name = "Shade",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 20,
}, root)
local shop = new("Frame", {
	Name = "Shop",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(812, 452),
	BackgroundColor3 = Color3.fromRGB(14, 16, 24),
	BackgroundTransparency = 0.03,
	Visible = false,
	ZIndex = 21,
}, root)
corner(shop, 26)
stroke(shop, THEME.Gold, 0.55, 2)
local shopScale = new("UIScale", {}, shop)
new("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 215)),
}, shop)
new("TextLabel", {
	Position = UDim2.fromOffset(34, 24),
	Size = UDim2.fromOffset(400, 38),
	Text = "SHOP",
	Font = BLACK,
	TextSize = 36,
	TextColor3 = THEME.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 22,
}, shop)
new("TextLabel", {
	Position = UDim2.fromOffset(34, 64),
	Size = UDim2.fromOffset(600, 20),
	Text = "Game passes  ·  ownership checked and applied on the server",
	Font = MEDIUM,
	TextSize = 15,
	TextColor3 = THEME.Sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 22,
}, shop)
local closeBtn = new("TextButton", {
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
	Position = UDim2.fromOffset(34, 108),
	Size = UDim2.fromOffset(744, 314),
	BackgroundTransparency = 1,
	ZIndex = 22,
}, shop)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 18),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, cardRow)

type PassCard = { card: Frame, buy: TextButton, price: TextLabel, icon: ImageLabel, check: Frame, stroke: UIStroke, scale: UIScale }
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

for i, pass in ipairs(Config.Passes) do
	local card = new("Frame", {
		Name = pass.Key,
		Size = UDim2.fromOffset(236, 314),
		BackgroundColor3 = Color3.fromRGB(26, 29, 41),
		LayoutOrder = i,
		ZIndex = 22,
	}, cardRow)
	corner(card, 20)
	local st = stroke(card, pass.Color, 0.65, 2)
	local cardScale = new("UIScale", {}, card)
	local art = new("Frame", {
		Position = UDim2.fromOffset(14, 14),
		Size = UDim2.fromOffset(208, 124),
		BackgroundColor3 = pass.Color,
		ZIndex = 23,
	}, card)
	corner(art, 16)
	new("UIGradient", {
		Rotation = 120,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(120, 120, 135)),
	}, art)
	new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = pass.Icon,
		Font = BLACK,
		TextSize = 58,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.75,
		ZIndex = 24,
	}, art)
	new("TextLabel", {
		Position = UDim2.fromOffset(16, 150),
		Size = UDim2.fromOffset(204, 26),
		Text = pass.Name,
		Font = BLACK,
		TextSize = 23,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 23,
	}, card)
	new("TextLabel", {
		Position = UDim2.fromOffset(16, 180),
		Size = UDim2.fromOffset(204, 44),
		Text = pass.Blurb,
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
		BackgroundColor3 = pass.Color,
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
		ImageColor3 = Color3.fromRGB(18, 20, 28),
		ZIndex = 24,
	}, buy)
	local price = new("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.5, -16, 0.5, 0),
		Size = UDim2.fromOffset(80, 30),
		Text = tostring(pass.Price),
		Font = BLACK,
		TextSize = 23,
		TextColor3 = Color3.fromRGB(18, 20, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 24,
	}, buy)
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
	buy.Activated:Connect(function()
		Action:FireServer("PromptPass", pass.Key)
	end)
	passCards[pass.Key] = { card = card, buy = buy, price = price, icon = icon, check = check, stroke = st, scale = cardScale }
end

local shopOpen = false
local function setShop(open: boolean)
	if open == shopOpen then
		return
	end
	shopOpen = open
	local k = scales[1] and scales[1].Scale or 1
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

-- Live values -----------------------------------------------------------------
local shownCash = 0
local targetCash = 0
local lastCash: number? = nil

local function pop(label: TextLabel, size: number)
	label.TextSize = size + 6
	tween(label, 0.35, { TextSize = size }, Enum.EasingStyle.Back)
end

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
	rebCost.Text = Format.cash(rCost) .. "  ->  " .. Format.mult(Config.RebirthMultiplier(((player:GetAttribute("Rebirths") or 0) :: number) + 1))
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
	if player:GetAttribute("Pass_DoubleCash") then
		table.insert(parts, "pass x2")
	end
	multDetail.Text = table.concat(parts, " · ")
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
	local chip = boostChips[key]
	local was = passKnown[key]
	passKnown[key] = owned
	setOwnedVisual(key, owned, was == false and owned)
	if chip then
		chip.Visible = owned
		if owned and was == false then
			local s = chip:FindFirstChildOfClass("UIScale") :: UIScale
			local k = s.Scale
			s.Scale = k * 0.4
			tween(s, 0.5, { Scale = k }, Enum.EasingStyle.Back)
		end
	end
	if owned and was == false then
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

-- Buttons ---------------------------------------------------------------------
local handlers = {
	BuyDropper = function()
		ripple(buyBtn, buyPress)
		Action:FireServer("BuyDropper")
	end,
	Rebirth = function()
		ripple(rebBtn, rebPress)
		Action:FireServer("Rebirth")
	end,
	Shop = function()
		ripple(shopBtn, shopPress)
		setShop(not shopOpen)
	end,
	CloseShop = function()
		setShop(false)
	end,
}
buyBtn.Activated:Connect(handlers.BuyDropper)
rebBtn.Activated:Connect(handlers.Rebirth)
shopBtn.Activated:Connect(handlers.Shop)
closeBtn.Activated:Connect(handlers.CloseShop)

-- Server feedback
Fx.OnClientEvent:Connect(function(kind, a, b)
	if kind == "Denied" then
		toast(tostring(a), THEME.Red)
	elseif kind == "RebirthDone" then
		toast("REBIRTH " .. tostring(a) .. "  ·  PERMANENT " .. Format.mult(b), THEME.Purple)
	end
end)

-- A small API for the recording director (same handlers a finger or mouse would use).
local api = Instance.new("BindableFunction")
api.Name = "HudApi"
api.OnInvoke = function(command: string, arg: any)
	if command == "Press" and handlers[arg] then
		handlers[arg]()
	elseif command == "Shop" then
		setShop(arg == true)
	elseif command == "HoverPass" then
		local pc = passCards[arg]
		if pc then
			tween(pc.scale, 0.25, { Scale = 1.04 }, Enum.EasingStyle.Back)
			tween(pc.stroke, 0.25, { Transparency = 0.05 })
		end
	elseif command == "PulseActions" then
		for _, pair in ipairs({ { buyBtn, buyPress }, { rebBtn, rebPress }, { shopBtn, shopPress } }) do
			ripple(pair[1], pair[2])
			task.wait(0.18)
		end
	elseif command == "Root" then
		return root
	end
	return nil
end
api.Parent = gui

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
