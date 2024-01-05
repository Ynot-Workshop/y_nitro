lib.versionCheck('Qbox-project/qbx_nitro')

exports.qbx_core:CreateUseableItem("nitrous", function(source)
    TriggerClientEvent('qbx_nitro:client:LoadNitrous', source)
end)

RegisterNetEvent('qbx_nitro:server:LoadNitrous', function(netId)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return end

    if exports.ox_inventory:RemoveItem(source, 'nitrous', 1) then
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        Entity(vehicle).state.nitro = 100
    end
end)

RegisterNetEvent('qbx_nitro:server:SyncFlames', function(netId)
    TriggerClientEvent('qbx_nitro:client:SyncFlames', -1, netId, source)
end)

RegisterNetEvent('qbx_nitro:server:UnloadNitrous', function(Plate)
    TriggerClientEvent('qbx_nitro:client:UnloadNitrous', -1, Plate)
end)

RegisterNetEvent('qbx_nitro:server:UpdateNitroLevel', function(Plate, level)
    TriggerClientEvent('qbx_nitro:client:UpdateNitroLevel', -1, Plate, level)
end)

RegisterNetEvent('qbx_nitro:server:StopSync', function(plate)
    TriggerClientEvent('qbx_nitro:client:StopSync', -1, plate)
end)
