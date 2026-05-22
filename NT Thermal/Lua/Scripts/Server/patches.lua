-- I'm going to patch the bots to not kill themselves in water here at some point.

-- Panicked stops you from shooting patch!
Hook.Patch("Barotrauma.Items.Components.RangedWeapon","Use", function (instance, ptable)
    if NTConfig.Get("FireCausePanic", true) then
        local Character = ptable["character"]
        if HF.GetAfflictionStrength(Character, "panicking", 0) > 0 then
            ptable.PreventExecution = true
        end
    end
end, Hook.HookMethodType.Before)

-- Hooks Lua event "Barotrauma.Character" to apply vanilla burning (formerly NT onfire) affliction and set a human on fire
Hook.HookMethod("Barotrauma.Character", "ApplyStatusEffects", function(instance, ptable)
	if ptable.actionType == ActionType.OnFire then

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