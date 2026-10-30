--!strict
-- Carrying product boxes. Physics strategy:
--   * on the floor, a box is a normal unanchored assembly owned by the SERVER
--     (SetNetworkOwner(nil)), so clients can't move it;
--   * while carried, it is welded to the player's HumanoidRootPart (no collision,
--     massless) and simply follows the character;
--   * when dropped, the SERVER picks the final position (raycast to the floor in
--     front of the player, never through a wall). Clients never send positions.
-- Player attribute CarryingBox (boolean) tells the client UI what is going on.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InteractionConfig = require(ReplicatedStorage.Shared.InteractionConfig)
local ProductConfig = require(ReplicatedStorage.Shared.ProductConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ProductService = require(script.Parent.ProductService)

local CARRY_WELD_NAME = "CarryWeld"

local CarryService = {}

local carried: { [Player]: Model } = {}
local lastDropRequestAt: { [Player]: number } = {}

local function getRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function setBoxCarriedPhysics(box: Model, isCarried: boolean)
	for _, part in box:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanQuery = not isCarried
			if part == ProductService.getCrate(box) then
				part.CanCollide = not isCarried
				part.Massless = isCarried
			end
		end
	end
end

function CarryService.getCarried(player: Player): Model?
	return carried[player]
end

-- Called by the ProductBox interaction (distance/state already checked by InteractionService).
function CarryService.pickUp(player: Player, box: Model): (boolean, string?)
	if carried[player] then
		return false, "Suas mãos já estão ocupadas. Solte a caixa primeiro."
	end
	if box:GetAttribute("CarriedBy") ~= nil then
		return false, "Alguém já está carregando essa caixa."
	end
	local root = getRoot(player)
	if not root then
		return false, nil
	end

	-- not interactive while carried: nobody else can target it
	CollectionService:RemoveTag(box, InteractionConfig.Tag)
	box:SetAttribute("CarriedBy", player.UserId)
	setBoxCarriedPhysics(box, true)

	local crate = ProductService.getCrate(box)
	local holdPart = player.Character and player.Character:FindFirstChild(ProductConfig.Carry.HoldPart)
	if holdPart and holdPart:IsA("BasePart") then
		-- fixed offset from the hand (a Weld, not a WeldConstraint): wherever the
		-- animation puts the hand, the box follows
		local weld = Instance.new("Weld")
		weld.Name = CARRY_WELD_NAME
		weld.Part0 = holdPart
		weld.Part1 = crate
		weld.C0 = ProductConfig.Carry.HoldOffsetFromPart
		weld.Parent = crate
	else
		box:PivotTo(root.CFrame * ProductConfig.Carry.HoldOffset)
		local weld = Instance.new("WeldConstraint")
		weld.Name = CARRY_WELD_NAME
		weld.Part0 = root
		weld.Part1 = crate
		weld.Parent = crate
	end

	carried[player] = box
	player:SetAttribute("CarryingBox", true)
	return true, "Caixa na mão! Leve até a prateleira."
end

-- Detaches the box from the player without placing it (used when the box is emptied).
function CarryService.release(player: Player): Model?
	local box = carried[player]
	if not box then
		return nil
	end
	carried[player] = nil
	player:SetAttribute("CarryingBox", false)
	local crate = box:FindFirstChild("Crate")
	local weld = crate and crate:FindFirstChild(CARRY_WELD_NAME)
	if weld then
		weld:Destroy()
	end
	box:SetAttribute("CarriedBy", nil)
	return box
end

local function isInteractive(instance: Instance): boolean
	local current: Instance? = instance
	while current and current ~= workspace do
		if CollectionService:HasTag(current, InteractionConfig.Tag) then
			return true
		end
		current = current.Parent
	end
	return false
end

local function ignoreList(player: Player, box: Model): { Instance }
	local list: { Instance } = { box }
	if player.Character then
		table.insert(list, player.Character)
	end
	return list
end

-- Checks one candidate spot and returns the box CFrame if it is valid:
--   * a flat floor below, found from the player's own height (never above a ceiling)
--     and not an interactive object (shelf, other box...);
--   * a clear line from the player to the spot (no dropping through walls);
--   * the box volume touches nothing solid (shelves, walls, other players, boxes).
local function tryDropSpot(root: BasePart, direction: Vector3, distance: number, ignore: { Instance }, boxSize: Vector3): CFrame?
	local carry = ProductConfig.Carry
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignore
	rayParams.RespectCanCollide = true

	local target = root.Position + direction * distance
	local floorHit = workspace:Raycast(target, Vector3.new(0, -carry.DropMaxStepDown, 0), rayParams)
	if not floorHit or floorHit.Normal.Y < carry.DropMinFloorNormalY or isInteractive(floorHit.Instance) then
		return nil
	end

	local center = Vector3.new(target.X, floorHit.Position.Y + boxSize.Y / 2 + 0.05, target.Z)
	if workspace:Raycast(root.Position, center - root.Position, rayParams) then
		return nil
	end

	local cframe = CFrame.lookAt(center, center + direction)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = ignore
	overlapParams.RespectCanCollide = true
	local checkSize = boxSize - Vector3.one * carry.DropOverlapShrink
	if #workspace:GetPartBoundsInBox(cframe, checkSize, overlapParams) > 0 then
		return nil
	end
	return cframe
end

-- Server-chosen landing spot: tries the configured spots in front of the player in
-- order. Returns nil when none is free; the client never sends a position.
local function findDropCFrame(player: Player, box: Model): CFrame?
	local root = getRoot(player)
	if not root then
		return nil
	end
	local forward = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	forward = if forward.Magnitude > 0.01 then forward.Unit else Vector3.zAxis
	local ignore = ignoreList(player, box)
	local boxSize = ProductService.getCrate(box).Size
	for _, distance in ProductConfig.Carry.DropDistances do
		for _, angle in ProductConfig.Carry.DropAngles do
			local direction = CFrame.Angles(0, math.rad(angle), 0):VectorToWorldSpace(forward)
			local spot = tryDropSpot(root, direction, distance, ignore, boxSize)
			if spot then
				return spot
			end
		end
	end
	return nil
end

-- Last resort when the drop can't be refused (death, respawn, leaving): the floor
-- where the character stood, since the body is no longer in the way.
local function fallbackDropCFrame(player: Player, box: Model): CFrame
	local crate = ProductService.getCrate(box)
	local root = getRoot(player)
	if not root then
		return crate.CFrame
	end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignoreList(player, box)
	rayParams.RespectCanCollide = true
	local floorHit = workspace:Raycast(root.Position, Vector3.new(0, -ProductConfig.Carry.DropMaxStepDown, 0), rayParams)
	local floorY = if floorHit then floorHit.Position.Y else root.Position.Y - 3
	return CFrame.new(root.Position.X, floorY + crate.Size.Y / 2 + 0.05, root.Position.Z)
end

-- force = true when the player can't keep the box (death, respawn, leaving).
function CarryService.drop(player: Player, force: boolean?): (boolean, string?)
	local box = carried[player]
	if not box or not box.Parent then
		carried[player] = nil
		player:SetAttribute("CarryingBox", false)
		return false, "Você não está carregando nada."
	end
	local landing = findDropCFrame(player, box)
	if not landing then
		if not force then
			return false, "Sem espaço para soltar aqui. Procure um lugar livre no chão."
		end
		landing = fallbackDropCFrame(player, box)
	end
	CarryService.release(player)
	setBoxCarriedPhysics(box, false)
	box:PivotTo(landing)
	CollectionService:AddTag(box, InteractionConfig.Tag)
	ProductService.setServerOwned(box)
	return true, "Caixa no chão."
end

local function handleDropRequest(player: Player): { ok: boolean, code: string, message: string? }
	local now = os.clock()
	local last = lastDropRequestAt[player]
	if last and now - last < ProductConfig.Carry.MinRequestIntervalSeconds then
		return { ok = false, code = "TooFast", message = InteractionConfig.Messages.TooFast }
	end
	lastDropRequestAt[player] = now
	local ok, message = CarryService.drop(player)
	return { ok = ok, code = if ok then "Ok" else "Rejected", message = message }
end

function CarryService.init()
	Remotes.getFunction(Remotes.Names.RequestDrop).OnServerInvoke = handleDropRequest

	local function onPlayerAdded(player: Player)
		player:SetAttribute("CarryingBox", false)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid", 5)
			if humanoid and humanoid:IsA("Humanoid") then
				-- dying while carrying drops the box where the character was
				humanoid.Died:Connect(function()
					if carried[player] then
						CarryService.drop(player, true)
					end
				end)
			end
		end)
		-- respawn without dying (e.g. LoadCharacter) must not take the box along
		player.CharacterRemoving:Connect(function()
			if carried[player] then
				CarryService.drop(player, true)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		if carried[player] then
			CarryService.drop(player, true)
		end
		carried[player] = nil
		lastDropRequestAt[player] = nil
	end)
end

return CarryService
