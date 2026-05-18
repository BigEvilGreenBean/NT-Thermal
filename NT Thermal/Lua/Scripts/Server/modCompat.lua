-- Used for mod compatibility.


THERMCompat = {}
-- EH
THERMCompat.EH = {}
THERMCompat.EH.Tick = 0
THERMCompat.EH.UpdateInterval = 60
THERMCompat.EH.DeltaTime = THERMCompat.EH.UpdateInterval/40
THERMCompat.EH.ManagedItems = {}

Util.RegisterItemGroup("reactors", function (item)
    return item.GetComponentString("Reactor") ~= nil
end)


-- Credit to _]|M|[_ for the original Enhanced Reactors mod.
local reactors = {
    ["reactor1"] = true,
    ["outpostreactor"] = true,
    ["ekdockyard_reactorslow_small"] = true,
    ["ekdockyard_reactor_mini"] = true,
    ["ekdockyard_reactor_small"] = true
}

local fuelRods = {
    ["uraniumfuelrod_er"] = {
        radiationSickness = 1,
        contaminated = 1,
        radiationSounds = 3.5,
        overheating = 1
    },
    ["thoriumfuelrod_er"] = {
        radiationSickness = 0.5,
        contaminated = 0.5,
        radiationSounds = 2.0,
        overheating = 1.5,
    },
    ["fulguriumfuelrod_er"] = {
        radiationSickness = 2,
        contaminated = 2,
        radiationSounds = 4.5,
        overheating = 2,
    },
    ["fulguriumfuelrodvolatile_er"] = {
        radiationSickness = 3,
        contaminated = 3,
        radiationSounds = 5.5,
        overheating = 3,
    },
    ["emptyfuelrod"] = {
        radiationSickness = 0.1,
        contaminated = 0.2,
        radiationSounds = 1.5,
        overheating = 0.2,
    },
    ["fuelrod_outpost"] = {
        radiationSickness = 1,
        contaminated = 1,
        radiationSounds = 3.5,
        overheating = 1
    }
}

THERMCompat.ProcessItem = function (item)
    if reactors[item.Prefab.Identifier.Value] then
        item.AddTag("lua_managed")
        table.insert(THERMCompat.EH.ManagedItems, item)
    end

    if fuelRods[item.Prefab.Identifier.Value] then
        item.AddTag("lua_managed")
        -- item.AddTag("fuelrod")
        table.insert(THERMCompat.EH.ManagedItems, item)
    end
end

THERMCompat.RemoveItem = function (item)
    for i, managedItem in ipairs(THERMCompat.EH.ManagedItems) do
        if managedItem == item then
            table.remove(THERMCompat.EH.ManagedItems, i)
            break
        end
    end
end

THERMCompat.ApplyTemperatureRadius = function (item, character, maxDistance, wallPenetration, armorPenetration, afflictions)
if character.IsBot and NTConfig.Get("ReactorsGiveTemperatureBot", true) or not character.IsBot then
    if not (NTConfig.Get("BotTempIgnoreMode", true) and character.IsBot) and not (NTConfig.Get("PressureStabilizerTemperature", true) and HF.GetAfflictionStrength(character, "pressurestabilized", 0) > 0) then
        if HF.GetAfflictionStrength(character, "givetemp", 0) > 0 then -- Make sure the temperature is actually set up.
            if Vector2.Distance(character.WorldPosition, item.WorldPosition) > maxDistance then
                return
            end

            local position = item.Position

            local factor = math.min(Explosion.GetObstacleDamageMultiplier(ConvertUnits.ToSimUnits(position), position, character.SimPosition) * wallPenetration, 1)
            factor = factor * (1 - Vector2.Distance(character.WorldPosition, item.WorldPosition) / maxDistance)

            local limbsToCheck = {LimbType.Head,LimbType.Torso,LimbType.LeftArm,LimbType.RightArm,LimbType.LeftLeg,LimbType.RightLeg}
            for index, limb in pairs(limbsToCheck) do
                local animLimb = character.AnimController.GetLimb(limb,true,false,false)
                if animLimb ~= nil then -- I have no clue why this is needed but it stops the debugger from throwing a metric shit load of errors at me. Ydrec if you can hear me ydrec save me ydrec.
                    local AttackResult = animLimb.AddDamage(animLimb.SimPosition, afflictions, false, factor, armorPenetration, nil)
                    character.CharacterHealth.ApplyDamage(animLimb, AttackResult, true)
                end
            end
            end
        end
    end
end

local temperature = AfflictionPrefab.Prefabs["ntt_temperature"]
THERMCompat.ProcessItemUpdate = function (item) -- My forked EH version.
local reactor = item.GetComponentString("Reactor")
    if reactor then
        if reactor.Temperature > 40 then
            for character in Character.CharacterList do
                local CharacterTable = THERM.GetCharacter(character.ID)
                local BurnResistance = THERM.TotalBurnResistance(CharacterTable)
                THERMCompat.ApplyTemperatureRadius(item, character, 750, 1, 0, { temperature.Instantiate(.5 * ((reactor.Temperature/100 + 1))/BurnResistance  * THERMCompat.EH.DeltaTime) }) -- :crying emoji: why does this mod have like a 1/100000 of a second tick rate.
            end
        end
    end

    if item.HasTag("fuelroditem") and item.HasTag("activefuelrod") then
        local inventory = item.ParentInventory

        local parentItem = nil
        local parentCharacter = nil

        if inventory then
            if LuaUserData.IsTargetType(inventory, "Barotrauma.ItemInventory") then
                parentItem = inventory.Owner
            else
                parentCharacter = inventory.Owner
            end
        end

        local reactor = parentItem and parentItem.GetComponentString("Reactor") or nil

        if not parentItem or (not parentItem.HasTag("deepdivinglarge") and not parentItem.HasTag("containradiation")) then
            local data = fuelRods[item.Prefab.Identifier.Value]
            for character in Character.CharacterList do
                local CharacterTable = THERM.GetCharacter(character.ID)
                local BurnResistance = THERM.TotalBurnResistance(CharacterTable)
                THERMCompat.ApplyTemperatureRadius(item, character, 750, 1, 0, {
                    temperature.Instantiate((2 * data.overheating * THERMCompat.EH.DeltaTime)/BurnResistance)})
            end
        end

        if reactor then
            if parentItem.ConditionPercentage < 75 and not parentItem.HasTag("extrashielding") then
                local data = fuelRods[item.Prefab.Identifier.Value]
                for character in Character.CharacterList do
                    local CharacterTable = THERM.GetCharacter(character.ID)
                    local BurnResistance = THERM.TotalBurnResistance(CharacterTable)
                    THERMCompat.ApplyTemperatureRadius(item, character, 750, 1, 0, {temperature.Instantiate((0.5 * data.overheating * THERMCompat.EH.DeltaTime)/BurnResistance)})
                end
            end
        end
    end
end

for item in Item.ItemList do
    THERMCompat.ProcessItem(item)
end

Hook.Add("item.created", "THERMCompat.ItemCreated", function (item)
    THERMCompat.ProcessItem(item)
end)

Hook.Add("item.removed", "THERMCompat.ItemRemoved", function (item)
    THERMCompat.RemoveItem(item)
end)


-- Hit a lick and lifted this from the Human update.
Hook.Add("think", "THERMCompat.updateEH", function()
    if NTConfig.Get("ReactorsGiveTemperature", true) or NTTHERM.UsingEnhancedReactors then
        if HF.GameIsPaused() then
            return
        end

        THERMCompat.EH.Tick = THERMCompat.EH.Tick - 1
        if THERMCompat.EH.Tick <= 0 then
                    THERMCompat.EH.UpdateInterval = NTConfig.Get("ThermalReactorTempInterval", 60)
                    THERMCompat.EH.Tick = THERMCompat.EH.UpdateInterval
                    for item in THERMCompat.EH.ManagedItems do
                        THERMCompat.ProcessItemUpdate(item)
                    end
        end
    end
end)