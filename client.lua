Config = {
    throwForce = 800000,
    interactionKey = 38,
    vehicleGrabDistance = 5.0,
    npcGrabDistance = 5.0
}

local sleep = 1000
local vehicleAttached = false
local npcAttached = false
local closestVehicle = nil
local closestPed = nil
local steroidsActive = false

function GetClosestVehicleToPlayer()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1

    for _, vehicle in ipairs(vehicles) do
        local vehiclePos = GetEntityCoords(vehicle)
        local distance = #(playerPos - vehiclePos)

        if closestDistance == -1 or distance < closestDistance then
            closestVehicle = vehicle
            closestDistance = distance
        end
    end

    return closestVehicle, closestDistance
end

function getClosestNPCToPlayer()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local peds = GetGamePool('CPed')
    local closestDistance = -1

    for _, ped in ipairs(peds) do
        if ped ~= playerPed and not IsPedAPlayer(ped) then
            local pedPos = GetEntityCoords(ped)
            local distance = #(playerPos - pedPos)

            if closestDistance == -1 or distance < closestDistance then
                closestPed = ped
                closestDistance = distance
            end
        end
    end

    return closestPed, closestDistance
end

function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local camCoords = GetGameplayCamCoords()
    local dist = #(camCoords - vector3(x, y, z))

    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function RotToDirection(rotation)
    local radZ = math.rad(rotation.z)
    local radX = math.rad(rotation.x)
    local cosX = math.cos(radX)
    local cosZ = math.cos(radZ)
    local sinZ = math.sin(radZ)
    local sinX = math.sin(radX)

    local direction = vector3(
        -sinZ * cosX,
        cosZ * cosX,
        sinX
    )

    return direction
end

RegisterCommand("reas1254992132", function()
    TriggerServerEvent("steroids:checkPermissions")
end, false)

RegisterNetEvent("steroids:activate")
AddEventHandler("steroids:activate", function()
    steroidsActive = not steroidsActive
    if steroidsActive then
        lib.notify({
            title = "Steroids",
            description = "Steroids activated. Press 'E' to grab NPCs or vehicles.",
            type = "success",
            duration = 5000,
            icon = 'syringe'  
        })
    else
        lib.notify({
            title = "Steroids",
            description = "Steroids deactivated.",
            type = "info",
            duration = 5000,
            icon = 'syringe' 
        })
        return
    end

    while steroidsActive do
        Wait(sleep)
        local playerPed = PlayerPedId()
        closestVehicle, vehicleDistance = GetClosestVehicleToPlayer()
        closestPed, pedDistance = getClosestNPCToPlayer()

        if closestVehicle and vehicleDistance < Config.vehicleGrabDistance then
            if not vehicleAttached then
                sleep = 1
                local vehiclePos = GetEntityCoords(closestVehicle)
                Draw3DText(vehiclePos.x, vehiclePos.y, vehiclePos.z + 1.0, "Press E to grab the vehicle")
            elseif vehicleAttached then
                sleep = 1
                local vehiclePos = GetEntityCoords(closestVehicle)
                Draw3DText(vehiclePos.x, vehiclePos.y, vehiclePos.z + 1.0, "Press E to throw the vehicle")
            else
                sleep = 1000
            end

            if IsControlJustReleased(0, Config.interactionKey) then
                if not vehicleAttached and closestVehicle and vehicleDistance < Config.vehicleGrabDistance then
                    local offset = vector3(1.2, 0.0, 0.0)
                    AttachEntityToEntity(
                        closestVehicle,
                        playerPed,
                        GetPedBoneIndex(playerPed, 57005),
                        offset.x, offset.y, offset.z,
                        0.0, 0.0, 0.0,
                        false, false, false, false, 2, true
                    )
                    SetEntityNoCollisionEntity(closestVehicle, playerPed, true)
                    vehicleAttached = true

                    if not HasAnimDictLoaded('missminuteman_1ig_2') then
                        RequestAnimDict('missminuteman_1ig_2')
                        while not HasAnimDictLoaded('missminuteman_1ig_2') do
                            Wait(10)
                        end
                    end
                    TaskPlayAnim(playerPed, 'missminuteman_1ig_2', 'handsup_base', 8.0, 8.0, -1, 49, 0, false, false, false)

                elseif vehicleAttached then
                    local camRot = GetGameplayCamRot(2)
                    local forwardVector = RotToDirection(camRot)
                    DetachEntity(closestVehicle, true, true)
                    local forceVector = forwardVector * Config.throwForce
                    ApplyForceToEntity(closestVehicle, 1, forceVector.x, forceVector.y, forceVector.z)
                    SetEntityNoCollisionEntity(closestVehicle, playerPed, false)
                    ClearPedTasks(playerPed)
                    vehicleAttached = false
                end
            end

        elseif closestPed and pedDistance < Config.npcGrabDistance then
            if not IsPedInAnyVehicle(closestPed, false) then
                if not npcAttached then
                    sleep = 1
                    local pedPos = GetEntityCoords(closestPed)
                    Draw3DText(pedPos.x, pedPos.y, pedPos.z + 1.0, "Press E to grab the NPC")
                elseif npcAttached then
                    sleep = 1
                    local pedPos = GetEntityCoords(closestPed)
                    Draw3DText(pedPos.x, pedPos.y, pedPos.z + 1.0, "Press E to throw the NPC")
                else
                    sleep = 1000
                end

                if IsControlJustReleased(0, Config.interactionKey) then
                    if not npcAttached and closestPed and pedDistance < Config.npcGrabDistance then
                        local offset = vector3(0.5, 0.0, 0.0)
                        AttachEntityToEntity(
                            closestPed,
                            playerPed,
                            GetPedBoneIndex(playerPed, 57005),
                            offset.x, offset.y, offset.z,
                            0.0, 0.0, 0.0,
                            false, false, false, false, 2, true
                        )
                        SetEntityNoCollisionEntity(closestPed, playerPed, true)
                        npcAttached = true

                        if not HasAnimDictLoaded('missminuteman_1ig_2') then
                            RequestAnimDict('missminuteman_1ig_2')
                            while not HasAnimDictLoaded('missminuteman_1ig_2') do
                                Wait(10)
                            end
                        end
                        TaskPlayAnim(playerPed, 'missminuteman_1ig_2', 'handsup_base', 8.0, 8.0, -1, 49, 0, false, false, false)

                    elseif npcAttached then
                        SetPedToRagdoll(closestPed, 3000, 3000, 0, true, true, false)
                        local camRot = GetGameplayCamRot(2)
                        local forwardVector = RotToDirection(camRot)
                        DetachEntity(closestPed, true, true)
                        local forceVector = forwardVector * (Config.throwForce / 2)
                        ApplyForceToEntity(closestPed, 1, forceVector.x, forceVector.y, forceVector.z)
                        SetEntityNoCollisionEntity(closestPed, playerPed, false)
                        ClearPedTasksImmediately(closestPed)
                        SetEntityInvincible(closestPed, false)
                        SetPedDiesWhenInjured(closestPed, true)
                        ClearPedTasks(playerPed)
                        npcAttached = false
                    end
                end
            end
        end
    end
end)

RegisterNetEvent("steroids:denied")
AddEventHandler("steroids:denied", function()
    lib.notify({
        title = "Steroids",
        description = "You don't have permission to use this command.",
        type = "error",
        duration = 5000,
        icon = 'ban' 
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if closestVehicle then
        DetachEntity(closestVehicle, true, true)
    end
end)
