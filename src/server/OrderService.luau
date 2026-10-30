-- Oven baking, the item the player is holding, order delivery and coins.
-- Player attributes (read by the client HUD): Coins (number), HeldItem (menu Id or nil)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DayManager = require(script.Parent.DayManager)

local OrderService = {}

local menuById = {}
for _, item in Config.Menu do
	menuById[item.Id] = item
end

local notifyRemote: RemoteEvent

function OrderService.GetMenuItem(id: string)
	return menuById[id]
end

function OrderService.Notify(player: Player, message: string)
	notifyRemote:FireClient(player, message)
end

-- Server-side check that the player is really standing close to the part.
function OrderService.IsPlayerNear(player: Player, part: BasePart): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end
	local limit = Config.Interaction.MaxDistance + Config.Interaction.DistanceTolerance
	return (root.Position - part.Position).Magnitude <= limit
end

local function clearHeldVisual(player: Player)
	local character = player.Character
	local held = character and character:FindFirstChild("HeldItemVisual")
	if held then
		held:Destroy()
	end
end

local function setHeldItem(player: Player, itemId: string?)
	player:SetAttribute("HeldItem", itemId)
	clearHeldVisual(player)

	local item = itemId and menuById[itemId]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not item or not root then
		return
	end

	-- Placeholder: a small colored box carried in front of the player.
	local visual = Instance.new("Part")
	visual.Name = "HeldItemVisual"
	visual.Size = Vector3.new(1.2, 0.8, 1.2)
	visual.Color = item.Color
	visual.Material = Enum.Material.SmoothPlastic
	visual.CanCollide = false
	visual.CanQuery = false
	visual.CanTouch = false
	visual.Massless = true
	visual.CFrame = root.CFrame * CFrame.new(0, 0, -1.6)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = visual
	weld.Parent = visual
	visual.Parent = character
end

function OrderService.GetHeldItem(player: Player): string?
	return player:GetAttribute("HeldItem")
end

function OrderService.AddCoins(player: Player, amount: number)
	player:SetAttribute("Coins", (player:GetAttribute("Coins") or 0) + amount)
end

-- Returns the coins earned, or nil if the player is not holding the ordered item.
function OrderService.TryDeliver(player: Player, orderId: string, patienceFraction: number): number?
	local item = menuById[orderId]
	if not item then
		return nil
	end

	local held = OrderService.GetHeldItem(player)
	if held == nil then
		OrderService.Notify(player, "Asse o pedido no forno primeiro!")
		return nil
	end
	if held ~= orderId then
		OrderService.Notify(player, "Pedido errado! A ovelha quer " .. item.DisplayName .. ".")
		return nil
	end

	local tip = math.floor(Config.Coins.TipMax * math.clamp(patienceFraction, 0, 1) + 0.5)
	local earned = item.Price + tip
	setHeldItem(player, nil)
	OrderService.AddCoins(player, earned)
	OrderService.Notify(player, "+" .. earned .. " moedas!")
	return earned
end

local function setupOven(oven: BasePart)
	for index, item in Config.Menu do
		local attachment = Instance.new("Attachment")
		attachment.Name = "Prompt_" .. item.Id
		-- spread the prompts along the oven front so they don't overlap
		attachment.Position = Vector3.new((index - (#Config.Menu + 1) / 2) * 1.6, 0, -oven.Size.Z / 2)
		attachment.Parent = oven

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Assar " .. item.DisplayName
		prompt.ObjectText = "Forno"
		prompt.HoldDuration = item.BakeSeconds
		prompt.KeyboardKeyCode = item.Key
		prompt.MaxActivationDistance = Config.Interaction.MaxDistance
		prompt.RequiresLineOfSight = false
		prompt.Parent = attachment

		prompt.Triggered:Connect(function(player)
			if not OrderService.IsPlayerNear(player, oven) then
				return
			end
			if not DayManager.IsDayActive() then
				OrderService.Notify(player, "A padaria está fechada agora.")
				return
			end
			setHeldItem(player, item.Id)
			OrderService.Notify(player, item.DisplayName .. " pronto!")
		end)
	end
end

function OrderService.Init()
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	notifyRemote = Instance.new("RemoteEvent")
	notifyRemote.Name = "Notify"
	notifyRemote.Parent = remotes
	remotes.Parent = ReplicatedStorage

	local bakery = workspace:WaitForChild("Bakery")
	setupOven(bakery:WaitForChild("Oven"))

	local function onPlayerAdded(player: Player)
		player:SetAttribute("Coins", Config.Coins.Starting)
		player:SetAttribute("HeldItem", nil)
		player.CharacterAdded:Connect(function()
			player:SetAttribute("HeldItem", nil)
		end)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return OrderService
