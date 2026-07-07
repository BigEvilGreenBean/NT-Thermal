
-- Keep dictionary of THERM functions.
THERM = {}

-- Convert limb to waterlimb value
local WaterLimbValues = 
                {
                [LimbType.Head] = "HeadV",
                [LimbType.LeftArm] = "LeftArmV",
                [LimbType.LeftLeg] = "LeftLegV",
                [LimbType.RightArm] = "RightArmV",
                [LimbType.RightLeg] = "RightLegV",
                [LimbType.Torso] = "TorsoV"
                }

local WaterLimbValues2 = 
                {
                ["HeadV"] = LimbType.Head,
                ["LeftArmV"] = LimbType.LeftArm,
                ["LeftLegV"] = LimbType.LeftLeg,
                ["RightArmV"] = LimbType.RightArm,
                ["RightLegV"] = LimbType.RightLeg,
                ["TorsoV"] = LimbType.Torso
                }

---@param givenlimb LimbType
---@return string
THERM.LimbToWaterLimbV = function (givenlimb)
        local limb = HF.NormalizeLimbType(givenlimb)
        return WaterLimbValues[limb]
end

-- Convert limb to waterlimb value
---@param givenlimb string
---@return LimbType
THERM.WaterLimbVToLimb = function (givenlimb)
        return WaterLimbValues2[givenlimb]
end


local LimbsToCheck = {LimbType.Head,LimbType.Torso,LimbType.RightArm,LimbType.LeftArm,LimbType.LeftLeg,LimbType.RightLeg}
-- Calculate pressure
---@param CharacterTable table
---@param character Character
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
---@param limb LimbType
---@param Character Character
---@return number
THERM.ClothResistance = function (limb,Character)
        -- Calulate head resistance.
        -- Note, using BoolToNum kept breaking the script, so I didn't use it, enjoy these magic numbers for the rat jacuzzi overlord.
        -- 1 = false and 2 = true
        local WearingHeadEquip = 1
        local WearingTorsoEquip = 1
        local WearingOuterEquip = 1
        local WearingDivingSuitEquip = 1
        -- HeadClothing.
        if THERM.GetHeadSlot(Character) then
                WearingHeadEquip = 2
        else
                WearingHeadEquip = 1
        end
        -- TorsoClothing.
        if THERM.GetInnerSlot(Character) then
                WearingTorsoEquip = 2
        else
                WearingTorsoEquip = 1
        end
        -- OuterClothing.
        if THERM.GetSuitSlot(Character) then
                WearingOuterEquip = 1.2
                if THERM.IsDivingSuit(THERM.GetSuitSlot(Character)) then
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
---@param limb LimbType
---@return number
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

---Function to get general idea of if limb is in water.
---@param target Character
---@param LimbTypeToCheck LimbType
---@param offset number
---@param index integer
---@return number
THERM.CalculateIsLimbInWater = function (target, LimbTypeToCheck, offset, index)
        if not target then return 0 end
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
                        WaterExposure = THERM.CalculateLimbWaterExposure(target.AnimController, limb, WorldCurrentHullWaterY)
                        return WaterExposure
                else
                        return 0 
                end
        else
                return 0
        end
end

-- Used for calculating water exposure from given WorldPosition's
local LimbData = {[LimbType.LeftLeg] = {StartPoint = LimbType.LeftThigh, EndPoint = LimbType.LeftFoot, Offset = 10},
                  [LimbType.RightLeg] = {StartPoint = LimbType.RightThigh, EndPoint = LimbType.RightFoot, Offset = 10},
                  [LimbType.RightForearm] = {StartPoint = LimbType.LeftArm, EndPoint = LimbType.LeftHand, Offset = 2},
                  [LimbType.LeftForearm] = {StartPoint = LimbType.RightArm, EndPoint = LimbType.RightHand, Offset = 2}, 
                  [LimbType.Torso] = {StartPoint = LimbType.Torso, EndPoint = LimbType.Waist, Offset = 10},
                  [LimbType.Head] = {StartPoint = LimbType.Head, EndPoint = LimbType.Torso, Offset = 1},}

