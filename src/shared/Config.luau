-- Balancing values for the whole game. Change numbers here, not in the systems.

local Config = {}

Config.Day = {
	LengthSeconds = 360, -- one bakery day
	BreakSeconds = 10, -- pause between days
}

Config.Customers = {
	SpawnIntervalMin = 6,
	SpawnIntervalMax = 12,
	FirstSpawnDelay = 2,
	PatienceSeconds = 45,
	WalkSpeed = 8, -- studs per second
	ReactionSeconds = 1.5, -- how long the "thank you" / "hmpf" balloon shows before leaving
}

Config.Coins = {
	Starting = 0,
	TipMax = 5, -- extra coins when the customer still has full patience
}

Config.Interaction = {
	MaxDistance = 10,
	DistanceTolerance = 4, -- server slack on top of MaxDistance (lag)
}

-- Things the oven can bake and customers can order.
Config.Menu = {
	{
		Id = "Bread",
		DisplayName = "Pão",
		Price = 5,
		BakeSeconds = 1,
		Color = Color3.fromRGB(222, 170, 90),
		Key = Enum.KeyCode.E,
	},
	{
		Id = "Cake",
		DisplayName = "Bolo",
		Price = 10,
		BakeSeconds = 2.5,
		Color = Color3.fromRGB(240, 130, 170),
		Key = Enum.KeyCode.R,
	},
}

return Config
