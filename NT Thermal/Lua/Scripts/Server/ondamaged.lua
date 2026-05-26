-- Lol there's like nothing in here.

NT.OnDamagedMethods.explosiondamage = function(character, strength, limbtype) -- Heat from grenades and stuff
    HF.AddAfflictionLimb(character, "ntt_temperature", limbtype, strength/10, character) 
end