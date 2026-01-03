

-- Store all submarines in here.
Submarines = {}
Rooms = {}


local round_started = false
Hook.Add("roundStart", "The round started", function ()
    round_started = true
end)


Hook.Add("roundEnd", "The round ended", function ()
    round_started = false
end)


Hook.Patch("Barotrauma.Submarine", "Load", function (GameSession, Submarine)
    print(Submarine["sub"])
end)