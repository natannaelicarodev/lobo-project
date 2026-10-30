--!strict
-- Client entry point: starts the controllers.

local CarryController = require(script.Controllers.CarryController)
local CharacterAnimationController = require(script.Controllers.CharacterAnimationController)
local InteractionController = require(script.Controllers.InteractionController)

InteractionController.init()
CarryController.init()
CharacterAnimationController.init()
