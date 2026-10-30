--!strict
-- Opens and closes a door part by making it passable. Lock a door by setting the
-- attribute Enabled = false (and optionally DisabledMessage) on it.

local OPEN_TRANSPARENCY = 0.7

return {
	TypeName = "Door",

	interact = function(_player: Player, target: Instance): (boolean, string?)
		if not target:IsA("BasePart") then
			return false, nil
		end

		local open = target:GetAttribute("IsOpen") ~= true
		target:SetAttribute("IsOpen", open)
		target.CanCollide = not open
		target.Transparency = if open then OPEN_TRANSPARENCY else 0
		target:SetAttribute("ActionText", if open then "Fechar porta" else "Abrir porta")
		return true, nil
	end,
}
