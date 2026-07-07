
-- Elements ----------------------------------------------------------------------------------------------------------------------

-- Whilst these could be included in the human update, they're seperate for a more accurate time. Since at high intervals, you could basically never get wet.
-- Limbs to Check with function
local LimbsToCheck = {LimbType.Head,LimbType.Torso,LimbType.RightForearm,LimbType.RightLeg}
-- Key set of Water Values.

local WaterLimbValues = {"HeadV", "TorsoV", "RightArmV", "RightLegV"}
Hook.Add("NTTHERM.CustomInWater", "CustomInWater", function (effect, deltaTime, item, targets, worldPosition, element)
        local target = item -- Yeah this is weird.
        if target ~= nil and target.IsHuman and target.IsDead ~= true and target.InWater ~= true and target.CurrentHull ~= nil then
                local CharacterTable = THERM.GetCharacter(target.ID,target)
                if not NTConfig.Get("SimpleWaterCalculation", true) then
                        -- Fetch the player table once.
                        if CharacterTable ~= nil  and not (NTConfig.Get("BotTempIgnoreMode", true) and target.IsBot) then
                                -- Check to see if the last calculated water volume hull is different from the current water volume hull, if it is then calculate for the rat jacuzzi overlord. Or, if the y position is different.
                                if (CharacterTable.LastHullWaterVolume ~= HF.Round(target.CurrentHull.WaterVolume,-2))
                                or (target.CurrentHull.WaterVolume > 0 and (math.floor(CharacterTable.LastStoredPlayerY) ~= math.floor(target.position.Y)))
                                or CharacterTable.InCustomWater then

                                        for i, limb in ipairs(LimbsToCheck) do
                                                local LimbKey = WaterLimbValues[i]
                                                -- Parameters = 1: target character, 2: limb to check, 3: offset values corresponds to LimbsToCheck, 4: index of limb.
                                                local Result = THERM.CalculateIsLimbInWater(target, limb, {100,200,200,150}, i) or 0
                                                local WaterValues = CharacterTable.LimbWaterValues
                                                -- Optimize algorithim by onlycomputing one limb of pairs and setting to both, less accurate but rat jacuzzi overlord is now happy.
                                                if Result > 0 then
                                                        CharacterTable.InCustomWater = true
                                                else
                                                        CharacterTable.InCustomWater = false
                                                end
                                                -- Optimize algorithim by onlycomputing one limb of pairs and setting to both, less accurate but rat jacuzzi overlord is now happy.
                                                if LimbKey == "RightArmV" then
                                                        WaterValues.RightArmV = Result
                                                        WaterValues.LeftArmV = Result
                                                elseif LimbKey == "RightLegV" then
                                                        WaterValues.RightLegV = Result
                                                        WaterValues.LeftLegV = Result
                                                        -- This will run last, so set it in here.
                                                        CharacterTable.LastHullWaterVolume = HF.Round(target.CurrentHull.WaterVolume,-2)
                                                        CharacterTable.LastStoredPlayerY = math.floor(target.position.Y)
                                                -- Set the value
                                                else
                                                        WaterValues[LimbKey] = Result
                                                end
                                        end    
                                -- Set to false
                                elseif CharacterTable.InCustomWater == false then
                                        THERM.GroupSetWet(CharacterTable,0)
                                        THERM.RemoveWet(target)
                                end

                                -- Remove wetness due to a suit being put on.
                                local DivingSuit = THERM.GetSuitSlot(target)
                                if DivingSuit and THERM.IsDivingSuit(DivingSuit) then
                                        THERM.RemoveWet(target)
                                end
                        end
                elseif NTConfig.Get("SimpleWaterCalculation", true) and CharacterTable ~= nil then
                        THERM.GroupSetWet(CharacterTable,0)
                        THERM.RemoveWet(target)
                end
        end
end)

-- Used to decrease temp cause in water.
Hook.Add("NTTHERM.InWater", "InWater", function (effect, deltaTime, item, targets, worldPosition, element)
        local target = item -- Yeah this is also weird.
        if target ~= nil and target.IsHuman and target.IsDead ~= true and target.InWater and not (NTConfig.Get("BotTempIgnoreMode", true) and target.IsBot) then
                local CharacterTable = THERM.GetCharacter(target.ID,target)
                if CharacterTable ~= nil then
                        THERM.GroupSetWet(CharacterTable,1)
                        local DivingSuit = THERM.GetSuitSlot(target)
                        if not (DivingSuit and THERM.IsDivingSuit(DivingSuit)) then
                                THERM.MakeWet(target,1)
                        else 
                        THERM.RemoveWet(target)
                        end
                end
        end
end)

-- Used to check increase temp of a on fire character.
Hook.Add("NTTHERM.OnFire", "OnFire", function (effect, deltaTime, item, targets, worldPosition, element)
        local target = item -- Yeah this is also also weird.
        if target ~= nil and target.IsHuman and target.IsDead ~= true and not (NTConfig.Get("BotTempIgnoreMode", true) and target.IsBot) then
                local CharacterTable = THERM.GetCharacter(target.ID,target)
                if CharacterTable ~= nil then
                        THERM.ApplyTemperatureUpdate(target.ID)
                        for index, value in pairs(CharacterTable.OnFire) do
                                CharacterTable.OnFire[index] = 100 -- Multiplier for being on fire.
                        end
                end
        end
end)

