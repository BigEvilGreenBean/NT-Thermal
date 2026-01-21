
-- Keep dictionary of THERM functions.
THERM = {}

-- Convert limb to waterlimb value
THERM.LimbToWaterLimbV = function (givenlimb)
        local limb = HF.NormalizeLimbType(givenlimb)
        local WaterLimbValues = {Head = {LimbType.Head,"HeadV"}, 
                                Torso = {LimbType.Torso,"TorsoV"}, 
                                RightArm = {LimbType.RightArm,"RightArmV"}, 
                                LeftArm = {LimbType.LeftArm,"LeftArmV"}, 
                                LeftLeg = {LimbType.LeftLeg,"LeftLegV"}, 
                                RightLeg = {LimbType.RightLeg,"RightLegV"}}
        for index, WaterLimb in pairs(WaterLimbValues) do
                if WaterLimb[1] == limb then
                        return WaterLimb[2]
                end
        end 
        return "TorsoV"
end

-- Converts a limb to a the name of it's group, so LeftArm to arm and vice versa. Currently unused, however I think it's quite neat so I'll leave it.
THERM.LimbToFamily = function (givenlimb)
        if givenlimb ~= nil then
                local limb = HF.NormalizeLimbType(givenlimb)
                local Families = {Head = {LimbType.Head,"Head"}, 
                                        Torso = {LimbType.Torso,"Torso"}, 
                                        RightArm = {LimbType.RightArm,"Arm"}, 
                                        LeftArm = {LimbType.LeftArm,"Arm"}, 
                                        LeftLeg = {LimbType.LeftLeg,"Leg"}, 
                                        RightLeg = {LimbType.RightLeg,"Leg"}}
                for index, FamilyLimb in pairs(Families) do
                        if FamilyLimb[1] == limb then
                                return FamilyLimb[2]
                        end
                end   
        end
end

local LimbsToCheck = {LimbType.Head,LimbType.Torso,LimbType.RightArm,LimbType.LeftArm,LimbType.LeftLeg,LimbType.RightLeg}
-- Calculate pressure
THERM.SetCharacterTablePressure = function (character,CharacterTable)
        if character.IsProtectedFromPressure and (character.InPressure or not character.InPressure) then
                CharacterTable.PressureStrength = 1  
        elseif not character.IsProtectedFromPressure and character.InPressure then
                CharacterTable.PressureStrength = 2 
        else 
                CharacterTable.PressureStrength = 1
        end
end


-- Used for getting cloth resistance of temperature based off of limb equipment. These helperfunctions are the goat.
THERM.ClothResistance = function (limb,Character)
        -- Calulate head resistance.
        -- Note, using BoolToNum kept breaking the script, so I didn't use it, enjoy these magic numbers for the rat jacuzzi overlord.
        -- 1 = false and 2 = true
        local WearingHeadEquip = 1
        local WearingTorsoEquip = 1
        local WearingOuterEquip = 1
        local WearingDivingSuitEquip = 1
        -- HeadClothing.
        if Character.Inventory.GetItemAt(2) then
                WearingHeadEquip = 2
        else
                WearingHeadEquip = 1
        end
        -- TorsoClothing.
        if Character.Inventory.GetItemAt(3) then
                WearingTorsoEquip = 2
        else
                WearingTorsoEquip = 1
        end
        -- OuterClothing.
        if Character.Inventory.GetItemAt(4) then
                WearingOuterEquip = 1.2
                if Character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("diving") or Character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("deepdivinglarge") then
                     WearingDivingSuitEquip  = 1.4
                else
                     WearingDivingSuitEquip  = 1
                end
        else
                WearingOuterEquip = 1
                WearingDivingSuitEquip  = 1
        end
        -- Match limb 
        if limb == LimbType.Head then
                return (WearingHeadEquip * WearingDivingSuitEquip)
        elseif limb == LimbType.Torso then
                return (WearingTorsoEquip * WearingOuterEquip  * WearingDivingSuitEquip)
        else
                return (WearingOuterEquip  * WearingDivingSuitEquip)
        end
end

