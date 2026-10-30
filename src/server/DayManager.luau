-- Runs the day cycle: open bakery for Config.Day.LengthSeconds, short break, next day.
-- State is published as ReplicatedStorage attributes so clients can show it:
--   DayNumber (number), DayActive (boolean), PhaseTimeLeft (seconds)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DayManager = {}

local dayStarted = Instance.new("BindableEvent")
local dayEnded = Instance.new("BindableEvent")
DayManager.DayStarted = dayStarted.Event
DayManager.DayEnded = dayEnded.Event

function DayManager.IsDayActive(): boolean
	return ReplicatedStorage:GetAttribute("DayActive") == true
end

local function countdown(seconds: number)
	local endsAt = os.clock() + seconds
	local lastShown = -1
	while true do
		local left = math.max(0, math.ceil(endsAt - os.clock()))
		if left ~= lastShown then
			lastShown = left
			ReplicatedStorage:SetAttribute("PhaseTimeLeft", left)
		end
		if left <= 0 then
			return
		end
		task.wait(0.25)
	end
end

function DayManager.Start()
	ReplicatedStorage:SetAttribute("DayNumber", 0)
	ReplicatedStorage:SetAttribute("DayActive", false)

	task.spawn(function()
		local day = 0
		while true do
			day += 1
			ReplicatedStorage:SetAttribute("DayNumber", day)
			ReplicatedStorage:SetAttribute("DayActive", true)
			dayStarted:Fire(day)
			countdown(Config.Day.LengthSeconds)

			ReplicatedStorage:SetAttribute("DayActive", false)
			dayEnded:Fire(day)
			countdown(Config.Day.BreakSeconds)
		end
	end)
end

return DayManager