---Calculate Water Exposure for more accurate hypothermia.
---Abs value my goat.
---@param animcontrol AnimationController
---@param limb LimbType
---@param WaterY number
---@return number
THERM.CalculateLimbWaterExposure = function (animcontrol, limb, WaterY)
        local NewLimbData = LimbData[limb.type] or nil
        if not NewLimbData then
                return 0
        end
        local LimbStartPoint = animcontrol.GetLimb(NewLimbData.StartPoint,true,false,false).WorldPosition
        local LimbEndPoint = animcontrol.GetLimb(NewLimbData.EndPoint,true,false,false).WorldPosition
        -- Two blocks incase the limbs are oriented in a manner where the endpoint is higher than the start, which will cause the water exposure to falsely go up.
        if LimbEndPoint.Y < LimbStartPoint.Y then
                local LimbLengthY = math.abs(LimbStartPoint.Y + NewLimbData.Offset) - math.abs(LimbEndPoint.Y)
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

-- Returns just how extreme our hulls water temperature is.
---@param target Character
---@param limb LimbType
---@return number
THERM.FreezingWaterAmount = function (target, limb)
        local ActualLimb = target.AnimController.GetLimb(limb, true, false, false)
        local LimbHull = ActualLimb.hull
        local ScalingAmount = 1.25
        if LimbHull == nil then return 1 end
        local Result = HF.Clamp((LimbHull.WaterVolume / LimbHull.Volume) * ScalingAmount, 0, 1)
        return Result
end

---Made by Antinous (Thank you)
---@param item Item
---@return number
THERM.BurnReductionFactor = function(item)
        if not item or not item.Prefab then return nil end
        if not item.Prefab.ConfigElement then return nil end

        for element in item.Prefab.ConfigElement.Elements() do
                if element.Name.ToString() == "Wearable" then
                for child in element.Elements() do
                        if child.Name.ToString() == "damagemodifier" then
                        local afflictions = string.lower(child.GetAttributeString("afflictiontypes") or "")
                        if afflictions:find("burn") then
                                local multiplierString = child.GetAttributeString("damagemultiplier")
                                local multiplier = math.abs(multiplierString - 1) + 1
                                if multiplier > 1 then
                                        multiplier = HF.Clamp(multiplier * 1.2,1,100)
                                end
                                return multiplier
                        end
                        end
                end
                end
        end

        return 1
        end

