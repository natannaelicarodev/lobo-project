--!strict
-- Product boxes: creation, unit count and recovery of boxes lost by physics
-- (e.g. fallen out of the map). Box state lives in attributes on the box Model:
--   ProductId, Units, InteractionType = "ProductBox", CarriedBy (UserId while carried)
-- Visuals: if ServerStorage.ProductTemplates.<ProductId> exists (a Model; parts with the
-- attribute ProductUnit = n are the products shown for unit n), it is cloned around an
-- invisible "Crate" part that does all the physics. Otherwise a PROVISIONAL crate is built.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local InteractionConfig = require(ReplicatedStorage.Shared.InteractionConfig)
local ProductConfig = require(ReplicatedStorage.Shared.ProductConfig)

local BOX_TYPE = "ProductBox"
local CRATE_NAME = "Crate"
local TEMPLATE_FOLDER = "ProductTemplates"

local ProductService = {}

local boxesFolder: Folder
local spawnPoints: { BasePart } = {}
local nextSpawnIndex = 0
local destroyingOnPurpose: { [Model]: boolean } = {}

function ProductService.getProduct(productId: unknown): ProductConfig.Product?
	if typeof(productId) ~= "string" then
		return nil
	end
	return ProductConfig.Products[productId]
end

function ProductService.isBox(instance: Instance): boolean
	return instance:IsA("Model")
		and instance:GetAttribute("InteractionType") == BOX_TYPE
		and instance:FindFirstChild(CRATE_NAME) ~= nil
		and instance:IsDescendantOf(workspace)
end

function ProductService.getCrate(box: Model): BasePart
	return box:FindFirstChild(CRATE_NAME) :: BasePart
end

function ProductService.getUnits(box: Model): number
	local units = box:GetAttribute("Units")
	return if typeof(units) == "number" then units else 0
end

function ProductService.setUnits(box: Model, units: number)
	box:SetAttribute("Units", units)
	local product = ProductService.getProduct(box:GetAttribute("ProductId"))
	if product then
		box:SetAttribute("ObjectText", `Caixa de {product.PluralName} ({units})`)
	end
	-- show only the products of the units still in the box
	for _, part in box:GetDescendants() do
		local index = part:GetAttribute("UnitIndex")
		if part:IsA("BasePart") and typeof(index) == "number" then
			part.Transparency = if index <= units then 0 else 1
		end
	end
end

