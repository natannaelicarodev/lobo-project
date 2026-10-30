--!strict
-- Finds the nearest interactive object, shows the contextual hint and sends the
-- player's intent to the server. The client never decides the outcome: it only
-- displays what the server answers.

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Interactable = require(ReplicatedStorage.Shared.Interactable)
local InteractionConfig = require(ReplicatedStorage.Shared.InteractionConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local FeedbackToast = require(script.Parent.Parent.UI.FeedbackToast)
local InteractionHint = require(script.Parent.Parent.UI.InteractionHint)

local ACTION_NAME = "Interact"

local InteractionController = {}

-- Fires (typeName: string) after the server accepted an interaction; used for feedback
-- such as animations. Only the server's answer triggers it.
local succeeded = Instance.new("BindableEvent")
InteractionController.Succeeded = succeeded.Event

local player = Players.LocalPlayer
local requestRemote: RemoteFunction
local candidates: { [Instance]: boolean } = {}
local currentTarget: Instance? = nil
local actionBound = false
local requestPending = false

local function getLivingRoot(): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil
	end
	return root
end

-- Distance from the player to the object if it can be offered right now, otherwise nil.
local function usableDistance(instance: Instance, root: BasePart): number?
	if not candidates[instance] or not Interactable.isInteractable(instance) then
		return nil
	end
	local typeName = Interactable.getTypeName(instance)
	if not typeName then
		return nil
	end
	if InteractionConfig.Types[typeName].HideWhileCarrying and player:GetAttribute("CarryingBox") == true then
		return nil
	end
	local position = Interactable.getPosition(instance)
	local distance = position and (position - root.Position).Magnitude
	if not distance or distance > Interactable.getMaxDistance(instance) then
		return nil
	end
	return distance
end

local function isUsableFrom(instance: Instance, root: BasePart): boolean
	return usableDistance(instance, root) ~= nil
end

-- The tagged instance hit by a ray from the centre of the screen, if it is in range.
-- Works in first person (crosshair) and third person (what the camera points at).
local function findLookedAtTarget(root: BasePart): Instance?
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	local viewport = camera.ViewportSize
	local ray = camera:ViewportPointToRay(viewport.X / 2, viewport.Y / 2)
	local reach = InteractionConfig.LookRayLength + (camera.CFrame.Position - root.Position).Magnitude
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * reach, params)

	-- the tag can be on the hit part or on one of its ancestors (a Model)
	local instance: Instance? = hit and hit.Instance
	while instance and instance ~= workspace do
		if isUsableFrom(instance, root) then
			return instance
		end
		instance = instance.Parent
	end
	return nil
end

-- Priority: what the player is looking at; otherwise the nearest object in range.
local function findTarget(): Instance?
	local root = getLivingRoot()
	if not root then
		return nil
	end
	local lookedAt = findLookedAtTarget(root)
	if lookedAt then
		return lookedAt
	end
	local best: Instance? = nil
	local bestDistance = math.huge
	for instance in candidates do
		local distance = usableDistance(instance, root)
		if distance and distance < bestDistance then
			best = instance
			bestDistance = distance
		end
	end
	return best
end

local function sendRequest()
	local target = currentTarget
	if requestPending or not target then
		return
	end
	-- read before the request: the target may be gone afterwards (e.g. emptied box)
	local typeName = Interactable.getTypeName(target)
	requestPending = true
	local ok, result = pcall(requestRemote.InvokeServer, requestRemote, target)
	requestPending = false

	if not ok or typeof(result) ~= "table" then
		FeedbackToast.show(InteractionConfig.Messages.NoResponse, false)
		return
	end
	local message = result.message
	if typeof(message) == "string" and message ~= "" then
		FeedbackToast.show(message, result.ok == true)
	end
	if result.ok == true and typeName then
		succeeded:Fire(typeName)
	end
end

local function onAction(_name: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		task.spawn(sendRequest)
	end
	return Enum.ContextActionResult.Sink
end

-- The key is only bound while there is a target, so E/X stay free otherwise and the
-- touch button only appears when it can be used.
local function setTarget(target: Instance?)
	currentTarget = target
	if target then
		InteractionHint.show(target)
		if not actionBound then
			actionBound = true
			ContextActionService:BindAction(
				ACTION_NAME,
				onAction,
				true,
				InteractionConfig.Keys.Keyboard,
				InteractionConfig.Keys.Gamepad
			)
			ContextActionService:SetTitle(ACTION_NAME, InteractionConfig.TouchButtonTitle)
		end
	else
		InteractionHint.hide()
		if actionBound then
			actionBound = false
			ContextActionService:UnbindAction(ACTION_NAME)
		end
	end
end

local function trackTagged()
	for _, instance in CollectionService:GetTagged(InteractionConfig.Tag) do
		candidates[instance] = true
	end
	CollectionService:GetInstanceAddedSignal(InteractionConfig.Tag):Connect(function(instance)
		candidates[instance] = true
	end)
	CollectionService:GetInstanceRemovedSignal(InteractionConfig.Tag):Connect(function(instance)
		candidates[instance] = nil
		if instance == currentTarget then
			setTarget(nil)
		end
	end)
end

function InteractionController.init()
	requestRemote = Remotes.getFunction(Remotes.Names.RequestInteraction)
	InteractionHint.init()
	FeedbackToast.init()
	trackTagged()

	-- hide immediately on death/respawn instead of waiting for the next scan
	player.CharacterRemoving:Connect(function()
		setTarget(nil)
	end)

	-- A low-frequency scan is enough for a handful of objects and avoids per-frame work.
	task.spawn(function()
		while true do
			task.wait(InteractionConfig.ScanIntervalSeconds)
			setTarget(findTarget())
		end
	end)
end

return InteractionController
