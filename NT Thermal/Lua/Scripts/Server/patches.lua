-- I'm going to patch the bots to not kill themselves in water here at some point.

THERMPatch = {}
THERMPatch.RepairTools = {
                          ["extinguisher"] = -.0025,["plasmacutter"] = .0035,["weldingtool"] = .0025,["flamer"] = .0025,
                          ["ekutility_laserdrill"] = .005,["ekutility_arcwelder"] = .0015,["ekutility_ioncutter"] = .0015, -- EK Compat
                         }

-- Panicked stops you from shooting patch!
Hook.Patch("Barotrauma.Items.Components.RangedWeapon","Use", function (instance, ptable)
    if NTConfig.Get("FireCausePanic", true) and not (NTConfig.Get("BotTempIgnoreMode", true) and c.character.IsBot)
		and not (NTConfig.Get("PressureStabilizerTemperature", true) and HF.GetAfflictionStrength(c.character, "pressurestabilized", 0) > 0)then
        local Character = ptable["character"]
        if HF.GetAfflictionStrength(Character, "panicking", 0) > 0 then
            ptable.PreventExecution = true
        end
    end
end, Hook.HookMethodType.Before)

-- Hooks Lua event "Barotrauma.Character" to apply vanilla burning (formerly NT onfire) affliction and set a human on fire
Hook.HookMethod("Barotrauma.Character", "ApplyStatusEffects", function(instance, ptable)
	if ptable.actionType == ActionType.OnFire and NTConfig.Get("FireCausePanic", true) and not (NTConfig.Get("BotTempIgnoreMode", true) and c.character.IsBot)
		and not (NTConfig.Get("PressureStabilizerTemperature", true) and HF.GetAfflictionStrength(c.character, "pressurestabilized", 0) > 0) then
        local function MakeOnFire(character)
            if HF.GetAfflictionStrength(character, "ntt_temperature", 0) > THERM.FetchConfigStats().HyperthermiaLevel * NTTHERM.LowHyperthermiaScaling then
                HF.AddAffliction(character, "panicking", 2.5 * (ptable.deltaTime * 5))
            end
        end

		if instance.IsHuman then
			if not HF.HasAffliction(instance, "luabotomy") then HF.SetAffliction(instance, "luabotomy", 1) end
            MakeOnFire(instance)
		end
	end
end, Hook.HookMethodType.After)

-- Used for displaying temperature via status monitor
--Hook.Patch("Barotrauma.Items.Components.MiniMap", "SetTooltip", function(instance, ptable)
--end, Hook.HookMethodType.After)

-- For irridating heat from a welder
Hook.Patch("Barotrauma.Items.Components.RepairTool", "UseProjSpecific", function(instance, ptable)
    if NTConfig.Get("RepairToolsTemp",true) and not (NTConfig.Get("BotTempIgnoreMode", true) and c.character.IsBot)
		and not (NTConfig.Get("PressureStabilizerTemperature", true) and HF.GetAfflictionStrength(c.character, "pressurestabilized", 0) > 0) then
        local User = THERM.InstanceToUser(instance)
        local ItemIdentifier = instance.Item.Prefab.Identifier

        local Temp = function ()
            for Identifier, Temp in pairs(THERMPatch.RepairTools) do
                if Identifier == ItemIdentifier then
                    return Temp
                end
            end
            return 0
        end

        if User then
            local Temp = Temp()
            HF.AddAfflictionLimb(User, "ntt_temperature", LimbType.LeftArm, Temp)
            HF.AddAfflictionLimb(User, "ntt_temperature", LimbType.RightArm, Temp)
        end
    end
end, Hook.HookMethodType.After)