--!strict
-- Plays the carry animations on the local character. Animations played by the owner's
-- Animator replicate to other players automatically.
--   * carrying + moving  -> CarryWalk  (replaces the normal walk: higher priority, all joints)
--   * carrying + still   -> CarryIdle
--   * pick-up / restock accepted by the server -> PickUp / PlaceBox once (Action2)
-- State comes from events (CarryingBox attribute, Humanoid.Running), no per-frame loop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local AnimationConfig = require(ReplicatedStorage.Shared.AnimationConfig)
local InteractionController = require(script.Parent.InteractionController)

local ONE_SHOT_BY_INTERACTION = {
	ProductBox = "PickUp",
	Shelf = "PlaceBox",
}

local CharacterAnimationController = {}

local player = Players.LocalPlayer
local tracks: { [string]: AnimationTrack } = {}
local characterConnections: { RBXScriptConnection } = {}
local moving = false
local warnedMissing: { [string]: boolean } = {}
local previewIds: { [string]: string } = {}

-- Published ID, or (Studio only) a temporary ID registered from AnimationSources.
local function resolveAnimationId(name: string): string?
	local definition = AnimationConfig.Animations[name]
	if definition.AnimationId ~= "" then
		return definition.AnimationId
	end
	if RunService:IsStudio() then
		if previewIds[name] then
			return previewIds[name]
		end
		local folder = ReplicatedStorage:FindFirstChild(AnimationConfig.StudioPreviewFolder)
		local sequence = folder and folder:FindFirstChild(name)
		if sequence and sequence:IsA("KeyframeSequence") then
			local ok, id = pcall(KeyframeSequenceProvider.RegisterKeyframeSequence, KeyframeSequenceProvider, sequence)
			if ok then
				previewIds[name] = id
				return id
			end
		end
	end
	if not warnedMissing[name] then
		warnedMissing[name] = true
		warn(`[CharacterAnimationController] animation "{name}" has no published AnimationId; skipped`)
	end
	return nil
end

local function stop(name: string)
	local track = tracks[name]
	if track and track.IsPlaying then
		track:Stop(AnimationConfig.Animations[name].FadeTime)
	end
end

local function play(name: string)
	local track = tracks[name]
	if track and not track.IsPlaying then
		track:Play(AnimationConfig.Animations[name].FadeTime)
	end
end

local function refreshCarryLoop()
	if player:GetAttribute("CarryingBox") == true then
		if moving then
			stop("CarryIdle")
			play("CarryWalk")
		else
			stop("CarryWalk")
			play("CarryIdle")
		end
	else
		stop("CarryIdle")
		stop("CarryWalk")
	end
end

local function onCharacterAdded(character: Model)
	for _, connection in characterConnections do
		connection:Disconnect()
	end
	table.clear(characterConnections)
	table.clear(tracks)
	moving = false

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	local animator = humanoid:WaitForChild("Animator", 10)
	if not animator or not animator:IsA("Animator") then
		return
	end

	for name, definition in AnimationConfig.Animations do
		local id = resolveAnimationId(name)
		if id then
			local animation = Instance.new("Animation")
			animation.Name = name
			animation.AnimationId = id
			local track = animator:LoadAnimation(animation)
			track.Priority = definition.Priority
			track.Looped = definition.Looped
			tracks[name] = track
		end
	end

	table.insert(characterConnections, humanoid.Running:Connect(function(speed: number)
		local nowMoving = speed > AnimationConfig.WalkSpeedThreshold
		if nowMoving ~= moving then
			moving = nowMoving
			refreshCarryLoop()
		end
	end))
	refreshCarryLoop()
end

function CharacterAnimationController.init()
	player:GetAttributeChangedSignal("CarryingBox"):Connect(refreshCarryLoop)
	InteractionController.Succeeded:Connect(function(typeName: string)
		local oneShot = ONE_SHOT_BY_INTERACTION[typeName]
		local track = oneShot and tracks[oneShot]
		if track then
			track:Play(AnimationConfig.Animations[oneShot].FadeTime)
		end
	end)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

return CharacterAnimationController
