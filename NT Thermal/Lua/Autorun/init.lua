-- Most of this code has been lifted from NT Eyes, you should go check it out. Thank you POSTACI.
-- Set up dictonary
NTTHERM = {}
NTTHERM.Name = "Thermal"
NTTHERM.Version = "1.6.9h74"
NTTHERM.VersionNum = 000000001
NTTHERM.MinNTVersion = "A1.12.1"
NTTHERM.MinNTVersionNum = 01120100
NTTHERM.Path = table.pack(...)[1]
-- I don't think this is required.
NTTHERM.UpdateAfflictions = {}
NTTHERM.UpdateLimbAfflictions = {}
NTTHERM.UpdateBloodAfflictions = {}
NTTHERM.OnDamagedMethods = {}
NTTHERM.UsingRoboTrauma = false
NTTHERM.UsingEnhancedReactors = false

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Explosion"], "GetObstacleDamageMultiplier") -- For the Enhanced Reactors compat

Timer.Wait(function ()
    if NTC ~= nil then
        NTC.RegisterExpansion(NTTHERM)

		NTC.AddPreHumanUpdateHook(function (character) -- Used to freeze patients in stasis. Since limbs dont update when stasis is on.
			if HF.GetAfflictionStrength(character, "stasis", 0) > 0 and HF.GetAfflictionStrength(character, "givetemp", 0) > 0 then
				if not (NTConfig.Get("BotTempIgnoreMode", true) and character.IsBot) then
					THERM.ApplyTemperatureUpdate(character.ID)
					local Limbs = {LimbType.Head,LimbType.Torso,LimbType.RightArm,LimbType.LeftArm,LimbType.LeftLeg,LimbType.RightLeg}

					for index, limb in pairs(Limbs) do -- Cool patient.
						local LimbTemp = HF.GetAfflictionStrengthLimb(character, limb, "ntt_temperature", 0)
						HF.AddAfflictionLimb(character, "ntt_temperature", limb,((-.05 * ((LimbTemp/2)/(NTConfig.Get("NewHypothermiaLevel", 36)))) * NT.Deltatime), character)
					end

					if HF.GetAfflictionStrength(character, "cryo_stasis_starter", 0) > 0 then -- We have to force update chilled and warmth.
						for index, limb in pairs(Limbs) do
							if HF.GetAfflictionStrengthLimb(character, limb, "iced", 0) > 0 then
								local CoolingAbility = THERM.FetchConfigStats().WarmingAbility
								local MaxCoolingTemp = THERM.FetchOtherStats().MaxCoolingTemp
								local CoolScaling = -2.9
								local LimbTemp = HF.GetAfflictionStrengthLimb(character, limb, "ntt_temperature", 0)
								local TempAmount = ((CoolingAbility/(MaxCoolingTemp/LimbTemp)) * CoolScaling * NT.Deltatime)
								HF.AddAfflictionLimb(character, "iced", limb,-1.7 * NT.Deltatime, character)
								HF.AddAfflictionLimb(character, "ntt_temperature", limb,TempAmount, character)
							end
							if HF.GetAfflictionStrengthLimb(character, limb, "warmth", 0) > 0 then
								local WarmingAbility = THERM.FetchConfigStats().WarmingAbility
								local WarmthScaling = 4
								local MaxWarmingTemp = THERM.FetchOtherStats().MaxWarmingTemp
								local LimbTemp = HF.GetAfflictionStrengthLimb(character, limb, "ntt_temperature", 0)
								local TempAmount = (WarmingAbility/(LimbTemp/MaxWarmingTemp)/WarmthScaling * NT.Deltatime)
								HF.AddAfflictionLimb(character, "warmth", limb,-1.7 * NT.Deltatime, character)
								HF.AddAfflictionLimb(character, "ntt_temperature", limb,TempAmount, character)
							end
						end
					end

				end
			end
		end)

		local thermal_afflictions = { "sym_hot", "sym_cold", "sym_shivers", "sym_numb", "heat_cramp" } -- Add our NPC symptom announcements.
		table.insert(NT.SymsForNPC, thermal_afflictions)
		
		NT.DrainageAfflictions["pulmonary_edema"] = { xpgain = 3, case = "retractedskin"} -- Make pulmonary_edema go away with drainage.
		
		NTTHERM.UsingEnhancedReactors = EnhancedReactors -- Used to determine if enhanced reactors is on.

		NTC.AddSuturedAffliction("removed_skin", 3, "removed_skin", function (item, usingCharacter, targetCharacter, limb) -- Cure removed skin with sutures.
			HF.AddAfflictionLimb(targetCharacter, "removed_skin", limb.type, -100, usingCharacter)
		end)

		NTC.AddSuturedAffliction("grafted_skin", 3, "grafted_skin", function (item, usingCharacter, targetCharacter, limb) -- Cure removed skin with sutures.
			HF.AddAfflictionLimb(targetCharacter, "grafted_skin", limb.type, -100, usingCharacter)
			THERM.ReduceBurns(targetCharacter,limb,usingCharacter)
		end)

    end
end, 1)

-- Ensure that NT is installed.
Timer.Wait(function()
	if (SERVER or (CLIENT and not Game.IsMultiplayer)) and (NTC == nil) then --check if NT is installed
		print("Error loading NT Thermal: It Seems Neurotrauma isn't loaded!")
		return
	end

    --Server Side scripts
	if SERVER or (CLIENT and not Game.IsMultiplayer) then
    	dofile(NTTHERM.Path .. "/Lua/Scripts/Server/humanupdate.lua") 		-- HumanUpdates.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/heatedsuitlist.lua") 	-- The Heated Diving Suit
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/thermfunctions.lua") 	-- Setup THERM functions.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/playerhooks.lua") 		-- Main Hooks used for a large portion of the mod.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/roomtempcalc.lua") 		-- Script used for a calculating temperature of rooms.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/items.lua") 			-- Item methods.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/modcompat.lua") 		-- Compat.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/translationcompat.lua") -- Translation Compat.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/patches.lua") 			-- Patches.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/debug.lua") 			-- Patches.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/ondamaged.lua") 		-- ondamaged.
	end

end, 1)

-- By Lukako!
Timer.Wait(function()
    dofile(NTTHERM.Path .. "/Lua/Scripts/Shared/configdata.lua") 			--Config.
end, 1)