--!strict
-- Server entry point: starts the services and registers interaction handlers.

local CarryService = require(script.Services.CarryService)
local CharacterService = require(script.Services.CharacterService)
local InteractionService = require(script.Services.InteractionService)
local ProductService = require(script.Services.ProductService)
local ShelfService = require(script.Services.ShelfService)

for _, module in script.Interactions:GetChildren() do
	if module:IsA("ModuleScript") then
		InteractionService.registerHandler(require(module) :: any)
	end
end

CharacterService.init()
ProductService.init()
CarryService.init()
ShelfService.init()
InteractionService.init()
