lib.versionCheck('Qbox-project/qbx_nitro')

exports.qbx_core:CreateUseableItem('nitrous', function(source)
    local netId = lib.callback.await("qbx_nitro:client:LoadNitrous", source)
    if not netId then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if exports.ox_inventory:RemoveItem(source, 'nitrous', 1) then
        Entity(vehicle).state:set('nitro', 100, true)
    end
end)