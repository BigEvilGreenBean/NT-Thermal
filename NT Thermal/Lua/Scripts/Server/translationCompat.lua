
THERMTranslation = {}

EnglishTranslation = {
                    Readout = "Temperature readout of ", Hypothermic = "Hypothermic", Hyperthermic = "Hyperthermic", 
                    NormalTemp = "Normal temperature range", LimbsToCheck = {
                        [LimbType.Torso]      = "Torso",
                        [LimbType.Head]       = "Head",
                        [LimbType.LeftArm]    = "Left Arm",
                        [LimbType.RightArm]   = "Right Arm",
                        [LimbType.LeftThigh]  = "Left Leg",
                        [LimbType.RightThigh] = "Right Leg"},
                    Body = "Body"
}
RussianTranslation = {
                    Readout = "Температура тела ", Hypothermic = "Гипотермия", Hyperthermic = "Гипертермия", 
                    NormalTemp = "Температура в пределах нормы", LimbsToCheck = {
                        [LimbType.Torso]      = "Торс",
                        [LimbType.Head]       = "Голова",
                        [LimbType.LeftArm]    = "Левая рука",
                        [LimbType.RightArm]   = "Правая рука",
                        [LimbType.LeftThigh]  = "Левая нога",
                        [LimbType.RightThigh] = "Правая нога"},
                    Body = "Тело"
}
Translation = {
                    ["English"] = EnglishTranslation,
                    ["Russian"] = RussianTranslation
}

-- Use this to add translations to the thermometer.
THERMTranslation.AddTranslation = function (language, translation_table)
    Translation[language] = translation_table
end