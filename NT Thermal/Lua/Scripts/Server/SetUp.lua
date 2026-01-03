

-- To whom ever might be reading this, this mod relies on a single affliction to work. Is this the most efficent? Probably not, can I think of a better way? Also no.
-- This script handles the setting of the 'givetemperature' affliction.
-- Temperature is calculated in celsius. :(, eagle brain cannot compute.
-- As of making this mod, I lost one of my best friend's to Tarkov, reach out to your friends, make sure they're okay. It's crazy how widespread the plaque is.

-- Give every human in server "givehypothermia" and adds to THERM
Hook.Add("character.created", "Newcharacter", function (createdCharacter)
    -- Verify not nil
    if createdCharacter ~= nil and createdCharacter.IsHuman and HF ~= nil then
        -- Verify if the character has a client, that it's loaded in.
        if Util.FindClientCharacter(createdCharacter) == nil and THERM.GetCharacter(createdCharacter.Name) == nil then
            IntiateCharacterTemp(createdCharacter) 
        end
    end
end)


Hook.Add("Client.Connected", "ClientHasConnected", function (connectedClient)
    if connectedClient ~= nil and connectedClient.HasSpawned and connectedClient.Character ~= nil and connectedClient.Character.IsHuman and THERM.GetCharacter(connectedClient.Character.Name) == nil then
        IntiateCharacterTemp(connectedClient.Character)
    end
end)


-- Removes human in server from THERM
Hook.Add("character.death", "Newcharacter", function (createdCharacter)
    -- Verify not nil
    local CharacterResult = THERM.GetCharacter(createdCharacter.Name)
    if createdCharacter ~= nil and CharacterResult ~= nil then
        -- Register character in hypothermia table.
        table.remove(THERMCharacters,CharacterResult.tableIndex)
        print(createdCharacter.Name, " has been removed from the genepool.")
    end
end)


Hook.Patch("Barotrauma.GameSession", "ReviveCharacter", function(GameSession, ptable)
    -- Verify not nil
    local revivedcharacter = ptable["character"]
    if revivedcharacter ~= nil and revivedcharacter.IsHuman and THERM.GetCharacter(revivedcharacter.Name) == nil then
        IntiateCharacterTemp(revivedcharacter)
    end
 end, Hook.HookMethodType.After)


function IntiateCharacterTemp(createdCharacter)
    print(createdCharacter.Name, " has been added to the genepool.")
    HF.SetAffliction(createdCharacter, "give_temperature", 100)
    for i, limb in pairs(createdCharacter.AnimController.Limbs) do
        HF.SetAfflictionLimb(createdCharacter, "temperature", limb.type, NTConfig.Get("NormalBodyTemp", 38))
    end
    -- Register character in hypothermia table.
    local new_character = {CharacterName = createdCharacter.Name, 
                            LimbWaterValues = {HeadV = 0, TorsoV = 0, RightArmV = 0, LeftArmV = 0, LeftThigTHERM = 0, RightThigTHERM = 0}, 
                            PressureStrength = 1, 
                            AirTemp = 22, 
                            OnFire = false,
                            InCustomWater = false,
                            LastHullWaterVolume = 0,
                            LastStoredPlayerY = 0}
    table.insert(THERMCharacters,new_character)
end
