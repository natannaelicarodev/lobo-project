--!strict
-- Server entry point: starts the services and registers interaction handlers.

local CharacterService = require(script.Services.CharacterService)
local InteractionService = require(script.Services.InteractionService)

for _, module in script.Interactions:GetChildren() do
	if module:IsA("ModuleScript") then
		InteractionService.registerHandler(require(module) :: any)
	end
end

CharacterService.init()
InteractionService.init()
