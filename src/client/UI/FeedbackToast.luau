--!strict
-- Short message near the bottom of the screen: green for success, red for refusal.
-- A newer message replaces the older one; each message hides itself after a delay.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local InteractionConfig = require(game:GetService("ReplicatedStorage").Shared.InteractionConfig)

local SUCCESS_COLOR = Color3.fromRGB(70, 160, 90)
local FAILURE_COLOR = Color3.fromRGB(205, 75, 65)

local FeedbackToast = {}

local label: TextLabel
local stroke: UIStroke
local token = 0

local function build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FeedbackGui"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	label = Instance.new("TextLabel")
	label.Name = "Toast"
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -120)
	label.Size = UDim2.new(0.8, 0, 0, 44)
	label.BackgroundColor3 = Color3.fromRGB(255, 250, 240)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Visible = false
	label.Parent = gui
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 12)
	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = Vector2.new(460, 44)
	sizeLimit.Parent = label
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = label
	stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = label

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function FeedbackToast.show(message: string, success: boolean)
	token += 1
	local myToken = token
	local color = if success then SUCCESS_COLOR else FAILURE_COLOR
	label.Text = message
	label.TextColor3 = color
	stroke.Color = color
	label.Visible = true

	-- small pop so repeated messages are still noticed
	label.Rotation = if success then 0 else -2
	TweenService:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Rotation = 0 }):Play()

	task.delay(InteractionConfig.FeedbackSeconds, function()
		if token == myToken then
			label.Visible = false
		end
	end)
end

function FeedbackToast.init()
	build()
end

return FeedbackToast
