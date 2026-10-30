--!strict
-- Shelves hold a real stock count for one product, up to a capacity.
-- A shelf is a BasePart tagged Interactable with attributes:
--   InteractionType = "Shelf", ProductId, Capacity (optional), Stock (set by the server)
-- The stock is shown as exactly one product model per unit, placed on the shelf's
-- DisplaySlot attachments (or on a grid over its top surface when it has none).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InteractionConfig = require(ReplicatedStorage.Shared.InteractionConfig)
local ProductConfig = require(ReplicatedStorage.Shared.ProductConfig)
local CarryService = require(script.Parent.CarryService)
local ProductService = require(script.Parent.ProductService)

local DISPLAY_NAME = "StockDisplay"

local ShelfService = {}

function ShelfService.isShelf(instance: Instance): boolean
	return instance:IsA("BasePart") and instance:GetAttribute("InteractionType") == "Shelf"
end

function ShelfService.getStock(shelf: BasePart): number
	local stock = shelf:GetAttribute("Stock")
	return if typeof(stock) == "number" then stock else 0
end

function ShelfService.getCapacity(shelf: BasePart): number
	local capacity = shelf:GetAttribute("Capacity")
	return if typeof(capacity) == "number" then capacity else ProductConfig.Shelf.DefaultCapacity
end

-- The product model from the box template (same apple as in the crate), or a
-- PROVISIONAL sphere when there is no template.
local function makeUnit(productId: unknown, product: ProductConfig.Product?): BasePart
	local model = if typeof(productId) == "string" then ProductService.getUnitModel(productId) else nil
	local unit: BasePart
	if model then
		unit = model:Clone()
		unit:SetAttribute("ProductUnit", nil)
	else
		local sphere = Instance.new("Part")
		sphere.Shape = Enum.PartType.Ball
		sphere.Size = Vector3.one * ProductConfig.Shelf.UnitSize
		sphere.Color = if product then product.Color else Color3.new(1, 1, 1)
		unit = sphere
	end
	unit.Name = "Unit"
	unit.Anchored = true
	unit.CanCollide = false
	unit.CanQuery = false
	unit.CanTouch = false
	return unit
end

-- Where each unit stands, in fill order. A shelf with Attachments named "DisplaySlot"
-- (attribute Order) uses them, e.g. the tiers of a modeled stand; otherwise a grid on the
-- shelf's top surface. Positions are on the floor the product rests on.
local function getSlotPositions(shelf: BasePart, count: number): { Vector3 }
	local slots = {}
	for _, child in shelf:GetChildren() do
		if child:IsA("Attachment") and child.Name == "DisplaySlot" then
			table.insert(slots, child)
		end
	end
	local positions = {}
	if #slots > 0 then
		table.sort(slots, function(a, b)
			return (a:GetAttribute("Order") or 0) < (b:GetAttribute("Order") or 0)
		end)
		for index = 1, math.min(count, #slots) do
			table.insert(positions, slots[index].WorldPosition)
		end
		return positions
	end
	local spacing = ProductConfig.Shelf.UnitSpacing
	local columns = math.max(1, math.floor(shelf.Size.X / spacing))
	for index = 1, count do
		local column = (index - 1) % columns
		local row = (index - 1) // columns
		local x = (column + 0.5) * spacing - columns * spacing / 2
		local z = (row + 0.5) * spacing - shelf.Size.Z / 2
		table.insert(positions, (shelf.CFrame * CFrame.new(x, shelf.Size.Y / 2, z)).Position)
	end
	return positions
end

local function refreshTexts(shelf: BasePart, product: ProductConfig.Product?)
	local capacity = ShelfService.getCapacity(shelf)
	local name = if product then product.PluralName else "produtos"
	shelf:SetAttribute("ObjectText", `Prateleira de {name} ({ShelfService.getStock(shelf)}/{capacity})`)
	shelf:SetAttribute("ActionText", `Repor {name}`)
end

local function refreshDisplay(shelf: BasePart)
	local productId = shelf:GetAttribute("ProductId")
	local product = ProductService.getProduct(productId)
	local display = shelf:FindFirstChild(DISPLAY_NAME)
	if not display then
		display = Instance.new("Folder")
		display.Name = DISPLAY_NAME
		display.Parent = shelf
	end

	-- exactly one product model per unit in stock; rebuilt on every change (a shelf
	-- holds only a handful of units)
	display:ClearAllChildren()
	for _, floorPosition in getSlotPositions(shelf, ShelfService.getStock(shelf)) do
		local unit = makeUnit(productId, product)
		-- keep the model's own rotation so a mesh stays upright as in the template
		local rotation = unit.CFrame.Rotation
		unit.CFrame = CFrame.new(floorPosition + Vector3.new(0, unit.Size.Y / 2, 0)) * rotation
		unit.Parent = display
	end
	refreshTexts(shelf, product)
end

function ShelfService.setStock(shelf: BasePart, stock: number)
	shelf:SetAttribute("Stock", math.clamp(stock, 0, ShelfService.getCapacity(shelf)))
	refreshDisplay(shelf)
end

-- Moves products from the carried box to the shelf. Runs without yielding, so two
-- players restocking at the same time can never move the same units twice.
function ShelfService.restock(player: Player, shelf: BasePart): (boolean, string?)
	local box = CarryService.getCarried(player)
	if not box then
		return false, "Pegue uma caixa no estoque primeiro."
	end
	local productId = box:GetAttribute("ProductId")
	if productId ~= shelf:GetAttribute("ProductId") then
		return false, "Essa prateleira é de outro produto."
	end
	local product = ProductService.getProduct(productId)
	if not product then
		return false, nil
	end

	local stock = ShelfService.getStock(shelf)
	local capacity = ShelfService.getCapacity(shelf)
	local space = capacity - stock
	if space <= 0 then
		return false, "A prateleira já está cheia."
	end
	local unitsInBox = ProductService.getUnits(box)
	local moved = math.min(space, unitsInBox)
	if moved <= 0 then
		return false, "Essa caixa está vazia."
	end

	ShelfService.setStock(shelf, stock + moved)
	ProductService.setUnits(box, unitsInBox - moved)
	local message = `+{moved} {product.PluralName} na prateleira ({stock + moved}/{capacity})`
	if unitsInBox - moved <= 0 then
		CarryService.release(player)
		ProductService.destroyBox(box)
		message ..= ". Caixa vazia descartada."
	end
	return true, message
end

function ShelfService.init()
	for _, instance in CollectionService:GetTagged(InteractionConfig.Tag) do
		if ShelfService.isShelf(instance) then
			ShelfService.setStock(instance :: BasePart, ShelfService.getStock(instance :: BasePart))
		end
	end
end

return ShelfService
