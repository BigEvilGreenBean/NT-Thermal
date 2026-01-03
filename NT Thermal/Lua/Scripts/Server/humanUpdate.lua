-- Most of this has been lifted from NT Eyes.
-- Table of characters and their temp info.
THERMCharacters = {}
-- Cold
NTTHERM.ExtremeHypothermiaScaling = 6
NTTHERM.MediumHypothermiaScaling = 2
NTTHERM.LowHypothermiaScaling = 1
-- Hot
NTTHERM.ExtremeHyperthermiaScaling = 1.8
NTTHERM.MediumHypothermiaScaling = 1.3
NTTHERM.LowHyperthermiaScaling = 1

-- Function used to take two limbs and apply the heat difference to both.
local function ApplyHeatDifference(character, ToLimbTemp, ToLimbType, FromLimbTemp, FromLimbType)
	-- Make sure the temperature isn't zero. Else temperature shouldn't be added and or removed.
	if FromLimbTemp > 1 then
		local TempDifference = ((ToLimbTemp/FromLimbTemp) - 1)/-1
		HF.AddAfflictionLimb(character, "temperature", ToLimbType, TempDifference, character)
		HF.AddAfflictionLimb(character, "temperature", FromLimbType, TempDifference * -1, character)
	end
end


-- Function used to return config stats.
local function FetchConfigStats()
	local ConfigStats = 
		{
		NormalBodyTemp = NTConfig.Get("NewNormalBodyTemp", 38),
		HypothermiaLevel = NTConfig.Get("NewHypothermiaLevel", 36),
		HyperthermiaLevel = NTConfig.Get("NewHyperthermiaLevel", 39),
		WarmingAbility = NTConfig.Get("NewWarmingAbility", .2),
		DryingSpeed = NTConfig.Get("NewDryingSpeed", -.1)
		}
	return ConfigStats
end


-- Function used to return random stats that I can't think of a better name for.
local function FetchOtherStats()
	local Stats =
	{
	AffectBodyCold = 1.5,
	AffectBodyWarm = 1.5,	
	LimbsToCheck = {LimbType.Head,LimbType.RightArm,LimbType.LeftArm,LimbType.LeftLeg,LimbType.RightLeg},
	BloodAfflictions = {"elevated_core_temperature","diuretics","thrombolytics","a.a.f.n"}
	}
	return Stats
end


-- Function used to transfer heat between limbs and torso.
local function TransferBodyHeat(character, TorsoTemp)
	local limbTemp = nil
	local TempDifference = nil
	-- Check to make sure that the temp isn't too low, else the torso will yoink temperature from nowhere. It shouldn't due to code I implemented in the ApplyHeatDifference func but this is still here as a failsafe.
	if not (TorsoTemp < 1.5) then
		for index, limb in pairs(FetchOtherStats().LimbsToCheck) do
			limbTemp = HF.GetAfflictionStrengthLimb(character, limb, "temperature", NTConfig.Get("NormalBodyTemp", 38))
			-- Formula for heat transfer
			ApplyHeatDifference(character,limbTemp,limb,TorsoTemp,LimbType.Torso)
			end
	end 
end