---Key set of Water Values.
---@param limbwet number
---@param target Character
---@param limb LimbType
---@return number
THERM.CalculateTemperature = function (limbwet,target,limb)
        local CharacterTable = THERM.GetCharacter(target.ID)
        -- Slight error handling.
        if CharacterTable == nil then
                return 0
        end
        if limb == LimbType.Torso then
                local DivingSuit = THERM.GetSuitSlot(target)
                CharacterTable.LastStoredHeadTemp = HF.GetAfflictionStrengthLimb(target, LimbType.Torso, "ntt_temperature", 0)
                if DivingSuit ~= CharacterTable.LastStoredSuit and DivingSuit ~= nil then
                        CharacterTable.LastStoredSuit = DivingSuit
                        CharacterTable.DivingSuitBurnRes = THERM.BurnReductionFactor(DivingSuit)
                elseif  DivingSuit == nil then
                        CharacterTable.LastStoredSuit = nil
                        CharacterTable.DivingSuitBurnRes = 1
                end
                local InnerSuit = THERM.GetInnerSlot(target)
                if InnerSuit ~= CharacterTable.LastStoredInnerSuit and InnerSuit ~= nil then
                        CharacterTable.LastStoredInnerSuit = InnerSuit
                        CharacterTable.InnerClothingBurnRes = THERM.BurnReductionFactor(InnerSuit)
                elseif  InnerSuit == nil then
                        CharacterTable.LastStoredInnerSuit = nil
                        CharacterTable.InnerClothingBurnRes = 1
                end
        end
        THERM.SetCharacterTablePressure(target,CharacterTable)
        HypothermiaLevel = NTConfig.Get("NewHypothermiaLevel", 36)
        HyperthermiaLevel = NTConfig.Get("NewHyperthermiaLevel", 39)
        local LimbClothResistance = THERM.ClothResistance(limb,target)
        local LimbTempResistance = THERM.LimbTempResistance(limb)
        -- Parameters that affect temperature calculations.
        local WaterLimbKey = THERM.LimbToWaterLimbV(limb)
        local WaterMultipliers = CharacterTable.PressureStrength 
                * HF.Clamp(limbwet/1.5, 1, 2) 
                        * (HF.BoolToNum(THERM.IsLimbCyber(target,limb),1) + 2)
        local WaterResistance = 1
        if NTConfig.Get("WaterColdHull",false) then
                WaterResistance = THERM.FreezingWaterAmount(target, limb)
        end
        local Water = CharacterTable.LimbWaterValues[WaterLimbKey] * -1
        local RoomTemp = 0
        local OnFire = CharacterTable.OnFire[limb]
        local BloodLoss = function ()
                if HF.GetAfflictionStrengthLimb(target, limb, "ntt_temperature", 0) > HypothermiaLevel then
                        return HF.GetAfflictionStrength(target, "bloodloss", 0)/400
                end
                return 0 
        end
        local Sepsis = function ()
                if HF.GetAfflictionStrengthLimb(target, limb, "ntt_temperature", 0) < HyperthermiaLevel then
                        return HF.GetAfflictionStrength(target, "sepsis", 0)/90
                end
                return 0 
        end
        CharacterTable.OnFire[limb] = 1
        if target.CurrentHull ~= nil and THERMRoom.GetRoom(target.CurrentHull) ~= nil and THERMRoom.Rooms ~= nil and THERMRoom.Intiated then
                RoomTemp = THERMRoom.GetRoom(target.CurrentHull).Temp/THERMRoom.DefaultRoomTemp * 2 -- Scaling
        end
        if Water < 0 then
                THERM.MakeLimbWet(target,limb,Water,false)
        end
        -- Heat Calculation
        local Heat = HF.Clamp(RoomTemp - 1,0,10) + .2
                * (HF.BoolToNum(THERM.IsLimbCyber(target,limb),1) + 1)
                * OnFire
                /LimbClothResistance
                /LimbTempResistance
                * HF.Clamp((HF.GetAfflictionStrengthLimb(target, LimbType.Torso, "husksymbiosis", 0)/40),1,10)
                / 10 -- Scaling feature
                * NTConfig.Get("ETempScaling", 1.5)
                + Sepsis()
                * NT.Deltatime
        local Cold = (((((Water * WaterResistance) - BloodLoss()) 
                * WaterMultipliers)
                /LimbClothResistance)
                /LimbTempResistance) 
                * NTConfig.Get("ETempScaling", 1.5) 
                / 2 -- Scaling feature
                * NT.Deltatime
        return (Heat/THERM.TotalBurnResistance(CharacterTable)/2) + Cold
end


-- Fetches character data from THERMCharacters. This is needed since it stores water related data.
---@param characterID ID
---@param character Character
---@return table
THERM.GetCharacter = function (characterID,character)
        character = character or nil
        if characterID == nil then
                return nil
        end
        if THERMCharacters[characterID] ~= nil then
                return THERMCharacters[characterID]
        end
        if character ~= nil then -- failsafe incase the character is needed but not yet added.
                THERM.IntiateCharacterTemp(character)
                return THERMCharacters[characterID]
        end
end


-- Rat jacuzzi overlord added this function to make a limb wet if conditions are met.
---@param character Character
---@param watervalue number
---@param limb LimbType
---@param alreadychecked boolean
THERM.MakeLimbWet = function (character, limb, watervalue, alreadychecked)
        if not alreadychecked 
                and not THERM.IsDivingSuit(THERM.GetSuitSlot(character))
                and not THERM.ImmersiveDivingGearEquipped(THERM.GetSuitSlot(character),THERM.GetInnerSlot(character)) then
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


