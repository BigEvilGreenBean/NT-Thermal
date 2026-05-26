-- I store all the heated suits in here, just to reduce bloat.

THERMSuits = {}

HeatedSuits = {
    -- Vanilla
    ["respawndivingsuit"] = 0,["exosuit"] = 1,["clownexosuit"] = 1,["pucs"] = 2,["medicdivingsuit"] = 2,

    -- Safs
    ["SAFS"] = 1,["SAFS_V7"] = 1,["SAFS_nāga"] = 1,["SAFS_snow"] = 1,["SAFS_yellow"] = 1,
    ["SAFS_manual"] = 1,["SAFS_seaweed"] = 1,["SAFS_clown"] = 1 ,["SAFS_camo"] = 1,["SAFS_moon"] = 1, 
    ["SAFS_onyx"] = 1,["SAFS_camo2"] = 1,

    -- EK
    ["ek_armored_hardsuit"] = 1,["ek_armored_hardsuit_paintbandit"] = 1,["ek_armored_hardsuit_paintmercenary"] = 1,["ek_armored_hardsuit2"] = 1,
    ["ek_armored_hardsuit2_paintbandit"] = 1,["ek_armored_hardsuit2_paintmercenary"] = 1,
    ["ekutility_Utility_hardsuit_mk2"] = 1,

    -- Dynamic Europa
    ['exosuitplayerPA'] = 1,['exosuitPA'] = 1,["piratedivingsuitmakeshift"] = 0, -- Dynamic Europa
    
    -- Enhanced Armaments
    ['scp_combathardsuit'] = 1,
    
    -- Baroverhaul (Kill me)
    ["rustedexosuit"] = 1, ["assistantexosuit"] = 1, ["captainexosuit"] = 1, ["engineerexosuit"] = 1,
    ["medicexosuit"] = 1, ["mechanicexosuit"] = 1, ["securityexosuit"] = 1, ["charybdisexosuit"] = 1,
    ["fractalexosuit"] = 1, ["latcherexosuit"] = 1, ["advancedexosuit"] = 1, ["crystalexosuit"] = 1,
    ["barsukexosuit"] = 1, ["endwormexosuit"] = 1, ["watcherexosuit"] = 1, ["blueadvancedexosuit"] = 1,
    ["greenadvancedexosuit"] = 1, ["redadvancedexosuit"] = 1, ["pinkadvancedexosuit"] = 1
    }

ExceptionsToNotUSE = {["stasisbag"] = true} -- Used for suits that we don't want to count.

 -- MOD COMPAT ----------------------------------------------------------------------------------------------------------------------------

THERMSuits.AddHeatedSuit = function (SuitTable) -- Your suit table should look something like {["Insert name"] = battery_index}
    table.insert(HeatedSuits,SuitTable)
end

THERMSuits.AddNonHeatedSuit = function (SuitTable) -- Your suit table should look something like {["Insert name"] = true}
    table.insert(ExceptionsToNotUSE,SuitTable)
end