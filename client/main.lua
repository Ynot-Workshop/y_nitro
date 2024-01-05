local config = require 'config.client'
local nitrousActivated = false
local nitrousBoost = config.nitrousBoost
local Fxs = {}
local nitroDelay = false

lib.locale()

local function trim(value)
    if not value then return nil end
    return (string.gsub(value, '^%s*(.-)%s*$', '%1'))
end

RegisterNetEvent('qbx_nitro:client:LoadNitrous', function()
    if nitrousActivated then
        return exports.qbx_core:Notify(locale('notify.already_have_nos'), 'error')
    end
    if not cache.vehicle or IsThisModelABike(cache.vehicle) then
        return exports.qbx_core:Notify(locale('notify.not_in_vehicle'), 'error')
    end

    if config.turboRequired and not IsToggleModOn(cache.vehicle, 18) then
        return exports.qbx_core:Notify(locale('notify.need_turbo'), 'error')
    end
    
    if cache.seat ~= -1 then
        return exports.qbx_core:Notify(locale('notify.must_be_driver'), "error")
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

local function nitrousUseLoop()
    nitroDelay = true
    SetTimeout(3000, function()
        nitroDelay = false
    end)
    CreateThread(function()
        local Plate = trim(GetVehicleNumberPlateText(cache.vehicle))
        while nitrousActivated and cache.vehicle do
            if Entity(cache.vehicle).state.nitro - 0.25 >= 0 then
                SetVehicleEnginePowerMultiplier(cache.vehicle, nitrousBoost)
                SetVehicleEngineTorqueMultiplier(cache.vehicle, nitrousBoost)
                SetEntityMaxSpeed(cache.vehicle, 999.0)
                Entity(cache.vehicle).state:set("nitro", Entity(cache.vehicle).state.nitro - 0.25, true)
            else
                SetVehicleBoostActive(cache.vehicle, 0)
                SetVehicleEnginePowerMultiplier(cache.vehicle, 1.0)
                SetVehicleEngineTorqueMultiplier(cache.vehicle, 1.0)
                for index, _ in pairs(Fxs) do
                    StopParticleFxLooped(Fxs[index], 1)
                    TriggerServerEvent('qbx_nitro:server:StopSync', Plate)
                    Fxs[index] = nil
                end
                StopScreenEffect("RaceTurbo")
                TriggerServerEvent('qbx_nitro:server:UnloadNitrous', Plate)
                nitrousActivated = false
            end
            if IsControlJustReleased(0, 36) and cache.seat == -1 then
                SetVehicleBoostActive(cache.vehicle, 0)
                SetVehicleEnginePowerMultiplier(cache.vehicle, 1.0)
                SetVehicleEngineTorqueMultiplier(cache.vehicle, 1.0)
                for index, _ in pairs(Fxs) do
                    StopParticleFxLooped(Fxs[index], 1)
                    TriggerServerEvent('qbx_nitro:server:StopSync', Plate)
                    Fxs[index] = nil
                end
                StopScreenEffect("RaceTurbo")
                nitrousActivated = false
            end
            Wait(0)
        end
    end)
end

local function nitrousLoop()
    local sleep = 0
    CreateThread(function()
        while cache.vehicle do
            if (Entity(cache.vehicle)?.state?.nitro or 0) > 0 then
                sleep = 0
                if IsControlJustPressed(0, 36) and cache.seat == -1 and not nitroDelay then
                    TriggerServerEvent('qbx_nitro:server:SyncFlames', VehToNet(cache.vehicle))
                    nitrousActivated = true
                    loadEffects()
                    nitrousUseLoop()
                end
            else
                sleep = 1000
            end
            Wait(sleep)
        end
    end)
end

lib.onCache('vehicle', function(vehicle)
    if vehicle and (not config.turboRequired or IsToggleModOn(vehicle, 18)) then
        SetTimeout(750, function()
            nitrousLoop()
        end)
    end
end)

p_flame_location = {
    "exhaust",
    "exhaust_2",
    "exhaust_3",
    "exhaust_4",
    "exhaust_5",
    "exhaust_6",
    "exhaust_7",
    "exhaust_8",
    "exhaust_9",
    "exhaust_10",
    "exhaust_11",
    "exhaust_12",
    "exhaust_13",
    "exhaust_14",
    "exhaust_15",
    "exhaust_16",
}

ParticleDict = "veh_xs_vehicle_mods"
ParticleFx = "veh_nitrous"
ParticleSize = 1.4

function loadEffects()
    CreateThread(function()
        while nitrousActivated do
            local veh = GetVehiclePedIsIn(PlayerPedId())
            if veh ~= 0 then
                SetVehicleBoostActive(veh, 1)
                StartScreenEffect("RaceTurbo", 0.0, 0)

                for _, bones in pairs(p_flame_location) do
                    if GetEntityBoneIndexByName(veh, bones) ~= -1 then
                        if Fxs[bones] == nil then
                            RequestNamedPtfxAsset(ParticleDict)
                            while not HasNamedPtfxAssetLoaded(ParticleDict) do
                                Wait(0)
                            end
                            SetPtfxAssetNextCall(ParticleDict)
                            UseParticleFxAssetNextCall(ParticleDict)
                            Fxs[bones] = StartParticleFxLoopedOnEntityBone(ParticleFx, veh, 0.0, -0.02, 0.0, 180, 0.0,
                                0.0, GetEntityBoneIndexByName(veh, bones), ParticleSize, 0.0, 0.0, 0.0)
                        end
                    end
                end
            end
            Wait(0)
        end
    end)
end

local NOSPFX = {}

RegisterNetEvent('qbx_nitro:client:SyncFlames', function(netid, nosid)
    local veh = NetToVeh(netid)
    if veh ~= 0 then
        local myid = GetPlayerServerId(PlayerId())
        if NOSPFX[trim(GetVehicleNumberPlateText(veh))] == nil then
            NOSPFX[trim(GetVehicleNumberPlateText(veh))] = {}
        end
        if myid ~= nosid then
            for _, bones in pairs(p_flame_location) do
                if NOSPFX[trim(GetVehicleNumberPlateText(veh))][bones] == nil then
                    NOSPFX[trim(GetVehicleNumberPlateText(veh))][bones] = {}
                end
                if GetEntityBoneIndexByName(veh, bones) ~= -1 then
                    if NOSPFX[trim(GetVehicleNumberPlateText(veh))][bones].pfx == nil then
                        RequestNamedPtfxAsset(ParticleDict)
                        while not HasNamedPtfxAssetLoaded(ParticleDict) do
                            Wait(0)
                        end
                        SetPtfxAssetNextCall(ParticleDict)
                        UseParticleFxAssetNextCall(ParticleDict)
                        NOSPFX[trim(GetVehicleNumberPlateText(veh))][bones].pfx = StartParticleFxLoopedOnEntityBone(
                            ParticleFx, veh, 0.0, -0.05, 0.0, 0.0, 0.0, 0.0, GetEntityBoneIndexByName(veh, bones),
                            ParticleSize, 0.0, 0.0, 0.0)
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('qbx_nitro:client:StopSync', function(plate)
    if NOSPFX[plate] ~= nil then
        for k, v in pairs(NOSPFX[plate]) do
            StopParticleFxLooped(v.pfx, 1)
            NOSPFX[plate][k].pfx = nil
        end
    end
end)
