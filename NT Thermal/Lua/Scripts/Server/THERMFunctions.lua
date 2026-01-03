
-- Keep dictionary of THERM functions.
THERM = {}
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
                WearingOuterEquip = 2
                if Character.Inventory.GetItemAt(4).HasTag("diving") then
                     WearingDivingSuitEquip  = 2
                else
                     WearingDivingSuitEquip  = 1
                end
        else
                WearingOuterEquip = 1
                WearingDivingSuitEquip  = 1
        end
        -- Match limb 
        if limb == LimbType.Head then
                return (WearingHeadEquip)
        elseif limb == LimbType.Torso then
                return (WearingTorsoEquip * WearingOuterEquip)
        else
                return (WearingOuterEquip)
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
local WaterLimbValues = {"HeadV", "TorsoV", "RightArmV", "LeftArmV", "LeftThigTHERM", "RightThigTHERM"}
THERM.CalculateTemperature = function (target)
        local CharacterTable = THERM.GetCharacter(target.Name).character
        -- Unimplemented minimum temperature detection, I'm struggling getting this to be efficent and performance effective. I'll add this in a future update.
        --OutsideValue = THERM.IsHullLeakingOutsideWater(target.AnimController.CurrentHull,target)
        THERM.SetCharacterTablePressure(target,CharacterTable)
        for i, limb in ipairs(LimbsToCheck) do
                local LimbClothResistance = THERM.ClothResistance(limb,target)
                local LimbTempResistance = THERM.LimbTempResistance(limb)
                -- Parameters that affect temperature calculations.
                local LimbKey = WaterLimbValues[i]
                local TempMultipliers = CharacterTable.PressureStrength * HF.Clamp(HF.GetAfflictionStrengthLimb(target, limb, "wet", 1)/1.5, 1, 2)
                local Water = CharacterTable.LimbWaterValues[LimbKey] * -1
                local TempFormula = (((Water * TempMultipliers)/LimbClothResistance)/LimbTempResistance)
                local TempStrength = HF.GetAfflictionStrengthLimb(target, limb, "temperature", 37)
                -- Set the new temperature.
                HF.SetAfflictionLimb(target, "temperature", limb,
                HF.Clamp(TempStrength + TempFormula, 1, 101), target, TempStrength)
                -- Make limb wet.
                if Water < 0 then
                        THERM.MakeLimbWet(target,limb,Water,false)
                end
        end
end


-- Fetches character data from THERMCharacters. This is needed since it stores water related data.
THERM.GetCharacter = function (charactername)
        for index, table in pairs(THERMCharacters) do
                if table ~= nil and table.CharacterName == charactername then
                        return {character = table,tableIndex = index}
                end
        end
        return nil
end


-- Rat jacuzzi overlord added this function to make a limb wet if conditions are met.
THERM.MakeLimbWet = function (character, limb, watervalue, alreadychecked)
        if not alreadychecked and (not character.Inventory.GetItemAt(4) or (character.Inventory.GetItemAt(4) and not character.Inventory.GetItemAt(4).HasTag("diving"))) then
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
        if not character.Inventory.GetItemAt(4) or (character.Inventory.GetItemAt(4) and not character.Inventory.GetItemAt(4).HasTag("diving")) then
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


-- Used to set an affliction and clamp it.
THERM.ApplyAfflictionClamp = function (character,identifier,limb,value,default)
        HF.SetAfflictionLimb(character, identifier, limb,
        value, character, HF.GetAfflictionStrengthLimb(character, limb, identifier, default))
end