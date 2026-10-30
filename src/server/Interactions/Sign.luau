--!strict
-- Shows the text stored in the sign's "Message" attribute.

return {
	TypeName = "Sign",

	interact = function(_player: Player, target: Instance): (boolean, string?)
		local message = target:GetAttribute("Message")
		if typeof(message) ~= "string" or message == "" then
			return false, "A placa está em branco."
		end
		return true, message
	end,
}
