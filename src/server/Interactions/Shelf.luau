--!strict
-- Restocks a shelf with the box the player is carrying.

local ShelfService = require(script.Parent.Parent.Services.ShelfService)

return {
	TypeName = "Shelf",

	interact = function(player: Player, target: Instance): (boolean, string?)
		if not ShelfService.isShelf(target) then
			return false, nil
		end
		return ShelfService.restock(player, target :: BasePart)
	end,
}
