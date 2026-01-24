-- Used for overriding other lua scripts with my nationalist addon.
-- Currently have robo trauma and enhanced reactors in here.


THERMCompat = {}


THERMCompat.SetUpRoboCompat = function ()
    NTRT.Afflictions["wet"] = {}
	NTRT.Afflictions["temperature"] = {}
	NTRT.Afflictions["givetemp"] = {}
end


THERMCompat.SetUpEnhancedReactors = function ()
    local overheating = AfflictionPrefab.Prefabs["overheating"]
    local radiationSickness = AfflictionPrefab.Prefabs["radiationsickness"]
    local contaminated = AfflictionPrefab.Prefabs["contaminated"]
    local radiationSounds = AfflictionPrefab.Prefabs["radiationsounds"]
    local burn = AfflictionPrefab.Prefabs["burn"]

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

    EnhancedReactors.ApplyTemperatureRadius = function (item, character, maxDistance, wallPenetration, armorPenetration, afflictions)
    if Vector2.Distance(character.WorldPosition, item.WorldPosition) > maxDistance then
        return
    end

    local position = item.Position

    local factor = math.min(Explosion.GetObstacleDamageMultiplier(ConvertUnits.ToSimUnits(position), position, character.SimPosition) * wallPenetration, 1)
    factor = factor * (1 - Vector2.Distance(character.WorldPosition, item.WorldPosition) / maxDistance)

    local limbsToCheck = {LimbType.Head,LimbType.Torso,LimbType.LeftArm,LimbType.RightArm,LimbType.LeftLeg,LimbType.RightLeg}
    for index, limb in pairs(limbsToCheck) do
        local animLimb = character.AnimController.GetLimb(limb,true,false,false)
        local AttackResult = animLimb.AddDamage(animLimb.SimPosition, afflictions, false, factor, armorPenetration, nil)
        character.CharacterHealth.ApplyDamage(animLimb, AttackResult, true)
    end
    end

    local temperature = AfflictionPrefab.Prefabs["temperature"]
    EnhancedReactors.ProcessItemUpdate = function (item) -- I override this to make thermal temp stuff apply.
    local reactor = item.GetComponentString("Reactor")
        if reactor then
            if reactor.Temperature > 40 then
                for character in Character.CharacterList do
                    local CharacterTable = THERM.GetCharacter(character.ID)
                    local BurnResistance = 1
                    if CharacterTable ~= nil then
                        BurnResistance = CharacterTable.DivingSuitBurnRes
                    end
                    EnhancedReactors.ApplyTemperatureRadius(item, character, 750, 1, 0, { temperature.Instantiate(.02 * (reactor.Temperature/100 + 1)/BurnResistance) }) -- :crying emoji: why does this mod have like a 1/100000 of a second tick rate.
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

            -- if not parentItem then
            --     if math.random() < 0.01 then
            --         FireSource(item.WorldPosition)
            --     end
            -- end

            if not parentItem or (not parentItem.HasTag("deepdivinglarge") and not parentItem.HasTag("containradiation")) then
                local data = fuelRods[item.Prefab.Identifier.Value]
                for character in Character.CharacterList do
                    local CharacterTable = THERM.GetCharacter(character.ID)
                    local BurnResistance = 1
                    if CharacterTable ~= nil then
                        BurnResistance = CharacterTable.DivingSuitBurnRes
                    end
                    EnhancedReactors.ApplyAfflictionRadius(item, character, 750, 1, 0, {
                        radiationSickness.Instantiate(1 * data.radiationSickness),
                        contaminated.Instantiate(1 * data.contaminated),
                        radiationSounds.Instantiate(1.25 * data.radiationSounds)
                })
                    EnhancedReactors.ApplyTemperatureRadius(item, character, 750, 1, 0, {
                        temperature.Instantiate((0.1 * data.overheating)/BurnResistance)})
                end

                if parentCharacter and not item.HasTag("emptyfuelrod") then
                    local slot = inventory.FindIndex(item)

                    if slot == inventory.FindLimbSlot(InvSlotType.RightHand) then
                        parentCharacter.CharacterHealth.ApplyAffliction(parentCharacter.AnimController.GetLimb(InvSlotType.RightHand), burn.Instantiate(1))
                    elseif slot == inventory.FindLimbSlot(InvSlotType.LeftHand) then
                        parentCharacter.CharacterHealth.ApplyAffliction(parentCharacter.AnimController.GetLimb(InvSlotType.LeftHand), burn.Instantiate(1))
                    end
                end

                if parentCharacter and item.HasTag("emptyfuelrod") then
                    local slot = inventory.FindIndex(item)

                    if slot == inventory.FindLimbSlot(InvSlotType.RightHand) then
                        parentCharacter.CharacterHealth.ApplyAffliction(parentCharacter.AnimController.GetLimb(InvSlotType.RightHand), burn.Instantiate(0.5))
                    elseif slot == inventory.FindLimbSlot(InvSlotType.LeftHand) then
                        parentCharacter.CharacterHealth.ApplyAffliction(parentCharacter.AnimController.GetLimb(InvSlotType.LeftHand), burn.Instantiate(0.5))
                    end
                end
            end

            if reactor then
                if parentItem.ConditionPercentage < 75 and not parentItem.HasTag("extrashielding") then
                    local data = fuelRods[item.Prefab.Identifier.Value]
                    for character in Character.CharacterList do
                        local CharacterTable = THERM.GetCharacter(character.ID)
                        local BurnResistance = 1
                        if CharacterTable ~= nil then
                            BurnResistance = CharacterTable.DivingSuitBurnRes
                        end
                        EnhancedReactors.ApplyAfflictionRadius(item, character, 750, 0.6, 0, {
                            radiationSickness.Instantiate((0.45 - parentItem.ConditionPercentage * 0.006) * data.radiationSickness),
                            contaminated.Instantiate((0.45 - parentItem.ConditionPercentage * 0.006) * data.contaminated),
                            radiationSounds.Instantiate((2.9 - parentItem.ConditionPercentage * 0.038) * data.radiationSounds)
                        })
                        EnhancedReactors.ApplyTemperatureRadius(item, character, 750, .6, 0, {
                        temperature.Instantiate(((0.18 - parentItem.ConditionPercentage * 0.0024) * data.overheating)/BurnResistance)})
                    end
                end
            end
        end
    end
end