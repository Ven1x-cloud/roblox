-- Shared, early-prototype tuning values for the Berumida lobby and later expedition.
-- Keep monetization identifiers out of this shared module; none are configured yet.
return {
	DayCycleSeconds = 180,
	DaylightSeconds = 120,
	NightSeconds = 60,

	Lobby = {
		MaxPartySize = 5,
		MaxPlayersPerSavedWorld = 10,
	},

	VIP = {
		TargetWalkSpeed = 30,
		DoubleJumpEnabled = true,
		BoatSpeedMultiplier = 2,
		ShieldRechargeGameDays = 10,
	},

	Bandages = {
		RegularHealMaxHealthFraction = 0.5,
		MutantSelfActivationSeconds = 30,
		MutantAllyReviveSeconds = 30,
	},
}