local function weldTo(root: BasePart, part: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
end

local function getTemplate(productId: string): Model?
	local folder = ServerStorage:FindFirstChild(TEMPLATE_FOLDER)
	local template = folder and folder:FindFirstChild(productId)
	return if template and template:IsA("Model") then template else nil
end

-- One product model from the template (a part with ProductUnit), e.g. for shelf displays.
function ProductService.getUnitModel(productId: string): BasePart?
	local template = getTemplate(productId)
	if not template then
		return nil
	end
	for _, part in template:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("ProductUnit") ~= nil then
			return part
		end
	end
	return nil
end

-- Template visual (e.g. Creator Store crate) welded around an invisible physics crate
-- with the size of the template's bounding box.
local function buildFromTemplate(template: Model, cframe: CFrame): Model
	local visual = template:Clone()
	visual.Name = "Visual"
	local boundsCFrame, boundsSize = visual:GetBoundingBox()

	local model = Instance.new("Model")
	model.Name = "ProductBox"
	local crate = Instance.new("Part")
	crate.Name = CRATE_NAME
	crate.Size = boundsSize
	crate.Transparency = 1
	crate.CFrame = cframe
	crate.Parent = model
	model.PrimaryPart = crate

	visual:PivotTo(cframe * boundsCFrame:ToObjectSpace(visual:GetPivot()))
	for _, part in visual:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Massless = true
			local unit = part:GetAttribute("ProductUnit")
			if typeof(unit) == "number" then
				part:SetAttribute("UnitIndex", unit)
			end
			weldTo(crate, part)
		end
	end
	visual.Parent = model
	return model
end

local function buildProvisionalBox(product: ProductConfig.Product, cframe: CFrame): Model
	local size = ProductConfig.Box.Size
	local model = Instance.new("Model")
	model.Name = "ProductBox"

	local crate = Instance.new("Part")
	crate.Name = CRATE_NAME
	crate.Size = size
	crate.Color = ProductConfig.Box.Color
	crate.Material = Enum.Material.WoodPlanks
	crate.CFrame = cframe
	crate.Parent = model
	model.PrimaryPart = crate

	local unitSize = ProductConfig.Box.UnitSize
	local columns = math.max(1, math.floor(size.X / unitSize))
	for index = 1, product.UnitsPerBox do
		local column = (index - 1) % columns
		local row = (index - 1) // columns
		local unit = Instance.new("Part")
		unit.Name = "Unit"
		unit.Shape = Enum.PartType.Ball
		unit.Size = Vector3.one * unitSize
		unit.Color = product.Color
		unit.Material = Enum.Material.SmoothPlastic
		unit.CanCollide = false
		unit.CanQuery = false
		unit.CanTouch = false
		unit.Massless = true
		unit:SetAttribute("UnitIndex", index)
		local x = (column + 0.5) * unitSize - columns * unitSize / 2
		local z = (row - 0.5) * unitSize
		unit.CFrame = cframe * CFrame.new(x, size.Y / 2 + unitSize * 0.3, z)
		weldTo(crate, unit)
		unit.Parent = model
	end
	return model
end

local function buildBox(productId: string, product: ProductConfig.Product, cframe: CFrame): Model
	local template = getTemplate(productId)
	if template then
		return buildFromTemplate(template, cframe)
	end
	return buildProvisionalBox(product, cframe)
end

local function nextSpawnCFrame(): CFrame
	if #spawnPoints == 0 then
		return CFrame.new(0, 5, 0)
	end
	nextSpawnIndex += 1
	local point = spawnPoints[(nextSpawnIndex - 1) % #spawnPoints + 1]
	local stackLevel = (nextSpawnIndex - 1) // #spawnPoints
	local height = point.Size.Y / 2 + ProductConfig.Box.Size.Y * (stackLevel + 0.5) + 0.05
	return point.CFrame * CFrame.new(0, height, 0)
end

-- Server-owned physics: the client can't push the box around by network ownership.
function ProductService.setServerOwned(box: Model)
	local crate = ProductService.getCrate(box)
	if crate and not crate.Anchored and crate:IsDescendantOf(workspace) then
		pcall(crate.SetNetworkOwner, crate, nil)
	end
end

local createBox: (productId: string, units: number, cframe: CFrame) -> Model

-- If physics or anything else removes a box that still has products, the stock is not
-- lost: a new box with the same units appears in the stock room.
local function watchForLoss(box: Model)
	local crate = ProductService.getCrate(box)
	crate.AncestryChanged:Connect(function()
		if crate:IsDescendantOf(workspace) or destroyingOnPurpose[box] then
			destroyingOnPurpose[box] = nil
			return
		end
		local units = ProductService.getUnits(box)
		local productId = box:GetAttribute("ProductId")
		if units > 0 and typeof(productId) == "string" then
			warn(`[ProductService] box lost with {units} units of {productId}; respawning in stock room`)
			task.defer(createBox, productId, units, nextSpawnCFrame())
		end
		-- remove what is left of the old box (empty model, loose units)
		if box.Parent then
			ProductService.destroyBox(box)
		end
	end)
end

createBox = function(productId: string, units: number, cframe: CFrame): Model
	local product = ProductService.getProduct(productId)
	assert(product, "Unknown product: " .. tostring(productId))
	local box = buildBox(productId, product, cframe)
	box:SetAttribute("InteractionType", BOX_TYPE)
	box:SetAttribute("ProductId", productId)
	ProductService.setUnits(box, units)
	CollectionService:AddTag(box, InteractionConfig.Tag)
	box.Parent = boxesFolder
	ProductService.setServerOwned(box)
	watchForLoss(box)
	return box
end
ProductService.createBox = createBox

function ProductService.destroyBox(box: Model)
	destroyingOnPurpose[box] = true
	box:Destroy()
end

function ProductService.init()
	local store = workspace:WaitForChild("Store")
	local stockRoom = store:WaitForChild("StockRoom")
	for _, child in stockRoom:GetChildren() do
		if child:IsA("BasePart") and child.Name == "BoxSpawn" then
			table.insert(spawnPoints, child)
		end
	end
	table.sort(spawnPoints, function(a, b)
		return a.Position.X < b.Position.X
	end)

	local folder = Instance.new("Folder")
	folder.Name = "Boxes"
	folder.Parent = store
	boxesFolder = folder

	local starting = ProductConfig.StockRoom
	local product = ProductConfig.Products[starting.StartingProduct]
	for _ = 1, starting.StartingBoxes do
		createBox(starting.StartingProduct, product.UnitsPerBox, nextSpawnCFrame())
	end
end

return ProductService
