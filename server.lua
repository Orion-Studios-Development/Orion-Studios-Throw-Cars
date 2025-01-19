HasPermission = function(src)
    return IsPlayerAceAllowed(src, 'throwvehicle') 
end

RegisterServerEvent("steroids:checkPermissions")
AddEventHandler("steroids:checkPermissions", function()
    local src = source

    if HasPermission(src) then
        TriggerClientEvent("steroids:activate", src)
    else
        TriggerClientEvent("steroids:denied", src)
    end
end)
