-- Early prototype clock. This currently runs in the lobby place so the cycle can be tested.
-- Move/enable it in the reserved expedition place once that place exists.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("BerumidaPrototypeConfig"))
local fullCycleSeconds = Config.DayCycleSeconds
local daylightSeconds = Config.DaylightSeconds
local nightSeconds = Config.NightSeconds

assert(daylightSeconds > 0 and nightSeconds > 0, "Day and night must both have a duration")
assert(daylightSeconds + nightSeconds == fullCycleSeconds, "Day and night must add up to the full cycle")

local elapsedSeconds = 0
local displayedDay = 1
local displayedNight = false
local refreshAccumulator = 0

Lighting:SetAttribute("GameDay", displayedDay)
Lighting:SetAttribute("IsNight", displayedNight)
Lighting:SetAttribute("DayCycleSeconds", fullCycleSeconds)
Lighting:SetAttribute("DaylightSeconds", daylightSeconds)
Lighting:SetAttribute("NightSeconds", nightSeconds)
Lighting:SetAttribute("MaxPartySize", Config.Lobby.MaxPartySize)
Lighting:SetAttribute("MaxPlayersPerSavedWorld", Config.Lobby.MaxPlayersPerSavedWorld)
Lighting.ClockTime = 6

local function clockTimeForCycle(cycleSeconds)
	if cycleSeconds < daylightSeconds then
		local daytimeProgress = cycleSeconds / daylightSeconds
		return 6 + daytimeProgress * 12
	end

	local nighttimeProgress = (cycleSeconds - daylightSeconds) / nightSeconds
	return (18 + nighttimeProgress * 12) % 24
end

RunService.Heartbeat:Connect(function(deltaTime)
	elapsedSeconds = elapsedSeconds + deltaTime
	refreshAccumulator = refreshAccumulator + deltaTime
	if refreshAccumulator < 0.1 then
		return
	end
	refreshAccumulator = 0

	local cycleSeconds = elapsedSeconds % fullCycleSeconds
	local newDay = math.floor(elapsedSeconds / fullCycleSeconds) + 1
	local isNight = cycleSeconds >= daylightSeconds

	Lighting.ClockTime = clockTimeForCycle(cycleSeconds)

	if newDay ~= displayedDay then
		displayedDay = newDay
		Lighting:SetAttribute("GameDay", displayedDay)
	end
	if isNight ~= displayedNight then
		displayedNight = isNight
		Lighting:SetAttribute("IsNight", displayedNight)
	end
end)
