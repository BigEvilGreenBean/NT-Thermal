

-- Heat
Hook.Patch("Barotrauma.Hull","AddFireSource", function (GameSession, ptable)
        print(#ptable["fireSource"].Hull.FireSources, ", Size: ", ptable["fireSource"].Size)
end, Hook.HookMethodType.After)


-- Hook for the Rat jacuzzi
Hook.Patch("Barotrauma.Hull","RemoveFire", function (GameSession, ptable)
        print(ptable["fire"].Hull)
end, Hook.HookMethodType.After)