NTTHERM.UpdateLimbAfflictions = {

	--temperature
	temperature = {
		update = function(c, limbaff, i, type)
			local NormalBodyTemp = FetchConfigStats().NormalBodyTemp
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			local HyperthermiaLevel = FetchConfigStats().HyperthermiaLevel
			local AffectBodyCold = FetchOtherStats().AffectBodyCold
			local AffectBodyWarm = FetchOtherStats().AffectBodyWarm
			local TorsoTempStrength = HF.GetAfflictionStrengthLimb(c.character, LimbType.Torso, "temperature", NormalBodyTemp)
			-- Using limbaff[i].strength doesn't work for me for some reason, probably since I lack the required neurons. If you can fix it thank you and the rat jacuzzi overlord.
			local LimbStrength = HF.GetAfflictionStrengthLimb(c.character, type, "temperature", NormalBodyTemp)
			-- CompromisedTemp is the value at which the body will struggle to generate it's own heat or cool down. (You're cooked essentially.)
			local CompromisedColdTemp = HypothermiaLevel/1.5
			local CompromisedHotTemp = HyperthermiaLevel*1.5
			local CompromisedTempVal = 1

			-- Calculate CompromisedTempVal: Being too low or high in temperature will make the body slower to reach normal body temp.
			-- The division by three is a scaling feature, i'm too lazy to make it a variable.
			if limbaff[i].strength < CompromisedColdTemp then
				CompromisedTempVal = (CompromisedColdTemp/limbaff[i].strength)/3
			end
			-- The division by five is a scaling feature as well, same as last one.
			if limbaff[i].strength > CompromisedHotTemp then
				CompromisedTempVal = (limbaff[i].strength/CompromisedHotTemp)/5
			end

				-- Make torso colder or warmer based off limb temp being lower then certain point.
			if type ~= LimbType.Torso then 
				if limbaff[i].strength < NormalBodyTemp/AffectBodyCold or limbaff[i].strength > NormalBodyTemp * AffectBodyWarm then
					ApplyHeatDifference(c.character,TorsoTempStrength,LimbType.Torso,LimbStrength,type)
				end
			else
				-- Give hypothermia
				if limbaff[i].strength < HypothermiaLevel then
					HF.AddAfflictionLimb(c.character, "hypothermia", LimbType.Torso,
					100)
					-- Give shivers
					if limbaff[i].strength < HypothermiaLevel/NTTHERM.MediumHypothermiaScaling and limbaff[i].strength > HypothermiaLevel/NTTHERM.ExtremeHypothermiaScaling then
						NTC.SetSymptomTrue(c.character, "sym_shivers", 5)
					elseif limbaff[i].strength < HypothermiaLevel/NTTHERM.ExtremeHypothermiaScaling then
						NTC.SetSymptomTrue(c.character, "sym_numb", 10)
					end
				end
			end

			-- Passive temperature reactions
			-- Warm up if cold.
			if LimbStrength < NormalBodyTemp then
				HF.SetAfflictionLimb(c.character, "temperature", type, 
				HF.Clamp(LimbStrength + (.2/CompromisedTempVal), 1, NormalBodyTemp),
				c.character, LimbStrength)
			end
			-- Cool down if warm
           	if LimbStrength > NormalBodyTemp then
				HF.SetAfflictionLimb(c.character, "temperature", type, 
				HF.Clamp(LimbStrength - (.1/CompromisedTempVal), NormalBodyTemp, 101),
				c.character, LimbStrength)
			end 

			-- Afflictions of temperature
				-- Give hyperthermia
			if limbaff[i].strength > HyperthermiaLevel then
				HF.AddAfflictionLimb(c.character, "hyperthermia", LimbType.Torso,
				100)
			end
				-- Transfer heat from body to rest of character for accurate gameplay provided by thou Rat Jaccuzi
				TransferBodyHeat(c.character,TorsoTempStrength)
			if type == LimbType.Head then
				if limbaff[i].strength < HypothermiaLevel then
					NTC.SetSymptomTrue(c.character, "sym_runny_nose", 10)
				end
			end

		end,
	},

	--warmth
	warmth = {
		update = function(c, limbaff, i, type)
			local WarmingAbility = FetchConfigStats().WarmingAbility
			local HyperthermiaLevel = FetchConfigStats().HyperthermiaLevel
			local WarmthScaling = 20
			-- Warm up skin.
			if limbaff[i].strength > 0 then
				limbaff.temperature.strength = limbaff.temperature.strength +
				(HyperthermiaLevel
				/(limbaff.temperature.strength + WarmingAbility)
				/WarmthScaling)
				limbaff[i].strength = limbaff[i].strength - 1.7 * NT.Deltatime
			end
		end,
	},

	--iced to lower temperature
	iced = {
		update = function(c, limbaff, i, type)
			local CoolingAbility = FetchConfigStats().WarmingAbility * -1
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			local CoolScaling = 10
			-- over time skin temperature goes up again
			if limbaff[i].strength > 0 then
				limbaff[i].strength = limbaff[i].strength - 1.7 * NT.Deltatime
				limbaff.temperature.strength = limbaff.temperature.strength + 
				((limbaff.temperature.strength + CoolingAbility)
				/HypothermiaLevel
				/5)
			end
			-- iced effects
			if limbaff[i].strength > 0 then
				c.stats.speedmultiplier = c.stats.speedmultiplier * 0.95 -- 5% slow per limb
				if type == LimbType.Torso then
					c.afflictions.internalbleeding.strength = c.afflictions.internalbleeding.strength
						- 0.2 * NT.Deltatime
				end
			end
		end,
	},

	--wet
	wet = {
		update = function(c, limbaff, i, type)
			-- cool down skin.
			if limbaff[i].strength > 0 then
				local DryingSpeed = FetchConfigStats().DryingSpeed
				local WetStrength = HF.GetAfflictionStrengthLimb(c.character, LimbType.Torso, "wet", 1)
				limbaff.temperature.strength = limbaff.temperature.strength + DryingSpeed * (WetStrength + 1)
			end
		end,
	},
}