-- Used to get limb resistance against temperature changes.
THERM.LimbTempResistance = function (limb)
        local HeadResistance = 3
        local TorsoResistance = 4
        local LimbResistance = 2
        if limb == LimbType.Head then
                return HeadResistance
        end
        if limb == LimbType.Torso then
                return TorsoResistance
        else 
                return LimbResistance
        end
end


-- Used to determine if a hull is safe from outside water. Uses pressure of hull to determine if a leak is occuring.
-- I might change it to use 'IsSectionLeakingFromOutside' in future, however that seems very expensive to implement, at least to me. 
-- ##Not used.
THERM.IsHullLeakingOutsideWater = function (hull,character)
        local NormalPressure = 14832
        local InWaterVal = 3
        if hull ~= nil then
                return HF.Clamp(hull.Pressure/NormalPressure,1,3)
        else
                -- This indicates that the player must be in water, since they're not in a hull, so set the value to three.
                return InWaterVal
        end
end


-- Used for returning the minimum temperature a player can reach.
-- ##Not used.
THERM.CalculateMinimumTemp = function (OutsideValue,TempStrength)
        local minimumTemp = 5
        if OutsideValue > 2 then
                minimumTemp = 1
        elseif OutsideValue > 1 then
                minimumTemp = 3
        end
        if  (minimumTemp- 1) > TempStrength  then
                minimumTemp = TempStrength
        end
        return minimumTemp
end


-- Function to get general idea of if limb is in water.
THERM.CalculateIsLimbInWater = function (target, LimbTypeToCheck, offset, index)
        if target ~= nil then
                -- Calculate if limb is in water. The IsInWater action type for XML doesn't properly detect limbs, I can be knee deep in water and it won't count. At least I couldn't find it, if you do let me know.
                local limb = target.AnimController.GetLimb(LimbTypeToCheck, true, false, false)
                local LimbPosY = target.AnimController.GetLimb(LimbTypeToCheck, true, false, false).WorldPosition.Y
                local LimbHull = limb.Hull
                local WaterExposure = 0
                if LimbHull ~= nil then
                        local CurrentHullWaterVolume = LimbHull.WaterVolume
                        local CurrentHullWaterY = CurrentHullWaterVolume/LimbHull.Size.X
                        local WorldCurrentHullWaterY = (LimbHull.WorldPosition.Y - ((math.abs(LimbHull.Size.Y))/2)) + CurrentHullWaterY
                        if (LimbPosY - offset[index] < ((LimbHull.WorldPosition.Y - LimbHull.Size.Y) + CurrentHullWaterY)) and (CurrentHullWaterVolume > 0) then
                                WaterExposure = THERM.CalculateLimbWaterExposure(target, target.AnimController, limb, LimbPosY, LimbHull, WorldCurrentHullWaterY)
                                return WaterExposure
                        else
                                return 0 
                        end
                else
                        return 0
                end
        end
end


-- Used for calculating water exposure from given WorldPosition's
local LimbData = {"LeftLeg (7)", {StartPoint = LimbType.LeftThigh, EndPoint = LimbType.LeftFoot, Offset = 10},
                  "RightLeg (10)", {StartPoint = LimbType.RightThigh, EndPoint = LimbType.RightFoot, Offset = 10},
                  "LeftForearm (13)", {StartPoint = LimbType.LeftArm, EndPoint = LimbType.LeftHand, Offset = 2},
                  "RightForearm (14)", {StartPoint = LimbType.RightArm, EndPoint = LimbType.RightHand, Offset = 2}, 
                  "Torso (0)", {StartPoint = LimbType.Torso, EndPoint = LimbType.Waist, Offset = 10},
                  "Head (1)", {StartPoint = LimbType.Head, EndPoint = LimbType.Torso, Offset = 1},}
