-- Since the clankers are too full of themselves for flesh related temperature stuff.
-- This human update is purely for the clankers. Hence why it's called clankerUpdate.

THERMClankers = {}
NTTHERMRobot = {}

NTTHERMRobot.UpdateLimbAfflictions = {

	--temperature
	rtemperature = {
		min = 1,
		max = 101,
		update = function(c, limbaff, i, type)
			if limbaff[i].strength > 0 then
				if THERM.GetCharacter(c.character.ID) ~= nil then
					local NormalBodyTemp = FetchConfigStats().NormalBodyTemp
					local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
					local HyperthermiaLevel = FetchConfigStats().HyperthermiaLevel
					local AffectBodyCold = FetchOtherStats().AffectBodyCold
					local AffectBodyWarm = FetchOtherStats().AffectBodyWarm
					local TorsoTempStrength = HF.GetAfflictionStrengthLimb(c.character, LimbType.Torso, "temperature", 0)
					-- CompromisedTemp is the value at which the body will struggle to generate it's own heat or cool down. (You're cooked essentially.)
					local CompromisedColdTemp = HypothermiaLevel/1.5
					local CompromisedHotTemp = HyperthermiaLevel*1.5
					local CompromisedTempVal = 1
					-- Calculate new temperature
					limbaff[i].strength = limbaff[i].strength + THERM.CalculateTemperature(limbaff.wet.strength,c.character,type)
					-- Calculate CompromisedTempVal: Being too low or high in temperature will make the body slower to reach normal body temp.
					-- The division by three is a scaling feature, i'm too lazy to make it a variable.
					if limbaff[i].strength < CompromisedColdTemp then
						CompromisedTempVal = (CompromisedColdTemp/limbaff[i].strength)/3
					-- The division by five is a scaling feature as well, same as last one.
					elseif limbaff[i].strength > CompromisedHotTemp then
						CompromisedTempVal = (limbaff[i].strength/CompromisedHotTemp)/5
					end

						-- Make torso colder or warmer based off limb temp being lower then certain point.
					if type ~= LimbType.Torso then 
						-- Slight optimization, if the temps are the same don't calculate.
						if TorsoTempStrength ~= limbaff[i].strength then
							local TempDiffs = ApplyHeatDifference(c.character,TorsoTempStrength,LimbType.Torso,limbaff[i].strength,type)
							HF.AddAfflictionLimb(c.character, "temperature", LimbType.Torso, TempDiffs.ToLimbDiff, c.character)
							limbaff[i].strength = limbaff[i].strength + TempDiffs.FromLimbDiff
						end
						if type == LimbType.Head then
							if limbaff[i].strength < HypothermiaLevel then
								HF.SetAffliction(c.character, "overlay_ice", HF.Clamp(5/limbaff[i].strength*150,0,60))
							elseif limbaff[i].strength > HyperthermiaLevel then
								HF.SetAffliction(c.character, "overlay_fire", HF.Clamp(limbaff[i].strength/NormalBodyTemp*50,0,100))
							else
								HF.SetAffliction(c.character, "overlay_ice", 0)
								HF.SetAffliction(c.character, "overlay_fire", 0)
							end
							if limbaff[i].strength < 2 then
								c.afflictions.cerebralhypoxia.strength = c.afflictions.cerebralhypoxia.strength + (.05 * NT.Deltatime)
							elseif limbaff[i].strength < HypothermiaLevel/NTTHERM.ExtremeHypothermiaScaling/1.5 then
								NTC.SetSymptomTrue(c.character, "sym_lightheadedness", 5)
							elseif limbaff[i].strength > HyperthermiaLevel * NTTHERM.MediumHyperthermiaScaling then
								NTC.SetSymptomTrue(c.character, "sym_fever", 5)
							end
                        end
					else
						-- Give hypothermia
						if limbaff[i].strength < HypothermiaLevel then
							c.afflictions.hypothermia.strength = 100
							if limbaff[i].strength < HypothermiaLevel * NTTHERM.ExtremeHypothermiaScaling then
							NTC.SetSymptomTrue(c.character, "dyspnea", 2)
							end
						end
						-- Give hyperthermia
						if limbaff[i].strength > HyperthermiaLevel then
							c.afflictions.hyperthermia.strength = 100
							-- Get burnt nerd
							if limbaff[i].strength > HyperthermiaLevel * NTTHERM.ExtremeHyperthermiaScaling * 1.05 then
								limbaff.burn.strength = limbaff.burn.strength + (.5 * NT.Deltatime)
							elseif  limbaff[i].strength > HyperthermiaLevel * NTTHERM.ExtremeHyperthermiaScaling * 1.3 then
								limbaff.burn.strength = limbaff.burn.strength + (2 * NT.Deltatime)
							end
						end
						-- Transfer heat from body to rest of character for accurate gameplay provided by thou Rat Jaccuzi
						limbaff[i].strength = limbaff[i].strength + TransferBodyHeat(c.character,TorsoTempStrength)
					end

					-- Passive temperature reactions
					-- Warm up if cold.
					local RoomTempGain = GetRoomTempAddition(c.character,type)
					local AmputatedLimbValue = HF.BoolToNum(NT.LimbIsAmputated(c.character, type),1) + 1
					if limbaff[i].strength < NormalBodyTemp then
						limbaff[i].strength = HF.Clamp(limbaff[i].strength
							+ RoomTempGain + (.05
								/CompromisedTempVal
									*(c.afflictions.bloodpressure.strength
										/100)/AmputatedLimbValue
											* NT.Deltatime),1,NormalBodyTemp)
					-- Cool down if warm
					elseif limbaff[i].strength > NormalBodyTemp then
						limbaff[i].strength = HF.Clamp(limbaff[i].strength 
								- RoomTempGain - (.05
									/CompromisedTempVal
										*(c.afflictions.bloodpressure.strength
											/100)/AmputatedLimbValue 
											 * NT.Deltatime),NormalBodyTemp,101)
					end 
				end
				return
			-- Set Temperature since the current is 0.
			else
				limbaff[i].strength = FetchConfigStats().NormalBodyTemp
			end
		end,
	},

	--warmth
	rwarmth = {
		update = function(c, limbaff, i, type)
			local WarmingAbility = FetchConfigStats().WarmingAbility
			local WarmthScaling = 3
			local MaxWarmingTemp = FetchOtherStats().MaxWarmingTemp
			-- Warm up skin.
			if limbaff[i].strength > 0 then
				limbaff.temperature.strength = limbaff.temperature.strength 
					+ (WarmingAbility
					/(limbaff.temperature.strength/MaxWarmingTemp)
					/WarmthScaling 
					* NT.Deltatime)
				limbaff[i].strength = limbaff[i].strength - 1.7 * NT.Deltatime
				if type == LimbType.Torso and c.afflictions.internalbleeding.strength > 0 then
					c.afflictions.internalbleeding.strength = c.afflictions.internalbleeding.strength
						+ 0.2 * NT.Deltatime
				end
			end
		end,
	},

	--iced to lower temperature
	riced = {
		update = function(c, limbaff, i, type)
			local CoolingAbility = FetchConfigStats().WarmingAbility
			local MaxCoolingTemp = FetchOtherStats().MaxCoolingTemp
			local CoolScaling = -2.9
			-- over time skin temperature goes up again
			if limbaff[i].strength > 0 then
				limbaff[i].strength = limbaff[i].strength - 1.7 * NT.Deltatime
				limbaff.temperature.strength = limbaff.temperature.strength 
					+ ((CoolingAbility
					/(MaxCoolingTemp/limbaff.temperature.strength))
					* CoolScaling  
					* NT.Deltatime)
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
	rwet = {
		update = function(c, limbaff, i, type)
			-- cool down skin.
			if limbaff[i].strength > 0 then
				local DryingSpeed = FetchConfigStats().DryingSpeed
				local WetStrength = limbaff[i].strength
				local WetTempAddition = .1
				if limbaff.bandaged.strength > 0 then
					limbaff.dirtybandage.strength = limbaff.dirtybandage.strength + (WetStrength/4 * NT.Deltatime)
					limbaff.bandaged.strength = limbaff.bandaged.strength - (WetStrength/4 * NT.Deltatime)
				end
				limbaff.temperature.strength = limbaff.temperature.strength 
					+ (.05
						* (WetStrength + WetTempAddition) 
							* NT.Deltatime)
			end
		end,
	},
}

