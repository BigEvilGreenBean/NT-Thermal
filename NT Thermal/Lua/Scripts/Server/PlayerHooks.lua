-- Writing this as I plan my next attack on XML.

local Result = {}
-- Limbs to Check with function
local LimbsToCheck = {LimbType.Head,LimbType.Torso,LimbType.RightForearm,LimbType.RightLeg}
local LimbsToCheck2 = {LimbType.Head,LimbType.Torso,LimbType.RightForearm,LimbType.LeftForearm,LimbType.RightLeg,LimbType.LeftLeg}
-- Key set of Water Values.
local WaterLimbValues = {"HeadV", "TorsoV", "RightArmV", "RightThighTHERM"}
Hook.Add("NTTHERM.CustomInWater", "CustomInWater", function (effect, deltaTime, item, targets, worldPosition, element)
        
        for h, target in pairs(targets) do
                if target ~= nil and target.IsHuman and target.IsDead ~= true and target.InWater ~= true then
                        -- Fetch the player table once.
                        local CharacterTable = THERM.GetCharacter(target.Name).character
                        -- Check to see if the last calculated water volume hull is different from the current water volume hull, if it is then calculate for the rat jacuzzi overlord. Or, if the y position is different.
                        -- These optimizations can sometimes cause the script to not detect the water. Really cringe and I gotta fix.
                        if (CharacterTable.LastHullWaterVolume ~= target.CurrentHull.WaterVolume)
                         or (CharacterTable.InCustomWater and (math.floor(CharacterTable.LastStoredPlayerY) ~= math.floor(target.position.Y))) then
                                for i, limb in ipairs(LimbsToCheck) do
                                        local LimbKey = WaterLimbValues[i]
                                        -- Parameters = 1: target character, 2: limb to check, 3: offset values corresponds to LimbsToCheck, 4: index of limb.
                                        local Result = THERM.CalculateIsLimbInWater(target, limb, {100,200,200,150}, i)
                                        -- Optimize algorithim by onlycomputing one limb of pairs and setting to both, less accurate but rat jacuzzi overlord is now happy.
                                        if Result > 0 then
                                                CharacterTable.InCustomWater = true
                                        else
                                                CharacterTable.InCustomWater = false
                                        end
                                        -- Optimize algorithim by onlycomputing one limb of pairs and setting to both, less accurate but rat jacuzzi overlord is now happy.
                                        if LimbKey == "RightArmV" then
                                                CharacterTable.LimbWaterValues.RightArmV = Result
                                                CharacterTable.LimbWaterValues.LeftArmV = Result
                                        elseif LimbKey == "RightThighTHERM" then
                                                CharacterTable.LimbWaterValues.RightThigTHERM = Result
                                                CharacterTable.LimbWaterValues.LeftThigTHERM = Result
                                                -- This will run last, so set it in here.
                                                CharacterTable.LastHullWaterVolume = target.CurrentHull.WaterVolume
                                                CharacterTable.LastStoredPlayerY = math.floor(target.position.Y)
                                        -- Set the value
                                        else
                                                CharacterTable.LimbWaterValues[LimbKey] = Result
                                        end
                                end    
                        -- Set to false
                        elseif CharacterTable.InCustomWater == false then
                                CharacterTable.LimbWaterValues.HeadV = 0
                                CharacterTable.LimbWaterValues.TorsoV = 0
                                CharacterTable.LimbWaterValues.LeftArmV = 0
                                CharacterTable.LimbWaterValues.RightArmV = 0
                                CharacterTable.LimbWaterValues.LeftThigTHERM = 0
                                CharacterTable.LimbWaterValues.RightThigTHERM = 0
                                THERM.RemoveWet(target)
                                
                        end
                        -- Remove wetness due to a suit being put on.
                        if target.Inventory.GetItemAt(4) and target.Inventory.GetItemAt(4).HasTag("diving") then
                             THERM.RemoveWet(target)
                        end
                end
        end
end)


-- Base of all hypothermia.
Hook.Add("NTTHERM.InWater", "InWater", function (effect, deltaTime, item, targets, worldPosition, element)
        
        for h, target in pairs(targets) do
                if target ~= nil and target.IsHuman and target.IsDead ~= true and target.InWater then
                        local CharacterTable = THERM.GetCharacter(target.Name).character
                        CharacterTable.LimbWaterValues.HeadV = 1
                        CharacterTable.LimbWaterValues.TorsoV = 1
                        CharacterTable.LimbWaterValues.LeftArmV = 1
                        CharacterTable.LimbWaterValues.RightArmV = 1
                        CharacterTable.LimbWaterValues.LeftThigTHERM = 1
                        CharacterTable.LimbWaterValues.RightThigTHERM = 1
                        if not (target.Inventory.GetItemAt(4) and target.Inventory.GetItemAt(4).HasTag("diving")) then
                                THERM.MakeWet(target,1)
                        else
                            THERM.RemoveWet(target)
                        end
                        
                end
        end
end)


Hook.Add("NTTHERM.OnFire", "OnFire", function (effect, deltaTime, item, targets, worldPosition, element)
        print("OnFire")
end)


Hook.Add("NTTHERM.GiveTemp", "GiveTemp", function (effect, deltaTime, item, targets, worldPosition, element)
        for h, target in pairs(targets) do
                if target ~= nil and target.IsHuman and target.IsDead ~= true then
                        THERM.CalculateTemperature(target)
                end
        end
end)
