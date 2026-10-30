--!strict
-- Turns a lamp on and off. The switch needs an ObjectValue child named "Lamp"
-- pointing to a BasePart that contains a Light (PointLight, SpotLight...).

local LIGHT_ON_MATERIAL = Enum.Material.Neon
local LIGHT_OFF_MATERIAL = Enum.Material.SmoothPlastic

local function findLamp(target: Instance): (BasePart?, Light?)
	local link = target:FindFirstChild("Lamp")
	local lamp = link and link:IsA("ObjectValue") and link.Value
	if not lamp or not lamp:IsA("BasePart") then
		return nil, nil
	end
	return lamp, lamp:FindFirstChildWhichIsA("Light")
end

return {
	TypeName = "LightSwitch",

	interact = function(_player: Player, target: Instance): (boolean, string?)
		local lamp, light = findLamp(target)
		if not lamp or not light then
			return false, "Este interruptor não está ligado a nenhuma lâmpada."
		end

		local turnOn = not light.Enabled
		light.Enabled = turnOn
		lamp.Material = if turnOn then LIGHT_ON_MATERIAL else LIGHT_OFF_MATERIAL
		target:SetAttribute("ActionText", if turnOn then "Apagar luz" else "Acender luz")
		return true, if turnOn then "Luz acesa." else "Luz apagada."
	end,
}