NTTHERMRobot.UpdateAfflictions = {

	--Hypothermia 
	rhypothermia = {
		max = 100,
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
				local NormalBodyTemp = FetchConfigStats().NormalBodyTemp
				local TorsoTemp = HF.GetAfflictionStrength(c.character, "temperature", 0)
				c.afflictions.bloodpressure.strength = c.afflictions.bloodpressure.strength + (.2 * NT.Deltatime)
				if TorsoTemp < 2 then
					c.afflictions.frozen_vessels.strength = c.afflictions.frozen_vessels.strength + (2 * NT.Deltatime)
					NTC.SetSymptomTrue(c.character, "triggersym_coma", 2)
				end
				if TorsoTemp < HypothermiaLevel/NTTHERM.ExtremeHypothermiaScaling/2 then
					NTC.SetSymptomTrue(c.character, "triggersym_respiratoryarrest", 2)
					c.afflictions.immunity.strength = c.afflictions.immunity.strength - (.5 * NT.Deltatime)
				end
				if TorsoTemp < HypothermiaLevel/NTTHERM.ExtremeHypothermiaScaling/1.5 then
					c.afflictions.bloodpressure.strength = c.afflictions.bloodpressure.strength + (.1 * NT.Deltatime)
					c.afflictions.pulmonary_edema.strength = c.afflictions.pulmonary_edema.strength 
						+ (THERM.GetCharacter(c.character.ID).LimbWaterValues.TorsoV/50 
						* c.afflictions.lungdamage.strength/50
						* NT.Deltatime)
					NTC.SetSymptomTrue(c.character, "sym_paleskin", 5)
					NTC.SetSymptomTrue(c.character, "sym_unconsciousness", 2)

				end
				if TorsoTemp < HypothermiaLevel/NTTHERM.ExtremeHypothermiaScaling then
					c.afflictions.bloodpressure.strength = c.afflictions.bloodpressure.strength + (.05 * NT.Deltatime)
					NTC.SetSymptomTrue(c.character, "hypoventilation", 2)
				end
				if  HF.GetAfflictionStrength(c.character, "temperature", 0) > HypothermiaLevel then
					c.afflictions.hypothermia.strength = 0
				end
			end
		end,
	},

	--Hyperthermia
	rhyperthermia = {
		max = 100,
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				local Death = (5 * NT.Deltatime)
				local HyperthermiaLevel = FetchConfigStats().HyperthermiaLevel
				local NormalBodyTemp = FetchConfigStats().NormalBodyTemp
				local TorsoTemp = HF.GetAfflictionStrength(c.character, "temperature", 0)
				c.afflictions.bloodpressure.strength = c.afflictions.bloodpressure.strength - (.2 * NT.Deltatime)
				if TorsoTemp < HyperthermiaLevel then
					c.afflictions.hyperthermia.strength = 0
					return
				end
				if TorsoTemp > HyperthermiaLevel and TorsoTemp < HyperthermiaLevel * NTTHERM.ExtremeHyperthermiaScaling * 1.05 then
					NTC.SetSymptomTrue(c.character, "sym_sweating", 2)
				end
				if TorsoTemp > HyperthermiaLevel * NTTHERM.ExtremeHyperthermiaScaling then
					NTC.SetSymptomTrue(c.character, "sym_headache", 2)
				end
				if TorsoTemp > HyperthermiaLevel * NTTHERM.ExtremeHyperthermiaScaling * 1.05 then
					c.afflictions.heat_stroke.strength = c.afflictions.heat_stroke.strength + (1 * NT.Deltatime)
					HF.AddAffliction(c.character, "huskinfection", -2.5 * NT.Deltatime, c.character) -- EXTERMINATE THE BITCH ASS HUSK. JUSTICE FOR ARTIE DOOLITTLE. THOSE BASTARDS SLIMED HIM OUT. God speed artie, love you.
				end
				if TorsoTemp > HyperthermiaLevel * NTTHERM.ExtremeHyperthermiaScaling * 1.2 then
					c.afflictions.cerebralhypoxia.strength = c.afflictions.cerebralhypoxia.strength + Death
					c.afflictions.lungdamage.strength = c.afflictions.lungdamage.strength + Death
					c.afflictions.liverdamage.strength = c.afflictions.liverdamage.strength + Death
					c.afflictions.heartdamage.strength = c.afflictions.heartdamage.strength + Death
					c.afflictions.kidneydamage.strength = c.afflictions.kidneydamage.strength + Death
				end
			end
		end,
	},

	--Give temperature affliction, this is used to hook water and fire related stuff to the player for temperature.
	-- Those aren't stored in here since they have a independent tick rate.
	rgivetemp = {
		max = 3,
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				return
			else
				THERM.IntiateCharacterTemp(c.character)
				THERM.ValidateThermalCharacterData()
				c.afflictions[i].strength = 3
			end
		end,
	},

	-- Heated Diving Suit
	rheated_diving_suit = {
		max = 100,
		update = function(c, i)
			-- Used for suits that have automatic heating or prebuilt power. I'm too scared to refactor this.
			local ExceptedSuits = {["respawndivingsuit"] = {valid = true,index = 0},["exosuit"] = {valid = true, index =1},["clownexosuit"] = {valid = true, index = 1}, --Vanilla Ice Cream
			["SAFS"] = {valid = true, index = 1},["SAFS_V7"] = {valid = true, index = 1},["SAFS_nāga"] = {valid = true, index = 1},["SAFS_snow"] = {valid = true, index = 1},["SAFS_yellow"] = {valid = true, index = 1},  -- Safs compatibility
			["SAFS_manual"] = {valid = true, index = 1},["SAFS_seaweed"] = {valid = true, index = 1},["SAFS_clown"] = {valid = true, index = 1},["SAFS_camo"] = {valid = true, index = 1},["SAFS_moon"] = {valid = true, index = 1},  -- Safs compatibility
			["SAFS_onyx"] = {valid = true, index = 1},["SAFS_camo2"] = {valid = true, index = 1},  -- Safs compatibility
			["ek_armored_hardsuit"] = {valid = true, index = 1},["ek_armored_hardsuit_paintbandit"] = {valid = true, index = 1},["ek_armored_hardsuit_paintmercenary"] = {valid = true, index = 1},["ek_armored_hardsuit2"] = {valid = true, index = 1} -- EK
			,["ek_armored_hardsuit2_paintbandit"] = {valid = true, index = 1},["ek_armored_hardsuit2_paintmercenary"] = {valid = true, index = 1}} -- EK
			local IndexedSuits = {["pucs"] = 2} -- Used for suits that have extra storage. I.E pucs.
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			if c.afflictions[i].strength > 0 then
				local CharacterTable = THERM.GetCharacter(c.character.ID,c.character)
				local LimbsToCheck2 = {LimbType.Head,LimbType.Torso,LimbType.RightArm,LimbType.LeftArm,LimbType.LeftLeg,LimbType.RightLeg}
				for index, limb in pairs(LimbsToCheck2) do
					local LimbTemp = HF.GetAfflictionStrengthLimb(c.character, limb, "temperature", 0)
					if LimbTemp < FetchConfigStats().NormalBodyTemp then
						local WaterKey = THERM.LimbToWaterLimbV(limb)
						local WaterCounter = HF.Clamp(CharacterTable.LimbWaterValues[WaterKey]/1,.1,1)
						local IsCyber = HF.BoolToNum(THERM.IsLimbCyber(c.character,limb),1) + 1
						HF.AddAfflictionLimb(c.character, "temperature", limb, 
											(HypothermiaLevel/LimbTemp
											/25) 
											* (c.afflictions[i].strength
											/100) 
											* 20
											* IsCyber
											* WaterCounter 
											* NT.Deltatime)
					end
				end
			end
			local DivingSuit = c.character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
			local Bag = c.character.Inventory.GetItemInLimbSlot(InvSlotType.Bag)
			local BatteryConsumption = .3 * NT.Deltatime
			if c.character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes) ~= nil and (c.character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("diving") or c.character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("deepdivinglarge") or c.character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("deepdiving")) then
				-- Internal Heater Check
				local Index = IndexedSuits[tostring(DivingSuit.Prefab.Identifier)] or IndexedSuits[tostring(DivingSuit.Prefab.VariantOf)] or 1
				-- Suit Compatibility Mode is on
				if NTConfig.Get("SuitCompatiblityMode", false) then
					c.afflictions[i].strength = c.afflictions[i].strength + (5 * NT.Deltatime)
					return
				end
				if (DivingSuit.HasTag("thermal") or (Index ~= 1 and DivingSuit.Prefab.VariantOf ~= "" and DivingSuit.Prefab.VariantOf.HasTag("thermal"))) and DivingSuit.OwnInventory.GetItemAt(Index) ~= nil and DivingSuit.OwnInventory.GetItemAt(Index).Condition > 1 then
					local BatteryCell = c.character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).OwnInventory.GetItemAt(Index)
					if BatteryCell.Condition > 1 then
						BatteryCell.Condition = BatteryCell.Condition - BatteryConsumption
						c.afflictions[i].strength = c.afflictions[i].strength + (5 * NT.Deltatime)
						return
					end
					c.afflictions[i].strength = 0
					return
				-- External Heater Check
				elseif Bag ~= nil and Bag.Prefab.Identifier == "esh" and Bag.OwnInventory.GetItemAt(0) ~= nil and Bag.OwnInventory.GetItemAt(0).Condition > 1 then
					local BatteryCell = Bag.OwnInventory.GetItemAt(0)
					if BatteryCell ~= nil and BatteryCell.Condition > 1 then
						BatteryCell.Condition = BatteryCell.Condition - BatteryConsumption
						c.afflictions[i].strength = c.afflictions[i].strength + (5 * NT.Deltatime)
						return
					end
					c.afflictions[i].strength = 0
					return
				-- ExceptedSuits
				elseif ExceptedSuits[tostring(DivingSuit.Prefab.Identifier)] ~= nil then
					local HeaterIndex = ExceptedSuits[tostring(DivingSuit.Prefab.Identifier)].index
					if HeaterIndex ~= 0 
						and DivingSuit.OwnInventory.GetItemAt(HeaterIndex) 
						and DivingSuit.OwnInventory.GetItemAt(HeaterIndex).Condition > 1 then
						c.afflictions[i].strength = c.afflictions[i].strength + (5 * NT.Deltatime)
						return
					elseif HeaterIndex == 0 then
						c.afflictions[i].strength = c.afflictions[i].strength + (5 * NT.Deltatime)
						return
					end
					c.afflictions[i].strength = 0
					return
				end
				c.afflictions[i].strength = 0
				return
			-- Immersive Diving Gear compat (Yes this is basically duplicated code, you're welcome.)
			elseif c.character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes) ~= nil
			 	and THERM.ImmersiveDivingGearEquipped(c.character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes),c.character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)) then
				if NTConfig.Get("SuitCompatiblityMode", false) then
					c.afflictions[i].strength = c.afflictions[i].strength + (5 * NT.Deltatime)
					return
				elseif DivingSuit.OwnInventory ~= nil and DivingSuit.OwnInventory.GetItemAt(0) ~= nil and DivingSuit.OwnInventory.GetItemAt(0).Condition > 1 then
					local BatteryCell = DivingSuit.OwnInventory.GetItemAt(0)
					BatteryCell.Condition = BatteryCell.Condition - BatteryConsumption
					c.afflictions[i].strength = c.afflictions[i].strength + (5 * NT.Deltatime)
					return
				elseif Bag ~= nil and Bag.Prefab.Identifier == "esh" and Bag.OwnInventory.GetItemAt(0) ~= nil and Bag.OwnInventory.GetItemAt(0).Condition > 1 then
					local BatteryCell = Bag.OwnInventory.GetItemAt(0)
					if BatteryCell ~= nil and BatteryCell.Condition > 1 then
						BatteryCell.Condition = BatteryCell.Condition - BatteryConsumption
						c.afflictions[i].strength = c.afflictions[i].strength + (5 * NT.Deltatime)
						return
					end
					c.afflictions[i].strength = 0
					return
				end
				c.afflictions[i].strength = 0
			end
			c.afflictions[i].strength = 0
		end,
	},
}
