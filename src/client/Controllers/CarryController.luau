--!strict
-- While the player carries a box (player attribute CarryingBox, set by the server):
-- binds the drop action, shows a small "carrying" label and brings the camera closer.
-- Only sends the intent "drop"; the server decides where the box lands.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local InteractionConfig = require(ReplicatedStorage.Shared.InteractionConfig)
local ProductConfig = require(ReplicatedStorage.Shared.ProductConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local FeedbackToast = require(script.Parent.Parent.UI.FeedbackToast)

local ACTION_NAME = "DropCarried"

local CarryController = {}

local player = Players.LocalPlayer
local dropRemote: RemoteFunction
local label: TextLabel
local requestPending = false

local function sendDrop()
	if requestPending then
		return
	end
	requestPending = true
	local ok, result = pcall(dropRemote.InvokeServer, dropRemote)
	requestPending = false
	if not ok or typeof(result) ~= "table" then
		FeedbackToast.show(InteractionConfig.Messages.NoResponse, false)
	elseif typeof(result.message) == "string" and not result.ok then
		FeedbackToast.show(result.message, false)
	end
end

local function onAction(_name: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		task.spawn(sendDrop)
	end
	return Enum.ContextActionResult.Sink
end

local function buildLabel()
	local gui = Instance.new("ScreenGui")
	gui.Name = "CarryGui"
	gui.ResetOnSpawn = false
	label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -172)
	label.Size = UDim2.fromOffset(300, 34)
	label.BackgroundColor3 = Color3.fromRGB(70, 55, 45)
	label.BackgroundTransparency = 0.15
	label.TextColor3 = Color3.fromRGB(255, 250, 240)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Visible = false
	label.Parent = gui
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 10)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)
	padding.Parent = label
	gui.Parent = player:WaitForChild("PlayerGui")
end

local function refresh()
	local carrying = player:GetAttribute("CarryingBox") == true
	label.Visible = carrying
	if carrying then
		local keyName = ProductConfig.Carry.Keys.Keyboard.Name
		label.Text = `Carregando caixa  •  [{keyName}] soltar`
		ContextActionService:BindAction(
			ACTION_NAME,
			onAction,
			true,
			ProductConfig.Carry.Keys.Keyboard,
			ProductConfig.Carry.Keys.Gamepad
		)
		ContextActionService:SetTitle(ACTION_NAME, ProductConfig.Carry.TouchButtonTitle)
		player.CameraMaxZoomDistance = ProductConfig.Carry.CameraMaxZoomWhileCarrying
	else
		ContextActionService:UnbindAction(ACTION_NAME)
		player.CameraMaxZoomDistance = StarterPlayer.CameraMaxZoomDistance
	end
end

function CarryController.init()
	dropRemote = Remotes.getFunction(Remotes.Names.RequestDrop)
	buildLabel()
	player:GetAttributeChangedSignal("CarryingBox"):Connect(refresh)
	refresh()
end

return CarryController
