local config = require 'config.client'
local nitrousActivated = false
local nitrousBoost = config.nitrousBoost
local nitroDelay = false

local function trim(value)
    if not value then return nil end
    return (string.gsub(value, '^%s*(.-)%s*$', '%1'))
end

-- sometimes it's reversed i think?
local p_flame_location = {
    exhaust = 180,
    exhaust_2 = 180,
    exhaust_3 = 180,
    exhaust_4 = 180,
    exhaust_5 = 180,
    exhaust_6 = 180,
    exhaust_7 = 180,
    exhaust_8 = 180,
    exhaust_9 = 180,
    exhaust_10 = 180,
    exhaust_11 = 180,
    exhaust_12 = 180,
    exhaust_13 = 180,
    exhaust_14 = 180,
    exhaust_15 = 180,
    exhaust_16 = 180,
}

local ParticleDict = "veh_xs_vehicle_mods"
local ParticleFx = "veh_nitrous"
local ParticleSize = 1.4

local NOSPFX = {}
local function syncFlames(vehicle)
    if vehicle == 0 then return end

    local trimmedPlate = trim(GetVehicleNumberPlateText(vehicle))
    if trimmedPlate == nil then return end
    if NOSPFX[trimmedPlate] == nil then
        NOSPFX[trimmedPlate] = {}
    end
    for bone, rotation in pairs(p_flame_location) do
        if NOSPFX[trimmedPlate][bone] == nil then
            NOSPFX[trimmedPlate][bone] = {}
        end
        if GetEntityBoneIndexByName(vehicle, bone) ~= -1 then
            if NOSPFX[trimmedPlate][bone].pfx == nil then
                RequestNamedPtfxAsset(ParticleDict)
                while not HasNamedPtfxAssetLoaded(ParticleDict) do
                    Wait(0)
                end
                SetPtfxAssetNextCall(ParticleDict)
                UseParticleFxAssetNextCall(ParticleDict)
                NOSPFX[trimmedPlate][bone].pfx = StartParticleFxLoopedOnEntityBone(
                    ParticleFx, vehicle, 0.0, -0.05, 0.0, rotation, 0.0, 0.0, GetEntityBoneIndexByName(vehicle, bone),
                    ParticleSize, 0.0, 0.0, 0.0)
            end
        end
    end
end

local function stopSync(plate)
    if not NOSPFX[plate] then return end
    for k, v in pairs(NOSPFX[plate]) do
        StopParticleFxLooped(v.pfx, true)
        NOSPFX[plate][k].pfx = nil
    end
end

local function setMultipliers(vehicle, disable)
    local multiplier = disable and 1.0 or nitrousBoost
    SetVehicleEnginePowerMultiplier(vehicle, multiplier)
    SetVehicleEngineTorqueMultiplier(vehicle, multiplier)
end

local function stopBoosting(vehicle)
    SetVehicleBoostActive(vehicle, false)
    setMultipliers(vehicle, true)
    Entity(vehicle).state:set("nitroFlames", false, true)
    StopScreenEffect("RaceTurbo")
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
                StartScreenEffect("RaceTurbo", 0, 0)
                vehicleState:set("nitro", vehicleState.nitro - 0.25, true)
            else
                stopBoosting(cache.vehicle)
                vehicleState:set("nitro", 0, true)
            end
            if IsControlJustReleased(0, 36) and cache.seat == -1 then
                stopBoosting(cache.vehicle)
            end
            Wait(0)
        end
    end)
end

qbx.entityStateHandler('nitroFlames', function(veh, netId, value)
    if value then
        syncFlames(veh)
    else
        local plate = trim(GetVehicleNumberPlateText(veh))
        stopSync(plate)
    end
end)

local NitrousLoop = false
local function nitrousLoop()
    if not cache.vehicle or cache.seat ~= -1 then return end
    local sleep, vehicleState = 0, Entity(cache.vehicle)?.state
    NitrousLoop = true
    CreateThread(function()
        while cache.vehicle and NitrousLoop do
            if IsVehicleEngineOn(cache.vehicle) and (vehicleState?.nitro or 0) > 0 then
                sleep = 0
                if IsControlJustPressed(0, 36) and not nitroDelay then
                    vehicleState:set("nitroFlames", true, true)
                    nitrousUseLoop()
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
            stopBoosting(cache.vehicle)
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
        return exports.qbx_core:Notify(locale('notify.must_be_driver'), "error")
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
        TriggerServerEvent('qbx_nitro:server:LoadNitrous', NetworkGetNetworkIdFromEntity(cache.vehicle))
    else        -- if canceled
        exports.qbx_core:Notify(locale('notify.canceled'), 'error')
    end
end)