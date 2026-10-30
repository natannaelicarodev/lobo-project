-- Server entry point: starts every system in order.

local OrderService = require(script.OrderService)
local CustomerSpawner = require(script.CustomerSpawner)
local DayManager = require(script.DayManager)

OrderService.Init()
CustomerSpawner.Init()
DayManager.Start()
