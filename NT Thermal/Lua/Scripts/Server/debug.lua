-- Debug ----------------------------------------------------------------------------------------------------------------------

-- Prints out Thermal data.
Hook.Add("chatMessage", "Debug", function (message, sender)
        if not NTConfig.Get("DebugMessageMode",false) then return end

        if message == "[DEBUG]THERMALCharacterData" then -- Contents of Thermal Character Data
                print("\n------------- Beginning Debug of NT THERMAL. -------------\n")
                for index, character in pairs(THERMCharacters) do
                        print("\n")
                        if character ~= nil then
                                print("Entry " .. tostring(index) .. ": " .. character.Character.Name)
                                for index2, field in character do
                                        print("Field " .. tostring(index2) .. ": " .. tostring(field))
                                end
                        else
                                print("Error, nil value at index: ", index)
                        end
                end
                print("\n--------------- Ending Debug of NT THERMAL. ---------------\n")
        end

        if message == "[DEBUG]THERMALRoomTemp" then -- Contents of Thermal Room Data
                print("\n------------- Beginning Debug of NT THERMAL. -------------\n")
                if THERMRoom.Rooms ~= nil then
                        for index2, room in pairs(THERMRoom.Rooms) do
                                print("Current Temp of " .. tostring(room.Hull) .. ": ".. tostring(room.Temp))
                        end
                else
                        print("Nil table.")
                end
                print("\n--------------- Ending Debug of NT THERMAL. ---------------\n")
        end

        if message == "[DEBUG]THERMALCharacterCount" then -- Size of Thermal Character Data
                print("\n------------- Beginning Debug of NT THERMAL. -------------\n")
                print("There are " .. tostring(THERM.IEnumerableSize(THERMCharacters)) .. " characters stored in the Thermal Character Table!")
                local Humans = {}
                for character in Character.CharacterList do
                    if character.IsHuman and not character.IsDead then
                        table.insert(Humans,character)
                    end
                end
                print("There are currently only " .. tostring(THERM.IEnumerableSize(Humans)) .. " characters in the session!")
                print("\n--------------- Ending Debug of NT THERMAL. ---------------\n")
        end

end)