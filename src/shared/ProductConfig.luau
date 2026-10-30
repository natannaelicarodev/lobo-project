--!strict
-- Products, boxes, shelves and carrying: every balance and physics value lives here.
-- Box and unit visuals are PROVISIONAL (basic parts); see ProductService.

local ProductConfig = {}

export type Product = {
	DisplayName: string,
	PluralName: string,
	Color: Color3,
	UnitsPerBox: number,
}

ProductConfig.Products = {
	Apple = {
		DisplayName = "Maçã",
		PluralName = "maçãs",
		Color = Color3.fromRGB(205, 45, 45),
		UnitsPerBox = 6,
	},
} :: { [string]: Product }

ProductConfig.Box = {
	-- matches the Apple template (ServerStorage.ProductTemplates.Apple) so spawn stacking
	-- and the provisional fallback box use the same footprint
	Size = Vector3.new(2.2, 1.5, 1.74),
	Color = Color3.fromRGB(176, 128, 78),
	UnitSize = 0.55, -- product shown on top of the box
}

ProductConfig.Shelf = {
	DefaultCapacity = 12,
	UnitSize = 0.6,
	UnitSpacing = 0.8,
}

ProductConfig.StockRoom = {
	StartingBoxes = 4,
	StartingProduct = "Apple",
}

ProductConfig.Carry = {
	-- where the box sits relative to the HumanoidRootPart while carried
	-- (matches the CarryIdle/CarryWalk animations: hands under the box)
	HoldOffset = CFrame.new(0, 0.25, -1.65),
	-- The box is welded to this body part so it follows the arms in the animations
	-- (pick up, carry, place). The offset was measured in the CarryIdle pose so the box
	-- ends up exactly at HoldOffset from the root; HoldOffset is used when the part is missing.
	HoldPart = "RightHand",
	HoldOffsetFromPart = CFrame.new(0.395, 0.539, -0.826)
		* CFrame.fromOrientation(math.rad(9.5), math.rad(-90.07), math.rad(21.7)),
	-- where the server tries to put the box when dropped, in order
	DropDistances = { 3, 2.5, 2 }, -- studs in front of the player
	DropAngles = { 0, 30, -30 }, -- degrees left/right of where the player looks
	DropMaxStepDown = 6, -- the floor may be at most this far below the player's root
	DropMinFloorNormalY = 0.7, -- only fairly flat floors
	DropOverlapShrink = 0.1, -- tolerance when checking the box volume against the world
	MinRequestIntervalSeconds = 0.25,
	-- camera comes closer while carrying, so the shelf is easier to aim at
	CameraMaxZoomWhileCarrying = 10,
	Keys = {
		Keyboard = Enum.KeyCode.G,
		Gamepad = Enum.KeyCode.ButtonB,
	},
	TouchButtonTitle = "Soltar",
}

return ProductConfig