-- Calculate Water Exposure for more accurate hypothermia.
-- Abs value my goat.
THERM.CalculateLimbWaterExposure = function (target, animcontrol, limb, LimbPosY, hull, WaterY)
        for i, newlimb in pairs(LimbData) do
                if limb.Name == newlimb then
                        local LimbStartPoint = animcontrol.GetLimb(LimbData[i + 1].StartPoint,true,false,false).WorldPosition
                        local LimbEndPoint = animcontrol.GetLimb(LimbData[i + 1].EndPoint,true,false,false).WorldPosition
                        -- Two blocks incase the limbs are oriented in a manner where the endpoint is higher than the start, which will cause the water exposure to falsely go up.
                        if LimbEndPoint.Y < LimbStartPoint.Y then
                                local LimbLengthY = math.abs(LimbStartPoint.Y + LimbData[i + 1].Offset) - math.abs(LimbEndPoint.Y)
                                local WaterExposureLimb = math.abs(WaterY) - math.abs(LimbEndPoint.Y)
                                local WaterExposureLimbPercentage = HF.Clamp((WaterExposureLimb/LimbLengthY), 0, 1)
                                return WaterExposureLimbPercentage     
                        else
                                local LimbLengthY = math.abs(LimbEndPoint.Y) - math.abs(LimbStartPoint.Y)
                                local WaterExposureLimb = math.abs(WaterY) - math.abs(LimbStartPoint.Y)
                                local WaterExposureLimbPercentage = HF.Clamp((WaterExposureLimb/LimbLengthY), 0, 1)
                                return WaterExposureLimbPercentage     
                        end
                end
        end
end

-- Key set of Water Values.
THERM.CalculateTemperature = function (limbwet,target,limb)
        local CharacterTable = THERM.GetCharacter(target.ID)
        -- Slight error handling.
        if CharacterTable == nil then
                return
        end
        if limb == LimbType.Torso then
                CharacterTable.LastStoredTorsoTemp = HF.GetAfflictionStrengthLimb(target, LimbType.Torso, "temperature", 0)
        end
        THERM.SetCharacterTablePressure(target,CharacterTable)
        local LimbClothResistance = THERM.ClothResistance(limb,target)
        local LimbTempResistance = THERM.LimbTempResistance(limb)
        -- Parameters that affect temperature calculations.
        local WaterLimbKey = THERM.LimbToWaterLimbV(limb)
        local WaterMultipliers = CharacterTable.PressureStrength 
                * HF.Clamp(limbwet/1.5, 1, 2) 
                        * (HF.BoolToNum(THERM.IsLimbCyber(target,limb),1) + 2)
        local Water = CharacterTable.LimbWaterValues[WaterLimbKey] * -1
        local RoomTemp = 0
        local OnFire = CharacterTable.OnFire[limb]
        CharacterTable.OnFire[limb] = 1
        if target.CurrentHull ~= nil and THERMRoom.GetRoom(target.CurrentHull) ~= nil and THERMRoom.Rooms ~= nil and THERMRoom.Intiated then
                RoomTemp = THERMRoom.GetRoom(target.CurrentHull).Temp/THERMRoom.DefaultRoomTemp * 2 -- Scaling
        end
        if Water < 0 then
                THERM.MakeLimbWet(target,limb,Water,false)
        end
        -- Heat Calculation
        local Heat = HF.Clamp(RoomTemp - 1,0,10)
                * (HF.BoolToNum(THERM.IsLimbCyber(target,limb),1) + 1)
                / 10 -- Scaling feature
                * OnFire
                /LimbClothResistance
                /LimbTempResistance
                * NTConfig.Get("ETempScaling", 1.5)
                * NT.Deltatime
        local Cold = ((((Water) 
                * WaterMultipliers)
                /LimbClothResistance)
                /LimbTempResistance) 
                * NTConfig.Get("ETempScaling", 1.5) 
                / 1.5
                * NT.Deltatime
        return Heat + Cold
end


-- Fetches character data from THERMCharacters. This is needed since it stores water related data.
THERM.GetCharacter = function (characterID,character)
        character = character or nil
        if characterID ~= nil then
                if THERMCharacters[characterID] ~= nil then
                        return THERMCharacters[characterID]
                end
                if character ~= nil then -- failsafe incase the character is needed but not yet added.
                        THERM.IntiateCharacterTemp(character)
                        return THERMCharacters[characterID]
                end
        end
        return nil
end


