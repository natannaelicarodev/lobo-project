--!strict
-- Server authority for interactions. Clients only ask "I want to use this object";
-- the server checks the object, the player, distance, state and request rate,
-- then runs the handler registered for the object's InteractionType.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Interactable = require(ReplicatedStorage.Shared.Interactable)
local InteractionConfig = require(ReplicatedStorage.Shared.InteractionConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

export type Result = {
	ok: boolean,
	code: string,
	message: string?,
}

-- A handler must not yield: it runs while the server answers the client.
-- Returns whether the action happened and an optional message for the player.
export type Handler = {
	TypeName: string,
	interact: (player: Player, target: Instance) -> (boolean, string?),
}

local InteractionService = {}

local handlers: { [string]: Handler } = {}
local lastRequestAt: { [Player]: number } = {}
local busyTargets: { [Instance]: boolean } = {}

local function fail(code: string): Result
	return { ok = false, code = code, message = InteractionConfig.Messages[code] }
end

function InteractionService.registerHandler(handler: Handler)
	assert(InteractionConfig.Types[handler.TypeName], "Unknown InteractionType: " .. handler.TypeName)
	assert(handlers[handler.TypeName] == nil, "Handler already registered: " .. handler.TypeName)
	handlers[handler.TypeName] = handler
end

local function getLivingRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil
	end
	return root
end

local function handleRequest(player: Player, target: unknown): Result
	-- the argument comes from the client: check its type before anything else
	if typeof(target) ~= "Instance" or not Interactable.isInteractable(target) then
		return fail("Invalid")
	end

	local now = os.clock()
	local last = lastRequestAt[player]
	if last and now - last < InteractionConfig.MinRequestIntervalSeconds then
		return fail("TooFast")
	end
	lastRequestAt[player] = now

	local typeName = Interactable.getTypeName(target)
	local handler = typeName and handlers[typeName]
	if not handler then
		return fail("Invalid")
	end

	local root = getLivingRoot(player)
	if not root then
		return fail("NoCharacter")
	end

	local position = Interactable.getPosition(target)
	local limit = Interactable.getMaxDistance(target) + InteractionConfig.ServerDistanceTolerance
	if not position or (position - root.Position).Magnitude > limit then
		return fail("OutOfRange")
	end

	if not Interactable.isEnabled(target) then
		local custom = target:GetAttribute("DisabledMessage")
		return {
			ok = false,
			code = "Disabled",
			message = if typeof(custom) == "string" then custom else InteractionConfig.Messages.Disabled,
		}
	end

	if busyTargets[target] then
		return fail("Busy")
	end
	busyTargets[target] = true
	local ran, done, message = pcall(handler.interact, player, target)
	busyTargets[target] = nil

	if not ran then
		warn(`[InteractionService] {typeName} handler failed on {target:GetFullName()}: {done}`)
		return fail("Failed")
	end
	return { ok = done == true, code = if done then "Ok" else "Rejected", message = message }
end

function InteractionService.init()
	local remote = Remotes.getFunction(Remotes.Names.RequestInteraction)
	remote.OnServerInvoke = handleRequest

	Players.PlayerRemoving:Connect(function(player)
		lastRequestAt[player] = nil
	end)
end

return InteractionService
