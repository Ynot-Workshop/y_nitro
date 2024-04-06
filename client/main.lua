local config = require 'config.client'
local nitrousActivated = false
local nitrousBoost = config.nitrousBoost
local nitroDelay = false
local PurgeLoop = false

local function setMultipliers(vehicle, disable)
    local multiplier = disable and 1.0 or nitrousBoost
    SetVehicleEnginePowerMultiplier(vehicle, multiplier)
    SetVehicleEngineTorqueMultiplier(vehicle, multiplier)
end

local function stopBoosting()
    SetVehicleBoostActive(cache.vehicle, false)
    setMultipliers(cache.vehicle, true)
    Entity(cache.vehicle).state:set('nitroFlames', false, true)
    StopScreenEffect('RaceTurbo')
    nitrousActivated = false
end

local function nitrousUseLoop()
    nitrousActivated = true
    nitroDelay = true
    SetTimeout(3000, function()
        nitroDelay = false
    end)
    local vehicleState = Entity(cache.vehicle).state
    SetVehicleBoostActive(cache.vehicle, true)
    CreateThread(function()
        while nitrousActivated and cache.vehicle do
            if vehicleState.nitro - 0.25 >= 0 then
                setMultipliers(cache.vehicle, false)
                SetEntityMaxSpeed(cache.vehicle, 999.0)
                StartScreenEffect('RaceTurbo', 0, false)
                vehicleState:set('nitro', vehicleState.nitro - 0.25, true)
                vehicleState:set('nitroPurge', (vehicleState.nitroPurge or 0) + 1, true)
                if vehicleState.nitroPurge >= 100 then
                    exports.qbx_core:Notify(locale('notify.needs_purge'), 'error')
                    stopBoosting()
                end
            else
                stopBoosting()
                vehicleState:set('nitro', 0, true)
            end
            Wait(100)
        end
    end)
end

local function stopPurging()
    local vehicleState = Entity(cache.vehicle).state
    vehicleState:set('purgeNitro', false, true)
    PurgeLoop = false
end

local function nitrousPurgeLoop()
    local vehicleState = Entity(cache.vehicle).state
    PurgeLoop = true
    CreateThread(function()
        while PurgeLoop and cache.vehicle do
            if vehicleState.nitroPurge - 1 >= 0 then
                vehicleState:set('nitroPurge', vehicleState.nitroPurge - 1, true)
            else
                vehicleState:set('nitroPurge', 0, true)
                stopPurging()
            end
            Wait(100)
        end
    end)
end

qbx.entityStateHandler('nitroFlames', function(veh, netId, value)
    if not veh or not DoesEntityExist(veh) then return end

    lib.requestNamedPtfxAsset("veh_xs_vehicle_mods")
    SetVehicleNitroEnabled(veh, value)
    EnableVehicleExhaustPops(veh, not value)
    SetVehicleBoostActive(veh, value)
end)

local purge = {}
qbx.entityStateHandler('purgeNitro', function(veh, netId, value)
    if not veh or not DoesEntityExist(veh) then return end

    if not value then
        local currentPurge = purge[veh]
        if currentPurge?.left then
            StopParticleFxLooped(currentPurge.left, false)
        end
        if currentPurge?.right then
            StopParticleFxLooped(currentPurge.right, false)
        end
        purge[veh] = nil
        return
    end

    local bone
    local pos
    local off

    bone = GetEntityBoneIndexByName(veh, "bonnet")
    if bone == -1 then
        bone = GetEntityBoneIndexByName(veh, "engine")
    end

    pos = GetWorldPositionOfEntityBone(veh, bone)
    off = GetOffsetFromEntityGivenWorldCoords(veh, pos.x, pos.y, pos.z)

    if bone == GetEntityBoneIndexByName(veh, "bonnet") then
        off += vec3(0.0, 0.05, 0)
    else
        off += vec3(0.0, -0.2, 0.2)
    end

    UseParticleFxAssetNextCall("core")
    local leftPurge = StartParticleFxLoopedOnEntity("ent_sht_steam", veh, off.x - 0.5, off.y, off.z, 40.0, -20.0, 0.0, 0.3, false, false, false)
    UseParticleFxAssetNextCall("core")
    local rightPurge = StartParticleFxLoopedOnEntity("ent_sht_steam", veh, off.x + 0.5, off.y, off.z, 40.0, 20.0, 0.0, 0.3, false, false, false)
    purge[veh] = {left = leftPurge, right = rightPurge}
end)

local NitrousLoop = false
local function nitrousLoop()
    if not cache.vehicle or cache.seat ~= -1 then return end
    local sleep, vehicleState = 0, Entity(cache.vehicle)?.state
    NitrousLoop = true
    CreateThread(function()
        while cache.vehicle and NitrousLoop do
            if IsVehicleEngineOn(cache.vehicle) then
                sleep = 0
                if (vehicleState?.nitro or 0) > 0 and (vehicleState.nitroPurge or 0) < 100 then
                    if IsControlJustPressed(0, 36) and not nitroDelay then
                        vehicleState:set('nitroFlames', true, true)
                        nitrousUseLoop()
                    end
                    if IsControlJustReleased(0, 36) and cache.seat == -1 then
                        stopBoosting()
                    end
                end
                if (vehicleState?.nitroPurge or 0) > 0 then
                    if not nitrousActivated and IsControlJustPressed(0, 21) then
                        vehicleState:set('purgeNitro', true, true)
                        nitrousPurgeLoop()
                    end
                    if IsControlJustReleased(0, 21) and cache.seat == -1 then
                        stopPurging()
                    end
                end
            else
                sleep = 1000
            end
            Wait(sleep)
        end
    end)
end

lib.onCache('seat', function(seat)
    if seat ~= -1 then
        NitrousLoop = false
        return
    end
    SetTimeout(750, nitrousLoop)
end)

lib.onCache('vehicle', function(vehicle)
    if vehicle and (not config.turboRequired or IsToggleModOn(vehicle, 18)) then
        SetTimeout(750, function()
            nitrousLoop()
        end)
    else
        if nitrousActivated then
            nitrousActivated = false
            stopBoosting()
        end
        if PurgeLoop then
            PurgeLoop = false
            stopPurging()
        end
    end
end)

RegisterNetEvent('qbx_nitro:client:LoadNitrous', function()
    if not cache.vehicle or IsThisModelABike(cache.vehicle) then
        return exports.qbx_core:Notify(locale('notify.not_in_vehicle'), 'error')
    end

    if config.turboRequired and not IsToggleModOn(cache.vehicle, 18) then
        return exports.qbx_core:Notify(locale('notify.need_turbo'), 'error')
    end

    if cache.seat ~= -1 then
        return exports.qbx_core:Notify(locale('notify.must_be_driver'), 'error')
    end

    local vehicleState = Entity(cache.vehicle).state
    if vehicleState.nitro and vehicleState.nitro > 0 then
        return exports.qbx_core:Notify(locale('notify.already_have_nos'), 'error')
    end

    if lib.progressBar({
            duration = 2500,
            label = locale('progress.connecting'),
            useWhileDead = false,
            canCancel = true,
            disable = {
                combat = true
            }
        }) then -- if completed
        TriggerServerEvent('qbx_nitro:server:LoadNitrous', VehToNet(cache.vehicle))
    else    -- if canceled
        exports.qbx_core:Notify(locale('notify.canceled'), 'error')
    end
end)