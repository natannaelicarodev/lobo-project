--!strict
-- Contextual hint shown above the object the player can use: key + action + object.
-- A single BillboardGui is reused and re-pointed; hide() always clears the Adornee
-- so the hint can never stay stuck on the screen.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local InteractionConfig = require(game:GetService("ReplicatedStorage").Shared.InteractionConfig)
local Interactable = require(game:GetService("ReplicatedStorage").Shared.Interactable)

local TEXT_COLOR = Color3.fromRGB(70, 55, 45)
local DISABLED_COLOR = Color3.fromRGB(150, 140, 135)
local PANEL_COLOR = Color3.fromRGB(255, 250, 240)
local KEY_COLOR = Color3.fromRGB(255, 200, 80)

local InteractionHint = {}

local billboard: BillboardGui
local keyBadge: TextLabel
local actionLabel: TextLabel
local objectLabel: TextLabel
local inputConnection: RBXScriptConnection?

local function keyTextForInput(inputType: Enum.UserInputType): string?
	if inputType == Enum.UserInputType.Touch then
		return nil -- touch players use the on-screen button
	elseif inputType.Name:match("^Gamepad") then
		return (InteractionConfig.Keys.Gamepad.Name:gsub("^Button", ""))
	end
	return InteractionConfig.Keys.Keyboard.Name
end

local function refreshKey()
	local text = keyTextForInput(UserInputService:GetLastInputType())
	keyBadge.Visible = text ~= nil
	keyBadge.Text = text or ""
end

local function build()
	billboard = Instance.new("BillboardGui")
	billboard.Name = "InteractionHint"
	billboard.Size = UDim2.fromOffset(230, 56)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false
	billboard.Enabled = false

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.BackgroundTransparency = 0.05
	panel.Parent = billboard
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Color = TEXT_COLOR
	stroke.Thickness = 2
	stroke.Parent = panel

	keyBadge = Instance.new("TextLabel")
	keyBadge.Name = "Key"
	keyBadge.AnchorPoint = Vector2.new(0, 0.5)
	keyBadge.Position = UDim2.new(0, 8, 0.5, 0)
	keyBadge.Size = UDim2.fromOffset(40, 40)
	keyBadge.BackgroundColor3 = KEY_COLOR
	keyBadge.Font = Enum.Font.FredokaOne
	keyBadge.TextScaled = true
	keyBadge.TextColor3 = TEXT_COLOR
	keyBadge.Parent = panel
	Instance.new("UICorner", keyBadge).CornerRadius = UDim.new(0, 8)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = keyBadge

	actionLabel = Instance.new("TextLabel")
	actionLabel.Name = "Action"
	actionLabel.BackgroundTransparency = 1
	actionLabel.Position = UDim2.fromOffset(56, 6)
	actionLabel.Size = UDim2.new(1, -64, 0, 26)
	actionLabel.Font = Enum.Font.FredokaOne
	actionLabel.TextScaled = true
	actionLabel.TextXAlignment = Enum.TextXAlignment.Left
	actionLabel.TextColor3 = TEXT_COLOR
	actionLabel.Parent = panel

	objectLabel = Instance.new("TextLabel")
	objectLabel.Name = "Object"
	objectLabel.BackgroundTransparency = 1
	objectLabel.Position = UDim2.fromOffset(56, 32)
	objectLabel.Size = UDim2.new(1, -64, 0, 18)
	objectLabel.Font = Enum.Font.Gotham
	objectLabel.TextScaled = true
	objectLabel.TextXAlignment = Enum.TextXAlignment.Left
	objectLabel.TextColor3 = DISABLED_COLOR
	objectLabel.Parent = panel

	billboard.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Points the hint at a target, or refreshes its texts if it already points there.
function InteractionHint.show(target: Instance)
	local adornee: Instance? = target
	if target:IsA("Model") then
		adornee = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
	end
	if not adornee or not adornee:IsA("BasePart") then
		InteractionHint.hide()
		return
	end

	local enabled = Interactable.isEnabled(target)
	actionLabel.Text = Interactable.getActionText(target)
	actionLabel.TextColor3 = if enabled then TEXT_COLOR else DISABLED_COLOR
	objectLabel.Text = Interactable.getObjectText(target) .. if enabled then "" else "  •  indisponível"

	if billboard.Adornee ~= adornee then
		billboard.Adornee = adornee
		billboard.StudsOffsetWorldSpace = Vector3.new(0, adornee.Size.Y / 2 + 1.5, 0)
	end
	billboard.Enabled = true
end

function InteractionHint.hide()
	billboard.Enabled = false
	billboard.Adornee = nil
end

function InteractionHint.init()
	build()
	refreshKey()
	if inputConnection then
		inputConnection:Disconnect()
	end
	inputConnection = UserInputService.LastInputTypeChanged:Connect(refreshKey)
end

return InteractionHint
