-- Most of this code has been lifted from NT Eyes, you should go check it out. Thank you POSTACI.
-- Set up dictonary
NTTHERM = {}
NTTHERM.Name = "Thermal"
NTTHERM.Version = "1.0.1h14"
NTTHERM.VersionNum = 000000001
NTTHERM.MinNTVersion = "A1.12.1"
NTTHERM.MinNTVersionNum = 01120100
NTTHERM.Path = table.pack(...)[1]
-- I don't think this is required.
NTTHERM.UpdateAfflictions = {}
NTTHERM.UpdateLimbAfflictions = {}
NTTHERM.UpdateBloodAfflictions = {}


Timer.Wait(function ()
    if NTC ~= nil then
        NTC.RegisterExpansion(NTTHERM)
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
		dofile(NTTHERM.Path .. "/Lua/Scripts/Shared/configData.lua") --Config.
		dofile(NTTHERM.Path .. "/Lua/Scripts/Server/Items.lua") -- Item methods.
	end
end, 1)