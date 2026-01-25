-- Most of this code has been lifted from NT Eyes, you should go check it out. Thank you POSTACI.
-- Set up dictonary
NTTHERM = {}
NTTHERM.Name = "Thermal"
NTTHERM.Version = "1.2.3h30"
NTTHERM.VersionNum = 000000001
NTTHERM.MinNTVersion = "A1.12.1"
NTTHERM.MinNTVersionNum = 01120100
NTTHERM.Path = table.pack(...)[1]
-- I don't think this is required.
NTTHERM.UpdateAfflictions = {}
NTTHERM.UpdateLimbAfflictions = {}
NTTHERM.UpdateBloodAfflictions = {}
NTTHERM.UsingRoboTrauma = false
NTTHERM.UsingEnhancedReactors = false

Timer.Wait(function ()
    if NTC ~= nil then
        NTC.RegisterExpansion(NTTHERM)
		NTC.AddPreHumanUpdateHook(function (character) -- Used to freeze patients in stasis. Since limbs dont update when stasis is on.
			if HF.GetAfflictionStrength(character, "stasis", 0) > 0 and HF.GetAfflictionStrength(character, "givetemp", 0) > 0 then
				for index, limb in pairs({LimbType.Head,LimbType.Torso,LimbType.RightArm,LimbType.LeftArm,LimbType.LeftLeg,LimbType.RightLeg}) do
					local LimbTemp = HF.GetAfflictionStrengthLimb(character, limb, "temperature", 0)
					HF.AddAfflictionLimb(character, "temperature", limb,((-.05 * ((LimbTemp/2)/(NTConfig.Get("NewHypothermiaLevel", 36)))) * NT.Deltatime), character)
				end
			end
		end)
		NTTHERM.UsingRoboTrauma = NTRT -- Used to determine if Robotrauma remake is on and balling.
		NTTHERM.UsingEnhancedReactors = EnhancedReactors -- Used to determine if enhanced reactors is on.
		if NTTHERM.UsingRoboTrauma ~= nil then
			THERMCompat.SetUpRoboCompat()
		end
		if NTTHERM.UsingEnhancedReactors ~= nil then
			Timer.Wait(function()
    			THERMCompat.SetUpEnhancedReactors()
			end, 1)
		end
    end
end, 1)

-- Ensure that NT is installed.
Timer.Wait(function()
	if (SERVER or (CLIENT and not Game.IsMultiplayer)) and (NTC == nil) then --check if NT is installed
		print("Error loading NT Thermal: It Seems Neurotrauma isn't loaded!")
		return
	end

    --Server Side scripts
	if SERVER or (CLIENT and not Game.IsMultiplayer) then
    	dofile(NTTHERM.Path .. "/Lua/Scripts/Server/humanUpdate.lua") --HumanUpdates.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/THERMFunctions.lua") --Setup THERM functions.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/PlayerHooks.lua") --Main Hooks used for a large portion of the mod.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/RoomTempCalc.lua") --Script used for a calculating temperature of rooms.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/Items.lua") -- Item methods.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/Compat.lua") -- Compat.
	end

end, 1)

-- By Lukako!
Timer.Wait(function()
    dofile(NTTHERM.Path .. "/Lua/Scripts/Shared/configData.lua") --Config.
end, 1)