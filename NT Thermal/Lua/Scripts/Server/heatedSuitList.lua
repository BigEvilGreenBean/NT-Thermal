-- I store all the heated suits in here, just to reduce bloat.

THERMSuits = {}

HeatedSuits = {
    -- index is the battery heater index. The 'needsTag' is a boolean check to see if the diving suit needs the "thermal" tag in the suit.
    -- Vanilla
    ["respawndivingsuit"] = {index = 0, needsTag = false},["exosuit"] = {index = 1, needsTag = false},["clownexosuit"] = {index = 1, needsTag = false},["pucs"] = {index = 2, needsTag = true},["medicdivingsuit"] = {index = 2, needsTag = true}, -- These needs tag since they don't have a battery slot by default.

    -- Safs
    ["SAFS"] = {index = 1, needsTag = false}, ["SAFS_V7"] = {index = 1, needsTag = false}, ["SAFS_nāga"] = {index = 1, needsTag = false}, ["SAFS_snow"] = {index = 1, needsTag = false}, ["SAFS_yellow"] = {index = 1, needsTag = false}, 
    ["SAFS_manual"] = {index = 1, needsTag = false}, ["SAFS_seaweed"] = {index = 1, needsTag = false}, ["SAFS_clown"] = {index = 1 , needsTag = false}, ["SAFS_camo"] = {index = 1, needsTag = false}, ["SAFS_moon"] = {index = 1, needsTag = false},  
    ["SAFS_onyx"] = {index = 1, needsTag = false}, ["SAFS_camo2"] = {index = 1, needsTag = false}, 

    -- Dynamic Europa
    ['exosuitplayerPA'] = {index = 1, needsTag = false}, ['exosuitPA'] = {index = 1, needsTag = false}, ["piratedivingsuitmakeshift"] = {index = 0, needsTag = false},  -- Dynamic Europa
    
    -- Enhanced Armaments
    ['scp_combathardsuit'] = {index = 1, needsTag = false}, 
    
    -- Baroverhaul (Kill me)
    ["rustedexosuit"] = {index = 1, needsTag = false},  ["assistantexosuit"] = {index = 1, needsTag = false},  ["captainexosuit"] = {index = 1, needsTag = false},  ["engineerexosuit"] = {index = 1, needsTag = false}, 
    ["medicexosuit"] = {index = 1, needsTag = false},  ["mechanicexosuit"] = {index = 1, needsTag = false},  ["securityexosuit"] = {index = 1, needsTag = false},  ["charybdisexosuit"] = {index = 1, needsTag = false}, 
    ["fractalexosuit"] = {index = 1, needsTag = false},  ["latcherexosuit"] = {index = 1, needsTag = false},  ["advancedexosuit"] = {index = 1, needsTag = false},  ["crystalexosuit"] = {index = 1, needsTag = false}, 
    ["barsukexosuit"] = {index = 1, needsTag = false},  ["endwormexosuit"] = {index = 1, needsTag = false},  ["watcherexosuit"] = {index = 1, needsTag = false},  ["blueadvancedexosuit"] = {index = 1, needsTag = false}, 
    ["greenadvancedexosuit"] = {index = 1, needsTag = false},  ["redadvancedexosuit"] = {index = 1, needsTag = false},  ["pinkadvancedexosuit"] = {index = 1, needsTag = false} 
    }

ExceptionsToNotUSE = {["stasisbag"] = true} -- Used for suits that we don't want to count.

PackageSuits = { -- A list with specific versions of suits (I.E same mod different versions.)
    ["3434408187"] = { -- EK Forked
                ["ek_armored_hardsuit"] = {index = 1, needsTag = false}, ["ek_armored_hardsuit_paintbandit"] = {index = 1, needsTag = false}, ["ek_armored_hardsuit_paintmercenary"] = {index = 1, needsTag = false}, ["ek_armored_hardsuit2"] = {index = 1, needsTag = false}, 
                ["ek_armored_hardsuit2_paintbandit"] = {index = 1, needsTag = false}, ["ek_armored_hardsuit2_paintmercenary"] = {index = 1, needsTag = false}, 
                ["ekutility_Utility_hardsuit_mk2"] = {index = 1, needsTag = false}, 
            },
        }

-- Smart system (Not finished)
--THERMSuits.FindHeater = function (Suit)
    --for element in Suit.Prefab.ConfigElement.Elements() do
        --if tostring(element) == "ItemContainer" then
            
        --end
    --end
--end

-- Hi Lukako, I stole this from your guide!
-- Adds suits from certain mods.
THERMSuits.RegisterPackages = function ()
    for mod in ContentPackageManager.EnabledPackages.All do
        if PackageSuits[tostring(mod.UgcId)] ~= nil then
            for Index, SuitTable in pairs(PackageSuits[tostring(mod.UgcId)]) do
                if HeatedSuits[Index] == nil then
                    HeatedSuits[Index] = SuitTable
                end
            end
        end
    end
end

 -- MOD COMPAT ----------------------------------------------------------------------------------------------------------------------------

---A mod compat function to add your own suits without thermal tags. If you want.
---@param SuitTable table
THERMSuits.AddHeatedSuit = function (SuitTable) -- Your suit table should look something like {["Insert name"] = {index = 'battery_index', needsTag = false/true}
    table.insert(HeatedSuits,SuitTable)
end

---A mod compat function to add your own excepted suits. If you want.
---@param SuitTable table
THERMSuits.AddNonHeatedSuit = function (SuitTable) -- Your suit table should look something like {["Insert name"] = true}
    table.insert(ExceptionsToNotUSE,SuitTable)
end

THERMSuits.RegisterPackages()