---Used to make an entire player wet. 
---@param character Character
---@param watervalue number
THERM.MakeWet = function (character, watervalue)
        if not THERM.IsDivingSuit(THERM.GetSuitSlot(character))
                and not THERM.ImmersiveDivingGearEquipped(THERM.GetSuitSlot(character),THERM.GetInnerSlot(character)) then
                for i, limb in pairs(LimbsToCheck) do
                        THERM.MakeLimbWet(character,limb,watervalue, true)
                end
        end
end


---Used to remove wetness from player.
---@param character Character
THERM.RemoveWet = function (character)
        for index, limb in pairs(LimbsToCheck) do
                HF.AddAfflictionLimb(character, "wet", limb, -.05, character) 
        end
end


---Is Cyber?
---@param limb LimbType
---@param character Character
---@return boolean
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

---Yes this does nothing new, I just like the look of it.
---@param sound string
---@param targetCharacter Character
THERM.PlaySound = function (sound,targetCharacter)
        if not targetCharacter then return end
        HF.GiveItem(targetCharacter, sound)
end

---Sets up the thermal stats.
---@param CreatedCharacter  Character
THERM.IntiateCharacterTemp = function(CreatedCharacter)
    -- Register character in thermal table.
    local new_character =  
                        {
                            CharacterID = CreatedCharacter.ID, -- The ID of the character.
                            LimbWaterValues = {                -- The water values of the character, (this isn't just wetness)
                                                HeadV = 0, 
                                                TorsoV = 0, 
                                                RightArmV = 0, 
                                                LeftArmV = 0, 
                                                LeftLegV = 0, 
                                                RightLegV = 0
                                              }, 
                            PressureStrength = 1,              -- The pressure of the water the character is in.
                            InCustomWater = false,             -- Is in custom water.
                            OnFire = {                         -- The multiplier per limb of fire.
                                        [LimbType.Head] = 1, 
                                        [LimbType.Torso] = 1, 
                                        [LimbType.LeftArm] = 1, 
                                        [LimbType.RightArm] = 1, 
                                        [LimbType.LeftLeg] = 1, 
                                        [LimbType.RightLeg] = 1
                                     },
                            LastHullWaterVolume = 0,           -- The last stored hull volume.
                            LastStoredPlayerY = 0,             -- The last stored Player Y.
                            LastStoredHeadTemp = 0,            -- Last stored Head Temp, used for thermal shock.
			    Character = CreatedCharacter,      -- Reference to self.
                            LastStoredSuit = nil,              -- The last stored suit.
                            LastStoredInnerSuit = nil,         -- The last stored inner suit.
                            DivingSuitBurnRes =                -- Our calculated burn resistance.
                            1,
                            InnerClothingBurnRes =             -- Our calculated burn resistance.
                            1,
                            TemperatureUpdate = false,         -- Do we have a temperature update?
                            CompactHeater = {                  -- The compact heater information.
                                                Equipped = false, 
                                                Item = nil
                                            }
                        }
	THERMCharacters[CreatedCharacter.ID] = new_character
end

-- Used to make sure ThermCharacters isn't holding data of nil characters.
THERM.ValidateThermalCharacterData = function()
	for index, entry in pairs(THERMCharacters) do
		if (entry.Character.IdFreed or entry.Character.IsDead) and entry == THERMCharacters[index] then
			THERMCharacters[index] = nil
		end
	end
end

---Used to quickly add up all burn resistance
---@param CharacterTable table
---@return number
THERM.TotalBurnResistance = function(CharacterTable)
        if not CharacterTable then return 1 end
        return CharacterTable.InnerClothingBurnRes + CharacterTable.DivingSuitBurnRes
end

---Used for compatibility with immersive diving gear.
---@param outerclothes Item
---@param innerclothes Item
---@return boolean
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

---I Stole this code from the robotrauma script.
---@param character Character
---@return boolean
THERM.IsRobot = function(character)
    -- return true
    return not character.IsFemale and not character.IsMale
end

---We use this to determine if the suit is a diving suit.
---@param DivingSuit Item
---@return boolean
THERM.IsDivingSuit = function(DivingSuit)
        if not DivingSuit then return false end
        return DivingSuit.HasTag("diving") or DivingSuit.HasTag("deepdivinglarge") or DivingSuit.HasTag("deepdiving")
end

---Returns the bag slot item.
---@param Character Character
---@return Item
THERM.GetBagSlot = function (Character)
        if not Character then return end
        return Character.Inventory.GetItemInLimbSlot(InvSlotType.Bag)
end

---Returns the head slot item.
---@param Character Character
---@return Item
THERM.GetHeadSlot = function (Character)
        if not Character then return end
        return Character.Inventory.GetItemInLimbSlot(InvSlotType.Head)
end

---Returns the diving suit slot item.
---@param Character Character
---@return Item
THERM.GetSuitSlot = function (Character)
        if not Character then return end
        return Character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
end

---Returns the inner suit slot item.
---@param Character Character
---@return Item
THERM.GetInnerSlot = function (Character)
        if not Character then return end
        return Character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
end

---Returns the inner suit slot item.
---@param Character Character
THERM.GetHeadSetSlot = function (Character)
        if not Character then return end
        return Character.Inventory.GetItemInLimbSlot(InvSlotType.Headset)
end

---We use this to optimize the shit out of temperature calculations.
---@param CharacterID ID
THERM.ApplyTemperatureUpdate = function (CharacterID)
        if not CharacterID then return end
        local CharacterTable = THERM.GetCharacter(CharacterID)
        if not CharacterTable then return end
        CharacterTable.TemperatureUpdate = true
end

---Returns the clients language.
---@param Client ClientCharacter
---@return string
THERM.ClientLanguage = function (Client)
        if not Client then return end
        return tostring(GameSettings.CurrentConfig.Language)
end

---Returns true if the patient could be consider in danger.
---@param Character Character
---@return boolean
THERM.TemperatureDanger = function (Character)
        if not Character then return false end
        if HF.GetAfflictionStrength(target, "sym_numb", 0) > 0 or HF.GetAfflictionStrength(target, "sym_shivers", 0) > 0 then
                return true
        end
        return false
end

---Returns true if the patient is has husk symbiosis.
---@param Character Character
---@return boolean
THERM.HasHuskSymbiosis = function (Character)
        if not Character then return false end
        if HF.GetAfflictionStrength(Character, "husksymbiosis", 0) > 0 or HF.GetAfflictionStrength(Character, "symbiotichusk", 0) > 0 or HF.GetAfflictionStrength(Character, "boosterhusk", 0) > 0 or (NTConfig.Get("HuskGenesHypothermia", true) and HF.GetAfflictionStrength(Character, "husktransformimmunity", 0) > 0) then
                return true
        end
        return false
end

---Sets out limb water values.
---@param CharacterTable table
---@param NewValue number
THERM.SetLimbWaterValues = function (CharacterTable, NewValue)
        if not CharacterTable then return end
        for key, water_value in pairs(CharacterTable.LimbWaterValues) do
                water_value = NewValue
        end
end

---Returns the size of an ienumerable. (Can also be used for a table, but that's kinda silly)
---@param IEnumerable IEnumerable
THERM.IEnumerableSize = function (IEnumerable)
    local size = 0
    for value in IEnumerable do
        size = size + 1
    end
    return size
end

---Used to set the wet values of all limbs.
---@param CharacterTable table
---@param NewWet number
THERM.GroupSetWet = function (CharacterTable, NewWet)
        if not CharacterTable then return end
        CharacterTable.LimbWaterValues.HeadV = NewWet
        CharacterTable.LimbWaterValues.TorsoV = NewWet
        CharacterTable.LimbWaterValues.LeftArmV = NewWet
        CharacterTable.LimbWaterValues.RightArmV = NewWet
        CharacterTable.LimbWaterValues.LeftLegV = NewWet
        CharacterTable.LimbWaterValues.RightLegV = NewWet
end

---Converts a patches Instance into a user.
---@param Instance HookInstance
---@return User
THERM.InstanceToUser = function (Instance)
        if not Instance then 
                return nil 
        end
        local ItemInv = Instance.Item.ParentInventory
        if ItemInv then
                local User = ItemInv.Owner
                if User then
                        return User
                end
        end
        return nil
end

---Our safe version of give temperature. (Clamped to 1-101)
---@param Character Character
---@param Amount number
---@param Limb LimbType
THERM.GiveTemperatureClamp = function (Character,Amount,Limb)
        local MinTemp = 1
        local MaxTemp = 101
        local CurrentTemp = HF.GetAfflictionStrengthLimb(Character, Limb, "ntt_temperature", NTConfig.Get("NormalBodyTemp", 38))
        local NewTemp = HF.Clamp(CurrentTemp + Amount, MinTemp, MaxTemp)
        local TempDiff = NewTemp - CurrentTemp
        HF.AddAfflictionLimb(Character, "ntt_temperature", Limb, TempDiff, Character) 
end

---Raises the entire temp of body.
---@param Character Character
---@param Amount number
THERM.RaiseTemperature = function (Character, Amount)
        for limb in LimbsToCheck do
                HF.AddAfflictionLimb(Character, "ntt_temperature", limb, Amount, Character) 
        end
end

-- Function used to return config stats.
---@return table
THERM.FetchConfigStats = function()
	local ConfigStats = 
		{
		NormalBodyTemp = NTConfig.Get("NewNormalBodyTemp", 38),
		HypothermiaLevel = NTConfig.Get("NewHypothermiaLevel", 36),
		HyperthermiaLevel = NTConfig.Get("NewHyperthermiaLevel", 39),
		WarmingAbility = NTConfig.Get("NewWarmingAbility", .2),
		DryingSpeed = NTConfig.Get("NewDryingSpeed", -.1),
		PerformanceMode = NTConfig.Get("PerformanceMode",true),
		ShockMargin = NTConfig.Get("ShockMargin",100)/357.142
		}
	return ConfigStats
end

-- Function used to return random stats that I can't think of a better name for.
---@return table
THERM.FetchOtherStats = function()
	local Stats =
	{
	AffectBodyCold = 1.1,
	AffectBodyWarm = 1.1,	
	LimbsToCheck = {LimbType.Head,LimbType.RightArm,LimbType.LeftArm,LimbType.LeftLeg,LimbType.RightLeg},
	BloodAfflictions = {"elevated_core_temperature","diuretics","thrombolytics","aafn","cryo_stasis_starter"},
	MaxWarmingTemp = THERM.FetchConfigStats().NormalBodyTemp * 1.02,
	MaxCoolingTemp = THERM.FetchConfigStats().NormalBodyTemp/1.02
	}
	return Stats
end

---Reduces all burn types.
---@param targetCharacter Character
---@param limb LimbType
---@param usingCharacter Character
THERM.ReduceBurns = function (targetCharacter, limb, usingCharacter)
        for Identifier in {"burn_deg3","burn_deg2","burn_deg1","burn"} do
                HF.AddAfflictionLimb(targetCharacter, Identifier, limb.type, -100, usingCharacter)
        end
end

---Get average temperature.
---@param Character Character
---@return number
THERM.AverageBodyTemp = function (Character)
        AverageTemp = 0
        for index, limb in pairs(LimbsToCheck) do
                AverageTemp = AverageTemp + HF.Round(HF.GetAfflictionStrengthLimb(Character, limb, "ntt_temperature", NTConfig.Get("NormalBodyTemp", 38)) - 1, 1)
        end
        return HF.Round(AverageTemp/6,1)
end

---Checks if an item is a battery.
---@param Item Item
---@return boolean
THERM.IsBatteryCell = function (Item)
        if Item.HasTag("mobilebattery") or Item.HasTag("batterycell") or Item.HasTag("battery")then
                return true
        end
        return false
end

THERM.StringOnlyHas = function (String,Wanted)
        if String:match(tostring(Wanted)) then
                if not String:match(",") then
                        return true
                end           
        end
        return false
end