-- Used to increase or decrease temp from XML.
Hook.Add("NTTHERM.AddTemp", "AddTemp", function (effect, deltaTime, item, targets, worldPosition, element)
        for key, target in pairs(targets) do
                local TempAmount = tonumber(element.GetAttributeString("temp", "default value"))
                if target ~= nil and target.IsHuman and target.IsDead ~= true and not (NTConfig.Get("BotTempIgnoreMode", true) and target.IsBot) then
                        if TempAmount < 0 then HF.AddAffliction(target, "ntt_temperature", TempAmount) return end
                        local CharacterTable = THERM.GetCharacter(target.ID,target)
                        if CharacterTable ~= nil then
                                THERM.ApplyTemperatureUpdate(target.ID)
                                HF.AddAffliction(target, "ntt_temperature", TempAmount/THERM.TotalBurnResistance(CharacterTable))
                        end
                end
        end
end)

-- Character ----------------------------------------------------------------------------------------------------------------------

-- Lukako my absolute value goat. Thank you so much.
Hook.Add("characterCreated", "NTTHERM.ForceUpdates", function(createdCharacter)
        -- run once on spawn then cope
    Timer.Wait(function()
        if createdCharacter.IsHuman and
                   createdCharacter.TeamID == 1 or 
                   createdCharacter.TeamID == 2 and not 
                   createdCharacter.IsDead then

        local temperaturecheck = createdCharacter.CharacterHealth.GetAffliction("ntt_temperature")
            if temperaturecheck == nil then
                HF.AddAffliction(createdCharacter, "luabotomy", 0.1)
            end
        end
    end, 5000)
end)

-- Removes human in server from THERM
Hook.Add("character.death", "Newcharacter", function (createdCharacter)
    -- Verify not nil
    local CharacterResult = THERM.GetCharacter(createdCharacter.ID)
    if createdCharacter ~= nil and CharacterResult ~= nil then
        THERM.ValidateThermalCharacterData()
    end
end)

-- Items ----------------------------------------------------------------------------------------------------------------------

-- StasisStarter
Hook.Add("NTTHERM.StasisStarter", "StasisStarter", function (effect, deltaTime, item, targets, worldPosition, element)

        for key, target in pairs(targets) do
                if target ~= nil and target.IsHuman and target.IsDead ~= true and not (NTConfig.Get("BotTempIgnoreMode", true) and target.IsBot) then
                        local CharacterTable = THERM.GetCharacter(target.ID,target)
                        local success = HF.GetSkillRequirementMet(target, "medical", 40)
                        if CharacterTable ~= nil then
                                if success then
                                        if HF.GetAfflictionStrength(target, "ntt_temperature", 0) <= NTConfig.Get("NewHyperthermiaLevel", 39) then
                                                HF.AddAffliction(target, "cryo_stasis_starter", 25, target)
                                        end
                                else
                                        if HF.GetAfflictionStrength(target, "ntt_temperature", 0) <= NTConfig.Get("NewHyperthermiaLevel", 39) then
                                                HF.AddAffliction(target, "cryo_stasis_starter", 5, target)
                                        end
                                end
                        end
                end
        end
        
end)

-- We set the thermal character data for CSH heating here. 
Hook.Add("NTTHERM.CSHHeat", "CSHHeat", function (effect, deltaTime, item, targets, worldPosition, element) 

        for key, target in pairs(targets) do
                if target ~= nil and target.IsHuman and target.IsDead ~= true and not (NTConfig.Get("BotTempIgnoreMode", true) and target.IsBot) then
                        local CharacterTable = THERM.GetCharacter(target.ID,target)
                        if CharacterTable ~= nil then
                                CharacterTable.CompactHeater.Equipped, 
                                CharacterTable.CompactHeater.ParentInventory, 
                                CharacterTable.CompactHeater.Item = true, item.ParentInventory, item
                        end
                end
        end
        
end)

-- Used to decrease temp from Cryo Tank.
Hook.Add("NTTHERM.CryoDecrease", "CryoDecrease", function (effect, deltaTime, item, targets, worldPosition, element)
        local ItemParent1 = item.ParentInventory.Owner
        if not ItemParent1 then return end
        if ItemParent1.GetComponentString("Wearable") == nil then return end -- Is this item not wearable?
        local ItemParent2Inventory = ItemParent1.ParentInventory
        if not ItemParent2Inventory then return end
        local Player = ItemParent2Inventory.Owner
        if Player == nil then return end
        if not ((NTConfig.Get("BotTempIgnoreMode", true) and Player.IsBot)
				or (NTConfig.Get("PressureStabilizerTemperature", true) and HF.GetAfflictionStrength(Player, "pressurestabilized", 0) > 0)) then
                THERM.GiveTemperatureClamp(Player,-1,LimbType.Head)
        end
end)

-- Removes suit heating after taking off a suit.
Hook.Add("item.drop", "Drop Item", function (Item, Character)
    if not Item then return end -- Failsafe to make sure this isn't nil.
    if THERM.IsDivingSuit(Item) then
        if not Character then return end
        HF.AddAffliction(Character, "heated_diving_suit", -100, Character)
    end
end)

-- Removes suit heating after taking off a suit.
Hook.Add("item.equip", "Equip Item", function (Item, Character)
    if not Item then return end -- Failsafe to make sure this isn't nil.
    if THERM.IsDivingSuit(Item) then
        if not Character then return end
        --THERMSuits.FindHeater(Item)
    end
end)

-- Round ----------------------------------------------------------------------------------------------------------------------

-- Used to verify player data.
Hook.Add("roundStart", "The round started", function ()
        THERM.ValidateThermalCharacterData()
end)