
-- Whilst these could be included in the human update, they're seperate for a more accurate time. Since at high intervals, you could basically never get wet.
local Result = {}
-- Limbs to Check with function
local LimbsToCheck = {LimbType.Head,LimbType.Torso,LimbType.RightForearm,LimbType.RightLeg}
local LimbsToCheck2 = {LimbType.Head,LimbType.Torso,LimbType.RightForearm,LimbType.LeftForearm,LimbType.RightLeg,LimbType.LeftLeg}
-- Key set of Water Values.
local WaterLimbValues = {"HeadV", "TorsoV", "RightArmV", "RightLegV"}
Hook.Add("NTTHERM.CustomInWater", "CustomInWater", function (effect, deltaTime, item, targets, worldPosition, element)
        
        for h, target in pairs(targets) do
                if target ~= nil and target.IsHuman and target.IsDead ~= true and target.InWater ~= true and target.CurrentHull ~= nil then
                        -- Fetch the player table once.
                        local CharacterTable = THERM.GetCharacter(target.ID,target)
                        if CharacterTable ~= nil then
                                -- Check to see if the last calculated water volume hull is different from the current water volume hull, if it is then calculate for the rat jacuzzi overlord. Or, if the y position is different.
                                if (CharacterTable.LastHullWaterVolume ~= target.CurrentHull.WaterVolume)
                                or (target.CurrentHull.WaterVolume > 0 and (math.floor(CharacterTable.LastStoredPlayerY) ~= math.floor(target.position.Y))) then
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
                                                elseif LimbKey == "RightLegV" then
                                                        CharacterTable.LimbWaterValues.RightLegV = Result
                                                        CharacterTable.LimbWaterValues.LeftLegV = Result
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
                                        CharacterTable.LimbWaterValues.LeftLegV = 0
                                        CharacterTable.LimbWaterValues.RightLegV = 0
                                        THERM.RemoveWet(target)
                                        
                                end
                                -- Remove wetness due to a suit being put on.
                                if target.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes) and (target.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("diving") or target.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("deepdivinglarge") or target.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("deepdiving")) then
                                THERM.RemoveWet(target)
                                end
                        end
                end
        end
end)


Hook.Add("NTTHERM.InWater", "InWater", function (effect, deltaTime, item, targets, worldPosition, element)
        
        for h, target in pairs(targets) do
                if target ~= nil and target.IsHuman and target.IsDead ~= true and target.InWater then
                        local CharacterTable = THERM.GetCharacter(target.ID,target)
                        if CharacterTable ~= nil then
                                CharacterTable.LimbWaterValues.HeadV = 1
                                CharacterTable.LimbWaterValues.TorsoV = 1
                                CharacterTable.LimbWaterValues.LeftArmV = 1
                                CharacterTable.LimbWaterValues.RightArmV = 1
                                CharacterTable.LimbWaterValues.LeftLegV = 1
                                CharacterTable.LimbWaterValues.RightLegV = 1
                                if not (target.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes) and (target.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("diving") or target.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("deepdivinglarge") or target.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes).HasTag("deepdiving"))) then
                                        THERM.MakeWet(target,1)
                                else
                                THERM.RemoveWet(target)
                                end
                        end
                end
        end
end)


Hook.Add("NTTHERM.OnFire", "OnFire", function (effect, deltaTime, item, targets, worldPosition, element)
        for h, target in pairs(targets) do
                if target ~= nil and target.IsHuman and target.IsDead ~= true then
                        local CharacterTable = THERM.GetCharacter(target.ID,target)
                        if CharacterTable ~= nil then
                                for index, value in pairs(CharacterTable.OnFire) do
                                        CharacterTable.OnFire[index] = 4
                                end
                        end
                end
        end
end)

-- Prints out Thermal data.
Hook.Add("chatMessage", "Debug", function (message, sender)
        if message == "THERMALDebug(BLAHBLAHBLAHDEBUGDEBUG123456789)" then
                print("Beginning Debug of NT THERMAL.")
                for index, character in pairs(THERMCharacters) do
                        if character ~= nil then
                                print("Entry " .. tostring(index) .. ": " .. character.Character.Name)
                                for index2, field in character do
                                        print("Field " .. tostring(index2) .. ": " .. tostring(field))
                                end
                        else
                                print("Error, nil value at index: ", index)
                        end
                end
                print("Debug Over.")
        end
        if message == "THERMALRoomTemp(BLAHBLAHBLAHDEBUGDEBUG123456789)" then
                if THERMRoom.Rooms ~= nil then
                        for index2, room in pairs(THERMRoom.Rooms) do
                                print("Current Temp of " .. tostring(room.Hull) .. ": ".. tostring(room.Temp))
                        end
                else
                        print("Nil table.")
                end
        end
end)


-- Removes human in server from THERM
Hook.Add("character.death", "Newcharacter", function (createdCharacter)
    -- Verify not nil
    local CharacterResult = THERM.GetCharacter(createdCharacter.ID)
    if createdCharacter ~= nil and CharacterResult ~= nil then
        THERM.ValidateThermalCharacterData()
    end
end)

-- Lukako my absolute value goat. Thank you so much.
Hook.Add("characterCreated", "NTTHERM.ForceUpdates", function(createdCharacter)
        -- run once on spawn then cope
    Timer.Wait(function()
        if createdCharacter.IsHuman and
                   createdCharacter.TeamID == 1 or 
                   createdCharacter.TeamID == 2 and not 
                   createdCharacter.IsDead then

        local temperaturecheck = createdCharacter.CharacterHealth.GetAffliction("temperature")
            if temperaturecheck == nil then
                HF.AddAffliction(createdCharacter, "luabotomy", 0.1)
            end
        end
    end, 5000)
end)