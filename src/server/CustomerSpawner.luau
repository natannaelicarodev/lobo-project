-- Spawns sheep customers during the day. Each one walks to a free counter slot,
-- shows an order balloon with a patience bar and waits for the player to deliver.
-- Uses Workspace.Bakery: CustomerSpawn (Part), CustomerSlots (Folder of Parts).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local DayManager = require(script.Parent.DayManager)
local OrderService = require(script.Parent.OrderService)

local CustomerSpawner = {}

local WOOL_COLOR = Color3.fromRGB(245, 245, 240)
local FACE_COLOR = Color3.fromRGB(60, 55, 55)
local BODY_HEIGHT = 2.2 -- height of the body center above the floor

type Customer = {
	model: Model,
	root: BasePart,
	slotIndex: number,
	order: any,
	state: "Walking" | "Waiting" | "Leaving",
	patienceLeft: number,
	balloonText: TextLabel,
	patienceFill: Frame,
	prompt: ProximityPrompt,
}

local spawnPart: BasePart
local slots: { BasePart } = {}
local slotTaken: { [number]: Customer? } = {}
local waitingCustomers: { [Customer]: boolean } = {}
local spawnLoopId = 0

local function groundCFrame(position: Vector3, lookAt: Vector3): CFrame
	local from = Vector3.new(position.X, BODY_HEIGHT, position.Z)
	local to = Vector3.new(lookAt.X, BODY_HEIGHT, lookAt.Z)
	if (to - from).Magnitude < 0.01 then
		to = from + Vector3.new(0, 0, 1)
	end
	return CFrame.lookAt(from, to)
end

local function addPiece(model: Model, root: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3)
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.Color = color
	piece.Material = Enum.Material.SmoothPlastic
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.Massless = true
	piece.CFrame = root.CFrame * offset

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = piece
	weld.Parent = piece
	piece.Parent = model
end

