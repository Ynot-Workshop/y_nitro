lib.versionCheck('Qbox-project/qbx_nitro')

exports.qbx_core:CreateUseableItem("nitrous", function(source)
    TriggerClientEvent('qbx_nitro:client:LoadNitrous', source)
end)

RegisterNetEvent('qbx_nitro:server:LoadNitrous', function(netId)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return end

    if exports.ox_inventory:RemoveItem(source, 'nitrous', 1) then
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        Entity(vehicle).state:set("nitro", 100, true)
    end
end)