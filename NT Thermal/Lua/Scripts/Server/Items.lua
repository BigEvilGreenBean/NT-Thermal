
-- Thank you mannatu and Heelge, your work is goated. I also stole most of this from your mod. I mean lifted.

-- Function to determine which character is the affliction being applied to.
local function ConvertCharacter(usingCharacter,targetCharacter)
    if targetCharacter == nil then
        return usingCharacter
    else
        return targetCharacter
    end
end


-- Warm I.V Bag Low key stole all of this from Neuro's ice pack code.
NT.ItemMethods.warm_iv_bag = function(item, usingCharacter, targetCharacter, limb)
        if item.Condition <= 25 then
		return
	end
	local limbtype = limb.type
	local success = HF.BoolToNum(HF.GetSkillRequirementMet(usingCharacter, "medical", 40), 1)
	HF.AddAfflictionLimb(targetCharacter, "elevated_core_temperature", limbtype, 5 + success * 25, usingCharacter)
        THERM.PlaySound("thermalsfx_liquidiv",targetCharacter)
	item.Condition = 0
end

-- Warm rag
NT.ItemMethods.warm_rag = function (item, usingCharacter, targetCharacter, limb)
        if item.Condition <= 25 then
		return
	end
	local limbtype = limb.type
	local success = HF.BoolToNum(HF.GetSkillRequirementMet(usingCharacter, "medical", 20), 1)
	HF.AddAfflictionLimb(targetCharacter, "warmth", limbtype, 75 + success * 25, usingCharacter)

	item.Condition = item.Condition - 25
end

-- A.A.F.N
NT.ItemMethods.aafn = function (item, usingCharacter, targetCharacter, limb)
        local success = HF.BoolToNum(HF.GetSkillRequirementMet(usingCharacter, "medical", 60), 1)
        local limbtype = limb.type
        if HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "clampedbleeders", 0) == 100 then
                HF.AddAffliction(targetCharacter, "aafn", 10 + success * 15, usingCharacter)
                item.Condition = item.Condition - 25
                return
        end
	HF.AddAffliction(targetCharacter, "aafn", 5 + success * 5, usingCharacter)
        HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 5, usingCharacter)
        HF.AddAfflictionLimb(targetCharacter, "lacerations", limbtype, 10, usingCharacter)
	item.Condition = item.Condition - 25
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
        if hasVoltage and THERM.GetCharacter(targetCharacter.ID)  ~= nil then
        THERM.PlaySound("thermalsfx_thermometer",targetCharacter)
           local actuallimb = limb.type
                local HypothermiaLevel = NTConfig.Get("NewHypothermiaLevel", 36) - 1
                local HyperthermiaLevel = NTConfig.Get("NewHyperthermiaLevel", 39) - 1
                local character = ConvertCharacter(usingCharacter,targetCharacter)
                local LimbTemp = HF.Round(HF.GetAfflictionStrengthLimb(character, actuallimb, "temperature", NTConfig.Get("NormalBodyTemp", 38)) - 1, 1)
                local CharacterClient = HF.CharacterToClient(usingCharacter)
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
                                return AverageColor
                        elseif TempStrength >  HyperthermiaLevel * NTTHERM.ExtremeHyperthermiaScaling then
                                return BoilingColor
                        elseif TempStrength > HyperthermiaLevel * NTTHERM.MediumHypothermiaScaling then
                                return HotColor
                        elseif TempStrength > HyperthermiaLevel * NTTHERM.LowHyperthermiaScaling then 
                                return WarmColor
                        else 
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
                        if Temp < HypothermiaLevel then
                                return "Hypothermic"
                        elseif Temp > HyperthermiaLevel then
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
                                        .. "°C/"
                                        .. tostring(HF.Round(((LimbTemp * 9/5)+32),1))
                                        .. "°F"
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
                                        .. " °C/"
                                        .. tostring(HF.Round(((BodyTemp * 9/5)+32),1))
                                        .. "°F"
                                        .. "\n"
                                        .. BodyTempThermia
                                        .. "‖color:end‖"

                -- Send the temperature to chat via the rat jacuzzi overlord commands.
                Timer.Wait(function ()
                        HF.DMClient(CharacterClient, Report)  
                end, 1000)     
        end
end