
-- Thank you mannatu and Heelge, your work is goated. I also stole most of this from your mod. I mean lifted.

-- Function to determine which character is the affliction being applied to.
local function ConvertCharacter(usingCharacter,targetCharacter)
    if targetCharacter == nil then
        return usingCharacter
    else
        return targetCharacter
    end
end


-- These aren't used but I'm too lazy to get rid of them.
-- Warm I.V Bag
NT.ItemMethods.warm_iv_bag = function(item, usingCharacter, targetCharacter, limb)
        
end

-- Warm rag
NT.ItemMethods.warm_rag = function (item, usingCharacter, targetCharacter, limb)

end

-- Heat pads
NT.ItemMethods.heatpads = function (item, usingCharacter, targetCharacter, limb)
        
end

-- towel
NT.ItemMethods.towel = function (item, usingCharacter, targetCharacter, limb)
        
end


-- Limbs to check key.
local LimbsToCheck = {}
LimbsToCheck[LimbType.Torso]      = "Torso"
LimbsToCheck[LimbType.Head]       = "Head"
LimbsToCheck[LimbType.LeftArm]    = "Left Arm"
LimbsToCheck[LimbType.RightArm]   = "Right Arm"
LimbsToCheck[LimbType.LeftThigh]  = "Left Leg"
LimbsToCheck[LimbType.RightThigh] = "Right Leg"
local LimbsToCheck2 = {LimbType.Head,LimbType.Torso,LimbType.RightArm,LimbType.LeftArm,LimbType.RightThigh,LimbType.LeftThigh}

-- Thermometer
NT.ItemMethods.handheld_thermometer = function(item, usingCharacter, targetCharacter, limb)

        -- Get Contained item.
        local containedItem = item.OwnInventory.GetItemAt(0)
        if containedItem == nil then
                return
        end
        local hasVoltage = containedItem.Condition > 0
        -- Make sure the thermometer has a battery.
        if hasVoltage then
           local actuallimb = limb.type
                local HypothermiaLevel = NTConfig.Get("NewHypothermiaLevel", 36)
                local HyperthermiaLevel = NTConfig.Get("NewHyperthermiaLevel", 39)
                local character = ConvertCharacter(usingCharacter,targetCharacter)
                local LimbTemp = HF.Round(HF.GetAfflictionStrengthLimb(character, actuallimb, "temperature", NTConfig.Get("NormalBodyTemp", 38)) - 1, 1)
                local CharacterClient = HF.CharacterToClient(character)
                local BaseColor = "100,100,200"
                local NameColor = "125,125,225"
                -- Temp Colors
                local BoilingColor     = "255,40,0"
                local HotColor         = "240,110,40"
                local WarmColor        = "240,200,150"
                local AverageColor     = "100,200,100"
                local ColdColor        = "170,230,200"
                local ChillyColor      = "40,140,230"
                local FreezingColor    = "0,60,255"
                local CurrentTempColor = AverageColor

                -- Determine Temp Color
                local function TempColor(TempStrength)
                        if TempStrength < 1 then
                                return FreezingColor
                        elseif TempStrength < HypothermiaLevel/NTTHERM.MediumHypothermiaScaling then
                                return ChillyColor
                        elseif TempStrength < HypothermiaLevel/NTTHERM.LowHypothermiaScaling then
                                return ColdColor
                        elseif TempStrength > HypothermiaLevel and TempStrength < HyperthermiaLevel then
                                print("Average ", TempStrength)
                                return AverageColor
                        elseif TempStrength >  HyperthermiaLevel * NTTHERM.ExtremeHyperthermiaScaling then
                                return BoilingColor
                        elseif TempStrength > HyperthermiaLevel * NTTHERM.MediumHypothermiaScaling then
                                return HotColor
                        elseif TempStrength > HyperthermiaLevel * NTTHERM.LowHyperthermiaScaling then 
                                return WarmColor
                        else 
                                print("Else", TempStrength)
                                return AverageColor
                        end
                end

                -- Get average temperature.
                local function AverageBodyTemp()
                        AverageTemp = 0
                        for index, limb in pairs(LimbsToCheck2) do
                                AverageTemp = AverageTemp + HF.Round(HF.GetAfflictionStrengthLimb(character, limb, "temperature", NTConfig.Get("NormalBodyTemp", 38)) - 1, 1)
                        end
                        return HF.Round(AverageTemp/6,1)
                end

                -- Determine if a patient has hypothermia or hyperthermia.
                local function ThermiaValue(Temp)
                        if Temp < HypothermiaLevel - 1 then
                                return "Hypothermic"
                        elseif Temp > HyperthermiaLevel - 1 then
                                return "Hyperthermic"
                        else
                                return "Normal temperature range"
                        end
                end

                local BodyTemp = AverageBodyTemp()
                local BodyTempColor = TempColor(BodyTemp)
                local BodyTempThermia = ThermiaValue(BodyTemp)
                CurrentTempColor = TempColor(LimbTemp)
                local CurrentTempThermia = ThermiaValue(LimbTemp)
                local Report = 
                                        -- Intial Readout -------------------
                                        "‖color:" 
                                        .. BaseColor 
                                        .. "‖" 
                                        .. "Temperature readout of "
                                        .. "‖color:end‖"
                                        .. "‖color:" 
                                        .. NameColor 
                                        .. "‖" 
                                        .. character.Name
                                        .. "‖color:end‖"
                                        .. ":\n"
                                        .. "\n"

                                        -- Limb Checked --------------------
                                        .. "‖color:" 
                                        .. NameColor 
                                        .. "‖" 
                                        .. LimbsToCheck[actuallimb]
                                        .. "‖color:end‖"
                                        .. ":\n"
                                        .. "‖color:" 
                                        .. CurrentTempColor
                                        .. "‖" 
                                        .. tostring(LimbTemp)
                                        .. " Celsius"
                                        .. "\n"
                                        .. CurrentTempThermia
                                        .."‖color:end‖"
                                        .. "\n"
                                        .. "\n"

                                        -- Body ----------------------------
                                        .. "‖color:" 
                                        .. NameColor
                                        .. "‖" 
                                        .. "Body" 
                                        .. "‖color:end‖"
                                        .. ":\n"
                                        .. "‖color:" 
                                        .. BodyTempColor
                                        .. "‖" 
                                        .. tostring(BodyTemp)
                                        .. " Celsius"
                                        .. "\n"
                                        .. BodyTempThermia
                                        .. "‖color:end‖"

                -- Send the temperature to chat via the rat jacuzzi overlord commands.
                Timer.Wait(function ()
                        HF.DMClient(CharacterClient, Report)  
                end, 500)     
        end
end