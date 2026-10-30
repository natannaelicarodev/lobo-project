--!strict
-- Makes sure every spawned character looks like the wolf in a sheep costume.
-- The main look is a custom rigged model installed in Studio as
-- StarterPlayer.StarterCharacter (attribute CharacterModel). When that model is
-- present this service does nothing. The primitive costume below is only a
-- FALLBACK for places without the model (e.g. a fresh `rojo build`).
-- StarterPlayer.LoadCharacterAppearance is off in default.project.json.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterConfig = require(ReplicatedStorage.Shared.CharacterConfig)

local CharacterService = {}

local COSTUME_NAME = "SheepCostume"

local function paintWolfBody(character: Model)
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if not bodyColors then
		bodyColors = Instance.new("BodyColors")
		bodyColors.Parent = character
	end
	local fur = CharacterConfig.WolfFurColor
	local colors = bodyColors :: BodyColors
	colors.HeadColor3 = fur
	colors.TorsoColor3 = fur
	colors.LeftArmColor3 = fur
	colors.RightArmColor3 = fur
	colors.LeftLegColor3 = fur
	colors.RightLegColor3 = fur
end

local function makePiece(piece: CharacterConfig.CostumePiece, attachTo: BasePart): BasePart
	local part: BasePart
	if piece.Shape == "Wedge" then
		part = Instance.new("WedgePart")
	else
		part = Instance.new("Part")
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
	end
	part.Name = piece.Name
	part.Size = piece.Size
	part.Color = piece.Color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = true
	part.CFrame = attachTo.CFrame * piece.Offset

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = attachTo
	weld.Part1 = part
	weld.Parent = part
	return part
end

-- Waits until the character has one of the given children. Needed for the torso:
-- Humanoid.RigType is not reliable yet when CharacterAdded fires.
local function waitForAnyChild(parent: Instance, names: { string }, timeout: number): Instance?
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		for _, name in names do
			local child = parent:FindFirstChild(name)
			if child then
				return child
			end
		end
		task.wait(0.1)
	end
	return nil
end

local function dressCharacter(character: Model)
	if character:GetAttribute(CharacterConfig.CustomModelAttribute) ~= nil then
		return -- already the custom wolf model
	end
	local timeout = CharacterConfig.BodyPartTimeoutSeconds
	local head = character:WaitForChild("Head", timeout)
	local torso = waitForAnyChild(character, { "UpperTorso", "Torso" }, timeout)
	if not head or not head:IsA("BasePart") or not torso or not torso:IsA("BasePart") then
		warn(`[CharacterService] {character.Name}: body parts not found, costume skipped`)
		return
	end
	-- Note: CharacterAdded fires before the character is parented to Workspace, so
	-- Parent is nil here. Building the costume now is fine; it is destroyed with the
	-- character if the player respawns or leaves.

	local old = character:FindFirstChild(COSTUME_NAME)
	if old then
		old:Destroy()
	end

	paintWolfBody(character)

	local costume = Instance.new("Model")
	costume.Name = COSTUME_NAME
	for _, piece in CharacterConfig.Costume do
		local attachTo = if piece.AttachTo == "Head" then head else torso
		makePiece(piece, attachTo :: BasePart).Parent = costume
	end
	costume.Parent = character
end

function CharacterService.init()
	local function onPlayerAdded(player: Player)
		-- the connection dies with the Player instance, nothing to clean up by hand
		player.CharacterAdded:Connect(dressCharacter)
		if player.Character then
			task.spawn(dressCharacter, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return CharacterService
