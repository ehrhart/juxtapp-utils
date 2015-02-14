# juxtapp-utils
Utils lib class for Juxta++

# How to use
Inside your plugin script, add these functions(or modify them if they already exist)

    require 'utils'
    
    function OnServerTick(ticks)
      utils_OnServerTick(ticks)
    end
    
    function OnPlayerInit(player)
      utils_OnPlayerInit(player)
    end
