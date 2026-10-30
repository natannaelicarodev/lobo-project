--!strict
-- Reads the data of an interactive instance. Shared so the client (hint UI) and the
-- server (validation) always agree on position, range, texts and state.

local CollectionService = game:GetService("CollectionService")

local InteractionConfig = require(script.Parent.InteractionConfig)

local Interactable = {}

function Interactable.isInteractable(instance: Instance): boolean
	return CollectionService:HasTag(instance, InteractionConfig.Tag)
		and (instance:IsA("BasePart") or instance:IsA("Model"))
		and instance:IsDescendantOf(workspace)
end

function Interactable.getTypeName(instance: Instance): string?
	local typeName = instance:GetAttribute("InteractionType")
	if typeof(typeName) == "string" and InteractionConfig.Types[typeName] then
		return typeName
	end
	return nil
end

function Interactable.getPosition(instance: Instance): Vector3?
	if instance:IsA("BasePart") then
		return instance.Position
	elseif instance:IsA("Model") then
		return instance:GetPivot().Position
	end
	return nil
end

function Interactable.getMaxDistance(instance: Instance): number
	local override = instance:GetAttribute("MaxDistance")
	if typeof(override) == "number" then
		return override
	end
	local typeName = Interactable.getTypeName(instance)
	local definition = typeName and InteractionConfig.Types[typeName]
	return (definition and definition.MaxDistance) or InteractionConfig.DefaultMaxDistance
end

function Interactable.isEnabled(instance: Instance): boolean
	return instance:GetAttribute("Enabled") ~= false
end

function Interactable.getActionText(instance: Instance): string
	local override = instance:GetAttribute("ActionText")
	if typeof(override) == "string" then
		return override
	end
	local typeName = Interactable.getTypeName(instance)
	local definition = typeName and InteractionConfig.Types[typeName]
	return definition and definition.ActionText or ""
end

function Interactable.getObjectText(instance: Instance): string
	local override = instance:GetAttribute("ObjectText")
	if typeof(override) == "string" then
		return override
	end
	local typeName = Interactable.getTypeName(instance)
	local definition = typeName and InteractionConfig.Types[typeName]
	return definition and definition.ObjectText or ""
end

return Interactable
