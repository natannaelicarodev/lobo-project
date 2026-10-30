--!strict
-- Tunable values and player-facing texts for the interaction system.

local InteractionConfig = {}

-- CollectionService tag that marks an instance (BasePart or Model) as interactive.
-- Required attribute on the instance: InteractionType (a key of InteractionConfig.Types).
-- Optional attributes: Enabled (boolean), DisabledMessage, ActionText, ObjectText, MaxDistance.
InteractionConfig.Tag = "Interactable"

-- How often the client looks for the nearest interactive object.
InteractionConfig.ScanIntervalSeconds = 0.1

-- How far past the character the "looking at" ray reaches (the camera distance is added).
InteractionConfig.LookRayLength = 12

-- Extra distance the server accepts on top of MaxDistance (network latency).
InteractionConfig.ServerDistanceTolerance = 3

-- Minimum time between two requests from the same player.
InteractionConfig.MinRequestIntervalSeconds = 0.25

InteractionConfig.DefaultMaxDistance = 8

InteractionConfig.Keys = {
	Keyboard = Enum.KeyCode.E,
	Gamepad = Enum.KeyCode.ButtonX,
}

InteractionConfig.TouchButtonTitle = "Usar"

export type InteractionType = {
	ActionText: string,
	ObjectText: string,
	MaxDistance: number?,
}

InteractionConfig.Types = {
	LightSwitch = {
		ActionText = "Acender luz",
		ObjectText = "Interruptor",
	},
	Door = {
		ActionText = "Abrir porta",
		ObjectText = "Porta",
	},
	Sign = {
		ActionText = "Ler placa",
		ObjectText = "Placa",
		MaxDistance = 10,
	},
} :: { [string]: InteractionType }

-- Result codes returned by the server, with the message shown to the player.
InteractionConfig.Messages = {
	Invalid = "Isso não pode ser usado.",
	TooFast = "Calma, uma coisa de cada vez!",
	NoCharacter = "Seu personagem ainda não está pronto.",
	OutOfRange = "Chegue mais perto para usar.",
	Disabled = "Não dá para usar isso agora.",
	Busy = "Alguém já está usando isso.",
	Failed = "Algo deu errado. Tente de novo.",
	NoResponse = "O servidor não respondeu. Tente de novo.",
} :: { [string]: string }

InteractionConfig.FeedbackSeconds = 2

return InteractionConfig
