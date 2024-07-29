local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('qb-policegarage:server:GetVehicles', function(source, cb)
    cb(Config.Vehicles)
end)
