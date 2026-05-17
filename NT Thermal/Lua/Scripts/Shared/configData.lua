-- The base of this code has been lifted from NT Eyes.

-- The default normal body temp is 37c, however due to the fact I can't have an affliction be at 0 (If I can let me know.), I offset all temp related values by 1. So normal body temp is now 38 and so on so forth.
-- Another note, Added 'New' prefix since it was bugged when I didn't, I'm not too sure why that was the case.

NTTHERM.ConfigData = {
	NTTHERM_Header1 = { name = NTTHERM.Name, type = "category" },

	NTTHERM_Header2 = { name = "---------- Temperature Settings ----------", type = "category" },
	
	NewHypothermiaLevel = {
		name = "Hypothermia level",
		default = 36,
		range = { 0, 100 },
		type = "float",
		description = "Sets the value at which hypothermia will occur.",
		group = true,
		resettable = true,
	},
	NewHyperthermiaLevel = {
		name = "Hyperthermia level",
		default = 39,
		range = { 0, 100 },
		type = "float",
		description = "Sets the value at which hyperthermia will occur.",
		group = true,
		resettable = true,
	},
	NewNormalBodyTemp = {
		name = "Normal Body Temp",
		default = 38,
		range = { 0, 100 },
		type = "float",
		description = "The normal temperature of the body.\nWARNING: Setting this value to a substantially higher or lower value will cause all characters to remain at their current temperature whilst they advance to this.\nProceed with caution.",
		group = true,
		resettable = true,
	},
	NewHypothermiaScaling = {
		name = "Hypothermia Scaling",
		default = 5,
		range = { 0, 10 },
		type = "float",
		description = "Multiplies hypothermia by this value.",
		group = true,
		resettable = true,
	},
	NewHyperthermiaScaling = {
		name = "Hyperthermia Scaling",
		default = 1,
		range = { 0, 10 },
		type = "float",
		description = "Multiplies hyperthermia by this value.",
		group = true,
		resettable = true,
	},
	NewWarmingAbility = {
		name = "Warming Ability",
		default = .05,
		range = { 0, 1 },
		type = "float",
		description = "How much the warmth affliction provides in temperature.",
		group = true,
		resettable = true,
	},
	NewDryingSpeed = {
		name = "Drying Speed",
		default = -.1,
		range = { -1, 0 },
		type = "float",
		description = "How fast the wet affliction wears off per Thermal interval.",
		group = true,
		resettable = true,
	},
	ETempScaling = {
		name = "External Temperature Scaling",
		default = 1.5,
		range = { 1, 10 },
		type = "float",
		description = "Multiplies incoming external temperature changes by this value. Water, Fire etc.",
		group = true,
		resettable = true,
	},
	HeaterBatteryConsumption = {
		name = "Heater Battery Consumption",
		default = 0.2,
		range = {0, 1},
		type = "float",
		description = "How much of a heater's battery condition is used per NT interval.",
		group = true,
		resettable = true,
	},
	ThermalRoomCalcInterval = {
		name = "Room Temperature Calculation Intervals",
		default = 300,
		range = {10, 500},
		type = "float",
		description = "The time between temperature calculations of rooms. Higher values mean better performance but less accuracy. Lower values mean worse performance but more accuracy.",
		group = true,
		resettable = true,
	},
	ShockMargin = {
		name = "Thermal Shock Margin",
		default = 200,
		range = {1, 400},
		type = "float",
		description = "The margin in which thermal shock will activate. Extremely sensitive. Higher values mean less margin, lower means higher margin.",
		group = true,
		resettable = true,
	},

	NTTHERM_Header3 = { name = "---------- Compatibility Toggles ----------", type = "category" },

	SuitCompatiblityMode = { name = "Suit Compatibility Mode", default = false, type = "bool", description = "This makes all suits heated by default, rather than using batteries or external heaters. This should be used only when needed and a patch isn't out." },
	BotSuitSafteyMode = { name = "Bot Suit Compatibility Mode", default = true, type = "bool", description = "This makes all suits worn by a bot heated. Useful so you don't have to babysit them."},
	BotTempIgnoreMode = { name = "Temperature Ignores Bot Mode", default = false, type = "bool", description = "This makes all bots immune to temperature and it's effects. This should theoretically give a performance boost."},
	PressureStabilizerTemperature = { name = "Pressure Stabilizers Stabilize Temperature", default = false, type = "bool", description = "This setting makes pressure stabilizers also stabilize temperature, on top of pressure and oxygen." },
	
	NTTHERM_Header4 = { name = "---------- Performance Settings ----------", type = "category" },

	SimpleWaterCalculation = { name = "Simple Water Calculations", default = false, type = "bool", description = "This setting makes water calculations extremely simple, the game will make you wet, only when 'in' water. However due to barotrauma limitations this is highly inaccurate." },
	HeatTransferToggle = { name = "Fire Transfers Heat", default = true, type = "bool", description = "This setting allows heat to transfer between hulls in a submarine. This should be left on for the intended experience." },
	PerformanceMode = { name = "Performance Mode", default = true, type = "bool", description = "This mode increases performance, however it sometimes might make inaccurate calculation. There really shouldn't be a difference though." },
}

--this adds above config options to the Neurotrauma config menu
NTConfig.AddConfigOptions(NTTHERM)