--!strict
-- Look of the player character: a wolf wearing a sheep costume.
-- The real look is the custom model StarterPlayer.StarterCharacter (made in Studio).
-- The Costume list below is only the FALLBACK built from basic parts and the
-- built-in sphere mesh (no asset IDs); only CharacterService reads this.

local CharacterConfig = {}

-- Attribute set on StarterPlayer.StarterCharacter; when present, no fallback costume.
CharacterConfig.CustomModelAttribute = "CharacterModel"

CharacterConfig.WolfFurColor = Color3.fromRGB(120, 120, 130)

local WOOL = Color3.fromRGB(246, 244, 236)
local EAR_INSIDE = Color3.fromRGB(240, 205, 205)
local WOLF_DARK = Color3.fromRGB(70, 70, 80)

export type CostumePiece = {
	Name: string,
	AttachTo: "Head" | "Torso", -- Torso = UpperTorso (R15) or Torso (R6)
	Shape: "Sphere" | "Wedge",
	Size: Vector3,
	Offset: CFrame, -- relative to the attached body part
	Color: Color3,
}

CharacterConfig.Costume = {
	-- sheep disguise
	{ Name = "WoolCoat", AttachTo = "Torso", Shape = "Sphere", Size = Vector3.new(2.8, 2.3, 1.9), Offset = CFrame.new(0, 0.05, 0), Color = WOOL },
	{ Name = "WoolPuffLeft", AttachTo = "Torso", Shape = "Sphere", Size = Vector3.new(1.1, 1.1, 1.1), Offset = CFrame.new(-1, 0.65, 0), Color = WOOL },
	{ Name = "WoolPuffRight", AttachTo = "Torso", Shape = "Sphere", Size = Vector3.new(1.1, 1.1, 1.1), Offset = CFrame.new(1, 0.65, 0), Color = WOOL },
	{ Name = "WoolHood", AttachTo = "Head", Shape = "Sphere", Size = Vector3.new(1.75, 1.5, 1.6), Offset = CFrame.new(0, 0.3, 0.3), Color = WOOL },
	{ Name = "SheepEarLeft", AttachTo = "Head", Shape = "Sphere", Size = Vector3.new(0.8, 0.3, 0.45), Offset = CFrame.new(-0.95, 0.2, 0.1) * CFrame.Angles(0, 0, math.rad(25)), Color = EAR_INSIDE },
	{ Name = "SheepEarRight", AttachTo = "Head", Shape = "Sphere", Size = Vector3.new(0.8, 0.3, 0.45), Offset = CFrame.new(0.95, 0.2, 0.1) * CFrame.Angles(0, 0, math.rad(-25)), Color = EAR_INSIDE },
	-- the wolf gives itself away
	{ Name = "WolfEarLeft", AttachTo = "Head", Shape = "Wedge", Size = Vector3.new(0.3, 0.65, 0.45), Offset = CFrame.new(-0.4, 1.15, 0.25), Color = CharacterConfig.WolfFurColor },
	{ Name = "WolfEarRight", AttachTo = "Head", Shape = "Wedge", Size = Vector3.new(0.3, 0.65, 0.45), Offset = CFrame.new(0.4, 1.15, 0.25), Color = CharacterConfig.WolfFurColor },
	{ Name = "WolfTail", AttachTo = "Torso", Shape = "Sphere", Size = Vector3.new(0.6, 0.6, 2), Offset = CFrame.new(0, -0.7, 1.3) * CFrame.Angles(math.rad(-35), 0, 0), Color = CharacterConfig.WolfFurColor },
	{ Name = "WolfTailTip", AttachTo = "Torso", Shape = "Sphere", Size = Vector3.new(0.45, 0.45, 0.7), Offset = CFrame.new(0, -0.15, 2.1) * CFrame.Angles(math.rad(-35), 0, 0), Color = WOLF_DARK },
} :: { CostumePiece }

-- Seconds to wait for the body parts of a freshly spawned character.
CharacterConfig.BodyPartTimeoutSeconds = 5

return CharacterConfig