local function buildBalloon(root: BasePart, order): (TextLabel, Frame)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OrderBalloon"
	billboard.Size = UDim2.fromOffset(150, 64)
	billboard.StudsOffset = Vector3.new(0, 3.4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 80

	local balloon = Instance.new("Frame")
	balloon.Size = UDim2.fromScale(1, 1)
	balloon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	balloon.Parent = billboard
	Instance.new("UICorner", balloon).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(80, 60, 50)
	stroke.Parent = balloon

	local text = Instance.new("TextLabel")
	text.Name = "OrderText"
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromOffset(8, 4)
	text.Size = UDim2.new(1, -16, 0, 34)
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(80, 60, 50)
	text.Text = "Quero: " .. order.DisplayName
	text.Parent = balloon

	local barBack = Instance.new("Frame")
	barBack.Position = UDim2.new(0, 10, 1, -20)
	barBack.Size = UDim2.new(1, -20, 0, 10)
	barBack.BackgroundColor3 = Color3.fromRGB(220, 215, 210)
	barBack.Parent = balloon
	Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Name = "PatienceFill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(90, 200, 90)
	fill.Parent = barBack
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	billboard.Parent = root
	return text, fill
end

local function buildSheep(startCFrame: CFrame, order): (Model, BasePart)
	local model = Instance.new("Model")
	model.Name = "SheepCustomer"

	-- Anchored body; every other piece is welded to it and follows when it moves.
	local root = Instance.new("Part")
	root.Name = "Body"
	root.Size = Vector3.new(2.4, 2.4, 3.2)
	root.Color = WOOL_COLOR
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CFrame = startCFrame
	root.Parent = model
	model.PrimaryPart = root

	addPiece(model, root, "Head", Vector3.new(1.4, 1.4, 1.4), CFrame.new(0, 0.7, -2), FACE_COLOR)
	addPiece(model, root, "Wool", Vector3.new(1.6, 0.6, 1.2), CFrame.new(0, 1.55, -1.9), WOOL_COLOR)
	for _, x in { -0.8, 0.8 } do
		for _, z in { -1.1, 1.1 } do
			addPiece(model, root, "Leg", Vector3.new(0.5, 1.2, 0.5), CFrame.new(x, -1.6, z), FACE_COLOR)
		end
	end

	return model, root
end

local function walkTo(customer: Customer, target: Vector3)
	local root = customer.root
	local goal = groundCFrame(target, target + (target - root.Position))
	local distance = (goal.Position - root.Position).Magnitude
	local tween = TweenService:Create(
		root,
		TweenInfo.new(math.max(distance / Config.Customers.WalkSpeed, 0.1), Enum.EasingStyle.Linear),
		{ CFrame = goal }
	)
	tween:Play()
	tween.Completed:Wait()
end

local function leave(customer: Customer, reaction: string?, color: Color3?)
	if customer.state == "Leaving" then
		return
	end
	customer.state = "Leaving"
	customer.prompt.Enabled = false
	waitingCustomers[customer] = nil

	if reaction then
		customer.balloonText.Text = reaction
		customer.balloonText.TextColor3 = color or customer.balloonText.TextColor3
		customer.patienceFill.Parent.Visible = false
	end

	task.spawn(function()
		task.wait(Config.Customers.ReactionSeconds)
		slotTaken[customer.slotIndex] = nil
		if customer.model.Parent then
			walkTo(customer, spawnPart.Position)
			customer.model:Destroy()
		end
	end)
end

local function onPromptTriggered(customer: Customer, player: Player)
	if customer.state ~= "Waiting" then
		return
	end
	if not OrderService.IsPlayerNear(player, customer.root) then
		return
	end
	local fraction = customer.patienceLeft / Config.Customers.PatienceSeconds
	local earned = OrderService.TryDeliver(player, customer.order.Id, fraction)
	if earned then
		leave(customer, "Obrigado!", Color3.fromRGB(40, 150, 60))
	end
end

local function spawnCustomer(slotIndex: number)
	local slot = slots[slotIndex]
	local order = Config.Menu[math.random(1, #Config.Menu)]
	local model, root = buildSheep(groundCFrame(spawnPart.Position, slot.Position), order)
	local balloonText, patienceFill = buildBalloon(root, order)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Entregar " .. order.DisplayName
	prompt.ObjectText = "Ovelha"
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = Config.Interaction.MaxDistance
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = root

	local customer: Customer = {
		model = model,
		root = root,
		slotIndex = slotIndex,
		order = order,
		state = "Walking",
		patienceLeft = Config.Customers.PatienceSeconds,
		balloonText = balloonText,
		patienceFill = patienceFill,
		prompt = prompt,
	}
	slotTaken[slotIndex] = customer
	prompt.Triggered:Connect(function(player)
		onPromptTriggered(customer, player)
	end)

	model.Parent = workspace.Bakery.Customers

	task.spawn(function()
		walkTo(customer, slot.Position)
		if customer.state ~= "Walking" then
			return
		end
		-- face the counter (slots look toward it via their LookVector)
		root.CFrame = groundCFrame(root.Position, root.Position + slot.CFrame.LookVector)
		customer.state = "Waiting"
		prompt.Enabled = true
		waitingCustomers[customer] = true
	end)
end

local function freeSlotIndex(): number?
	for index in slots do
		if not slotTaken[index] then
			return index
		end
	end
	return nil
end

local function runSpawnLoop()
	spawnLoopId += 1
	local myId = spawnLoopId
	task.spawn(function()
		task.wait(Config.Customers.FirstSpawnDelay)
		while spawnLoopId == myId and DayManager.IsDayActive() do
			local index = freeSlotIndex()
			if index then
				spawnCustomer(index)
				task.wait(math.random(Config.Customers.SpawnIntervalMin, Config.Customers.SpawnIntervalMax))
			else
				task.wait(1)
			end
		end
	end)
end

local function sendEveryoneHome()
	spawnLoopId += 1
	for _, customer in slotTaken do
		if customer then
			leave(customer, "Até amanhã!")
		end
	end
end

local function runPatienceLoop()
	task.spawn(function()
		local step = 0.2
		while true do
			task.wait(step)
			for customer in waitingCustomers do
				customer.patienceLeft -= step
				local fraction = math.max(customer.patienceLeft, 0) / Config.Customers.PatienceSeconds
				customer.patienceFill.Size = UDim2.fromScale(fraction, 1)
				customer.patienceFill.BackgroundColor3 = Color3.fromRGB(230, 70, 60)
					:Lerp(Color3.fromRGB(90, 200, 90), fraction)
				if customer.patienceLeft <= 0 then
					leave(customer, "Hmpf!", Color3.fromRGB(200, 50, 40))
				end
			end
		end
	end)
end

function CustomerSpawner.Init()
	local bakery = workspace:WaitForChild("Bakery")
	spawnPart = bakery:WaitForChild("CustomerSpawn")

	local slotFolder = bakery:WaitForChild("CustomerSlots")
	for _, slot in slotFolder:GetChildren() do
		table.insert(slots, slot)
	end
	table.sort(slots, function(a, b)
		return a.Name < b.Name
	end)

	local customersFolder = Instance.new("Folder")
	customersFolder.Name = "Customers"
	customersFolder.Parent = bakery

	DayManager.DayStarted:Connect(runSpawnLoop)
	DayManager.DayEnded:Connect(sendEveryoneHome)
	runPatienceLoop()
end

return CustomerSpawner
