--!strict
-- Picks up a product box.

local CarryService = require(script.Parent.Parent.Services.CarryService)
local ProductService = require(script.Parent.Parent.Services.ProductService)

return {
	TypeName = "ProductBox",

	interact = function(player: Player, target: Instance): (boolean, string?)
		if not ProductService.isBox(target) then
			return false, nil
		end
		return CarryService.pickUp(player, target :: Model)
	end,
}
