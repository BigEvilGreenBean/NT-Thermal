-- Dedicated to Daddy Noel and Uncle P
-- Used to store the temperature info of rooms and functions.
THERMRoom = {}
THERMRoom.Tick = 0
THERMRoom.UpdateInterval = 50
THERMRoom.DeltaTime = THERMRoom.UpdateInterval/620
THERMRoom.DefaultRoomTemp = 22
THERMRoom.Rooms = {}
THERMRoom.Intiated = false
THERMRoom.QueuedOxygenUpdates = {}

-- Resets thermal data.
NTC.AddPreHumanUpdateHook(
        function(character)
	if not THERMRoom.Intiated then
                THERM.ValidateThermalCharacterData()
		THERMRoom.Intiated = true
        end
end)

-- Used to clear Thermal Room Data.
Hook.Add("roundEnd", "The round ended", function ()
        THERMRoom.Intiated = false
        THERMRoom.Rooms = {}
end)

-- Hit a lick and lifted this from the Human update.
Hook.Add("think", "THERMRoom.update", function()
	if HF.GameIsPaused() then
		return
	end

	THERMRoom.Tick = THERMRoom.Tick - 1
	if THERMRoom.Tick <= 0 then
                if THERMRoom.Rooms ~= nil and THERMRoom.Intiated then
                        THERMRoom.CalculateRoomTemp()
                end
                THERMRoom.Tick = THERMRoom.UpdateInterval
	end
end)

-- Heat
Hook.Patch("Barotrauma.Hull","AddFireSource", function (GameSession, ptable)
        local hull = ptable["fireSource"].Hull
        if THERMRoom.GetRoom(hull) == nil and THERMRoom.Intiated then
                THERMRoom.InsertRoom(hull)
        end
end, Hook.HookMethodType.After)

-- Used to increase the temp of a adjacent room if parameters match.
Hook.Add("gapOxygenUpdate", "NTTHERM.OxygenHullUpdate", function (gap, hull1, hull2)
        if THERMRoom.Intiated and THERMRoom.QueuedOxygenUpdates[gap] == nil and (hull1.FireCount > 0 or hull2.FireCount > 0) then
                THERMRoom.QueueOxygenUpdate(gap,hull1,hull2)
        end
end)

-- Used to calculate a hull's temp.
THERMRoom.CalculateRoomTemp = function ()
        -- Check each room.
        if THERMRoom.Rooms ~= nil and THERMRoom.Intiated then
                for index, update in pairs(THERMRoom.QueuedOxygenUpdates) do -- Used for transferring heat between hulls
                        local hull1 = update.hullA
                        local hull2 = update.hullB
                        local ParentHull = nil
                        local ChildHull = nil
                        if THERMRoom.GetRoom(hull1) ~= nil and hull1.FireCount > 0 then
                                ParentHull = hull1
                                ChildHull = hull2
                        elseif THERMRoom.GetRoom(hull2) ~= nil and hull2.FireCount > 0 then
                                ParentHull = hull2
                                ChildHull = hull1
                        else
                                THERMRoom.QueuedOxygenUpdates[update] = nil -- Set update to nil
                                break
                        end
                        Timer.Wait(function() -- Delay it a little.
                                if THERMRoom.GetRoom(ChildHull) == nil then
                                        THERMRoom.InsertRoom(ChildHull)
                                end
                                --Limit the amount of heat chain linked.
                                if THERMRoom.GetRoom(ChildHull).Temp < THERMRoom.GetRoom(ParentHull).Temp/1.5 then
                                        local TempTransfer = THERMRoom.GetRoom(ParentHull).Temp
                                                /(ChildHull.Size.X * ChildHull.Size.Y)
                                                * 3000  --Scale it a lil.
                                        THERMRoom.GetRoom(ChildHull).Temp = HF.Clamp(THERMRoom.GetRoom(ChildHull).Temp + (TempTransfer/2),THERMRoom.DefaultRoomTemp,THERMRoom.GetRoom(ParentHull).Temp)
                                        THERMRoom.GetRoom(ParentHull).Temp = HF.Clamp(THERMRoom.GetRoom(ParentHull).Temp - (TempTransfer / 50),THERMRoom.DefaultRoomTemp,THERMRoom.GetRoom(ParentHull).Temp/2,100)
                                end
                                THERMRoom.QueuedOxygenUpdates[update] = nil -- I'm quite sure this one does nothing on a real note, but I'm afraid to delete it.
                                THERMRoom.QueuedOxygenUpdates[index] = nil -- Set update to nil
                        end,10)
                end
                for index, room in pairs(THERMRoom.Rooms) do -- Update current temps.
                        if room ~= nil and room.Hull ~= nil then
                                local Hull = room.Hull
                                local HullArea = Hull.Size.X * Hull.Size.Y
                                local TempGain = 0
                                -- For each fire source increase room temp.
                                if Hull.FireCount > 0 then
                                        for index2, fire in pairs(Hull.FireSources) do
                                                local FireArea = fire.Size.X * fire.Size.Y
                                                TempGain = FireArea/HullArea * 2000 / Hull.FireCount * THERMRoom.DeltaTime
                                                room.Temp = HF.Clamp(room.Temp + TempGain,THERMRoom.DefaultRoomTemp,100)
                                        end
                                -- If no fireSources then check if temp is stablizied.
                                elseif room.Temp <= THERMRoom.DefaultRoomTemp then
                                        THERMRoom.RemoveRoom(room)
                                -- Decrease room temp.
                                else
                                        local WaterCooling = (Hull.WaterVolume / (Hull.Size.X * Hull.Size.Y)) + 1
                                        TempGain = 10000000 -- This is like the average size of a room, I think, I low key forgot why I chose this number gang.
                                                        /HullArea 
                                                        * -1 
                                                        * WaterCooling
                                                        * THERMRoom.DeltaTime
                                        room.Temp = HF.Clamp(room.Temp + TempGain,THERMRoom.DefaultRoomTemp,100)
                                end
                        else
                                THERMRoom.RemoveRoom(room)
                        end
                end
        end
end

-- Inserts a room into the THERMRoom table with a hull table.
THERMRoom.InsertRoom = function (hull)
        if hull ~= nil then
                if THERMRoom.Rooms == nil then
                        THERMRoom.Rooms = {}
                end
                local HullTable = {Hull = hull, Temp = THERMRoom.DefaultRoomTemp, id = hull.ID}
                THERMRoom.Rooms[hull.ID] = HullTable
        end
end

-- Removes a room from the THERMRoom table with a hull table.
THERMRoom.RemoveRoom = function (hull)
        if hull ~= nil then
                THERMRoom.Rooms[hull.id] = nil
        end
end

-- Fetches a room from the THERMroom table with a hull value.
THERMRoom.GetRoom = function (hull)
        if hull ~= nil and THERMRoom.Rooms ~= nil then
                return THERMRoom.Rooms[hull.ID]
        end
        return nil
end

-- Adds a oxygen update to the queue.
THERMRoom.QueueOxygenUpdate = function (gap,hull1,hull2)
        THERMRoom.QueuedOxygenUpdates[gap] = {hullA = hull1,hullB = hull2}
end