-- Rat jacuzzi overlord added this function to make a limb wet if conditions are met.
THERM.MakeLimbWet = function (character, limb, watervalue, alreadychecked)
        if not alreadychecked 
                and (not character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes) 
                or (character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes) 
                and not (character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("diving") 
                or character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("deepdivinglarge"))))
                and not THERM.ImmersiveDivingGearEquipped(character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes),character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)) then
                -- Clamp wet to the limbs water value.
                if not ((watervalue * -2) < HF.GetAfflictionStrengthLimb(character, limb, "wet", 0)) then
                        HF.SetAfflictionLimb(character, "wet", limb,
                        watervalue * -2, character, HF.GetAfflictionStrengthLimb(character, limb, "wet", 0))    
                end
        elseif alreadychecked then
                if not ((watervalue * -2) < HF.GetAfflictionStrengthLimb(character, limb, "wet", 0)) then
                        HF.SetAfflictionLimb(character, "wet", limb,
                        watervalue * -2, character, HF.GetAfflictionStrengthLimb(character, limb, "wet", 0))    
                end
        end
end


-- Used to make an entire player wet. 
THERM.MakeWet = function (character, watervalue)
        if not character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes) 
                or (character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes) 
                and not (character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("diving") 
                or character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("deepdivinglarge"))) 
                and not THERM.ImmersiveDivingGearEquipped(character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes),character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)) then
                for i, limb in pairs(LimbsToCheck) do
                        THERM.MakeLimbWet(character,limb,watervalue, true)
                end
        end
end


-- Used to remove wetness from player.
THERM.RemoveWet = function (character)
        for index, limb in pairs(LimbsToCheck) do
                HF.AddAfflictionLimb(character, "wet", limb, -.05, character) 
        end
end


-- Is Cyber?
THERM.IsLimbCyber = function (character,limb)
        local newlimb = HF.NormalizeLimbType(limb)
        if      HF.GetAfflictionStrengthLimb(character, newlimb, "ntc_cyberleg", 0) > .1
                or HF.GetAfflictionStrengthLimb(character, newlimb, "ntc_cyberarm", 0) > .1
                or HF.GetAfflictionStrengthLimb(character, newlimb, "ntc_cyberlimb", 0) > .1
                then
                        return true
                end 
                return false
end

-- Yes this does nothing new, I just like the look of it.
THERM.PlaySound = function (sound,targetCharacter)
        if targetCharacter ~= nil then
                HF.GiveItem(targetCharacter, sound)
        end
end

-- Sets up the thermal stats.
THERM.IntiateCharacterTemp = function(createdCharacter)
    -- Register character in thermal table.
    local new_character =  {CharacterID = createdCharacter.ID, 
                            LimbWaterValues = {HeadV = 0, TorsoV = 0, RightArmV = 0, LeftArmV = 0, LeftLegV = 0, RightLegV = 0}, 
                            PressureStrength = 1, 
                            InCustomWater = false,
                            OnFire = {  [LimbType.Head] = 1, 
                                        [LimbType.Torso] = 1, 
                                        [LimbType.LeftArm] = 1, 
                                        [LimbType.RightArm] = 1, 
                                        [LimbType.LeftLeg] = 1, 
                                        [LimbType.RightLeg] = 1
                                     },
                            LastHullWaterVolume = 0,
                            LastStoredPlayerY = 0,
                            LastStoredTorsoTemp = 0,
			    Character = createdCharacter}
	THERMCharacters[createdCharacter.ID] = new_character
end

-- Used to make sure ThermCharacters isn't holding data of nil characters.
THERM.ValidateThermalCharacterData = function()
	for index, entry in pairs(THERMCharacters) do
		if (entry.Character.IdFreed or entry.Character.IsDead) and entry == THERMCharacters[index] then
			THERMCharacters[index] = nil
		end
	end
end

-- Used for compatibility with immersive diving gear.
THERM.ImmersiveDivingGearEquipped = function (outerclothes,innerclothes)
        -- if staircase to glory.
        if outerclothes ~= nil and innerclothes ~= nil then
                if outerclothes.HasTag("divinghelmet") or outerclothes.HasTag("bothelmet") then
                        if innerclothes.HasTag("diving") or innerclothes.HasTag("deepdivinglarge") then
                                return true
                        end
                end
        end
        return false
end