NTTHERM.UpdateAfflictions = {

	--Hypothermia 
	hypothermia = {
		max = 100,
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
				local NormalBodyTemp = FetchConfigStats().NormalBodyTemp
				NTC.SetSymptomTrue(c.character, "sym_cold", 5)
				if  HF.GetAfflictionStrength(c.character, "temperature", NormalBodyTemp) > HypothermiaLevel then
					c.afflictions.hypothermia.strength = 0
				end
			end
		end,
	},

	--Hyperthermia 
	hyperthermia = {
		max = 100,
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				local HyperthermiaLevel = FetchConfigStats().HyperthermiaLevel
				local NormalBodyTemp = FetchConfigStats().NormalBodyTemp
				NTC.SetSymptomTrue(c.character, "sym_hot", 5)
				if HF.GetAfflictionStrength(c.character, "temperature", NormalBodyTemp) < HyperthermiaLevel then
					c.afflictions.hyperthermia.strength = 0
				end
			end
		end,
	},

	-- Symptoms -----------------------------------------------
	-- Cold
	sym_cold = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and NTC.GetSymptom(c.character, i)
					and HF.GetAfflictionStrength(c.character, "hypothermia", 0) > 0,
				2
			)
		end,
	},

	-- Shivers
	sym_shivers = {
		update = function(c, i)
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and NTC.GetSymptom(c.character, i)
					and HF.GetAfflictionStrength(c.character, "temperature", 0) < HypothermiaLevel/1.5 
					and HF.GetAfflictionStrength(c.character, "temperature", 0) > HypothermiaLevel/2,
				2
			)
		end,
	},

	-- Numb
	sym_numb = {
		update = function(c, i)
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and NTC.GetSymptom(c.character, i)
					and HF.GetAfflictionStrength(c.character, "temperature", 0) < HypothermiaLevel/2,
				2
			)
		end,
	},

	-- Runny Nose
	sym_runny_nose = {
		update = function(c, i)
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and NTC.GetSymptom(c.character, i)
					and HF.GetAfflictionStrengthLimb(c.character, LimbType.Head, "temperature", NTConfig.Get("NormalBodyTemp", 38)) < HypothermiaLevel,
				2
			)
		end,
	},

	-- Hot
	sym_hot = {
		update = function(c, i)
			local HyperthermiaLevel = FetchConfigStats().HyperthermiaLevel
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and NTC.GetSymptom(c.character, i)
					and HF.GetAfflictionStrength(c.character, "temperature", NTConfig.Get("NormalBodyTemp", 38)) > HyperthermiaLevel,
				2
			)
		end,
	},
}


-- Afflictions used for blood related stuff.
NTTHERM.UpdateBloodAfflictions = {

	-- Elevated Core Temp
	elevated_core_temperature = {
		update = function (c, i)
			local NormalBodyTemp = FetchConfigStats().NormalBodyTemp
			local MaxWarmingTemp = NormalBodyTemp * 1.1
			local LimbStrength = HF.GetAfflictionStrength(c.character, "temperature", NormalBodyTemp)
			local BloodPressureMultiplier = 3
			if c.afflictions[i].strength > 0 then
				for index, limb in pairs(FetchOtherStats().LimbsToCheck) do
					HF.AddAfflictionLimb(c.character, "temperature", limb, 
					.1 + (MaxWarmingTemp/LimbStrength)/80 * c.afflictions[i].strength/20)
				end
				-- Side effect of elevated_core_temperature.
				if c.afflictions[i].strength > 30 then
					c.afflictions.bloodpressure.strength = c.afflictions.bloodpressure.strength 
					+ c.afflictions[i].strength/15 * BloodPressureMultiplier
					NTC.SetSymptomTrue(c.character, "sym_lightheadedness", 5)
				end
				if c.afflictions[i].strength > 40 then
					NTC.SetSymptomTrue(c.character, "sym_confusion", 3)
					c.afflictions.seizure.strength = c.afflictions.seizure.strength 
					+ 100
				end
			end
		end
	},

	thrombolytics = {
		update = function (c, i)
			
		end
	},

	diuretics = {
		update = function (c, i)
			
		end
	},

	aaafn = {
		update = function (c, i)
			
		end
	}
}



-- Add to Neuro Limb Afflictions.
for k, v in pairs(NTTHERM.UpdateLimbAfflictions) do
	NT.LimbAfflictions[k] = v
end

-- Add to Neuro Afflictions.
for k, v in pairs(NTTHERM.UpdateAfflictions) do
	NT.Afflictions[k] = v
end

-- Add to neuro afflictions
for k, v in pairs(NTTHERM.UpdateBloodAfflictions) do 
	NT.Afflictions[k] = v
end

-- Add blood afflictions to the hemo anaylzer.
for index, value in pairs(FetchOtherStats().BloodAfflictions) do
	NTC.AddHematologyAffliction(value)
end