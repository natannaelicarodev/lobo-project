-- Client HUD: coin counter, day clock, held item and short notifications.
-- Only displays state; all rules run on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer

local TEXT_COLOR = Color3.fromRGB(80, 60, 50)
local PANEL_COLOR = Color3.fromRGB(255, 248, 235)

local menuById = {}
for _, item in Config.Menu do
	menuById[item.Id] = item
end

local gui = Instance.new("ScreenGui")
gui.Name = "BakeryHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false

local function makePanel(name: string, size: UDim2, position: UDim2, anchor: Vector2): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.AnchorPoint = anchor
	label.BackgroundColor3 = PANEL_COLOR
	label.TextColor3 = TEXT_COLOR
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = gui
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = TEXT_COLOR
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = label
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = label
	return label
end

local coinsLabel = makePanel("Coins", UDim2.fromOffset(170, 44), UDim2.fromOffset(16, 16), Vector2.zero)
coinsLabel.TextColor3 = Color3.fromRGB(170, 120, 20)

local dayLabel = makePanel("Day", UDim2.fromOffset(300, 44), UDim2.new(0.5, 0, 0, 16), Vector2.new(0.5, 0))

local heldLabel = makePanel("Held", UDim2.fromOffset(240, 40), UDim2.new(0.5, 0, 1, -110), Vector2.new(0.5, 1))

local toast = makePanel("Toast", UDim2.fromOffset(360, 44), UDim2.new(0.5, 0, 0, 72), Vector2.new(0.5, 0))
toast.Visible = false

gui.Parent = player:WaitForChild("PlayerGui")

local function refreshCoins()
	coinsLabel.Text = "Moedas: " .. tostring(player:GetAttribute("Coins") or 0)
end

local lastCoins = player:GetAttribute("Coins") or 0
local function onCoinsChanged()
	local coins = player:GetAttribute("Coins") or 0
	refreshCoins()
	if coins > lastCoins then
		coinsLabel.BackgroundColor3 = Color3.fromRGB(255, 225, 120)
		TweenService:Create(coinsLabel, TweenInfo.new(0.6), { BackgroundColor3 = PANEL_COLOR }):Play()
	end
	lastCoins = coins
end

local function refreshHeld()
	local item = menuById[player:GetAttribute("HeldItem") or ""]
	heldLabel.Visible = item ~= nil
	if item then
		heldLabel.Text = "Segurando: " .. item.DisplayName
	end
end

local function formatTime(seconds: number): string
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function refreshDay()
	local day = ReplicatedStorage:GetAttribute("DayNumber") or 0
	local timeLeft = ReplicatedStorage:GetAttribute("PhaseTimeLeft") or 0
	if day == 0 then
		dayLabel.Text = "Abrindo a padaria..."
	elseif ReplicatedStorage:GetAttribute("DayActive") then
		dayLabel.Text = "Dia " .. day .. "  |  " .. formatTime(timeLeft)
	else
		dayLabel.Text = "Fechado! Próximo dia em " .. timeLeft .. "s"
	end
end

local toastToken = 0
local function showToast(message: string)
	toastToken += 1
	local myToken = toastToken
	toast.Text = message
	toast.Visible = true
	task.delay(2, function()
		if toastToken == myToken then
			toast.Visible = false
		end
	end)
end

player:GetAttributeChangedSignal("Coins"):Connect(onCoinsChanged)
player:GetAttributeChangedSignal("HeldItem"):Connect(refreshHeld)
for _, attribute in { "DayNumber", "DayActive", "PhaseTimeLeft" } do
	ReplicatedStorage:GetAttributeChangedSignal(attribute):Connect(refreshDay)
end

local remotes = ReplicatedStorage:WaitForChild("Remotes")
remotes:WaitForChild("Notify").OnClientEvent:Connect(showToast)

refreshCoins()
refreshHeld()
refreshDay()
