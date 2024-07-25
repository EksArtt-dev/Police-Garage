local QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
    for _, location in pairs(Config.cikarma) do
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, 357)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Police Garage")
        EndTextCommandSetBlipName(blip)
    end
end)

local function OpenPoliceGarageMenu()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.job.name ~= "police" then
        QBCore.Functions.Notify("Garajı Açmaya Yetkin Yetmiyor!", "error")
        return
    end

    local menu = {
        {
            header = Lang:t('menu.garage_title'),
            isMenuHeader = true
        }
    }

    for _, vehicle in pairs(Config.araclar) do
        menu[#menu + 1] = {
            header = vehicle.label,
            txt = "Araç Seç",
            params = {
                event = 'policegarage:client:SpawnVehicle',
                args = {
                    model = vehicle.model
                }
            }
        }
    end

    menu[#menu + 1] = {
        header = Lang:t('menu.close'),
        txt = "",
        params = {
            event = 'qb-menu:client:closeMenu'
        }
    }

    exports['qb-menu']:openMenu(menu)
end


CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        for _, location in pairs(Config.cikarma) do
            local distance = #(playerCoords - location)
            if distance < 10.0 then
                DrawMarker(2, location.x, location.y, location.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 0, 255, 0, 255, false, false, 2, true, nil, nil, false)
                if distance < 1.5 then
                    QBCore.Functions.DrawText3D(location.x, location.y, location.z, "~g~E~w~ - Polis Garaj")
                    if IsControlJustReleased(0, 38) then
                        OpenPoliceGarageMenu()
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('policegarage:client:SpawnVehicle')
AddEventHandler('policegarage:client:SpawnVehicle', function(data)
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.job.name ~= "police" then
        QBCore.Functions.Notify("Aracı Çıkartmaya yetkin yetmiyor", "error")
        return
    end

    local vehicleModel = data.model
    local playerPed = PlayerPedId()
    local spawnPoint = GetAvailableSpawnPoint()
    if spawnPoint then
        QBCore.Functions.SpawnVehicle(vehicleModel, function(vehicle)
            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
            local plate = "POLICE"..tostring(math.random(1000, 9999))
            SetVehicleNumberPlateText(vehicle, plate)
            SetEntityAsMissionEntity(vehicle, true, true)
            TriggerEvent("vehiclekeys:client:SetOwner", plate)

            local vehicleProps = QBCore.Functions.GetVehicleProperties(vehicle)
            vehicleProps.plate = plate
            exports.oxmysql:insert('INSERT INTO player_vehicles (owner, plate, vehicle, stored) VALUES (?, ?, ?, ?)', {PlayerData.citizenid, plate, json.encode(vehicleProps), 0})
        end, spawnPoint, true)
    else
        QBCore.Functions.Notify("No available spawn points", "error")
    end
end)


function GetAvailableSpawnPoint()
    for _, spawnPoint in pairs(Config.aracspawn) do
        if IsSpawnPointClear(spawnPoint, 2.0) then
            return spawnPoint
        end
    end
    return nil
end

function IsSpawnPointClear(coords, radius)
    local vehicles = GetVehiclesInArea(coords, radius)
    return #vehicles == 0
end

function GetVehiclesInArea(coords, radius)
    local vehicles = {}
    local handle, vehicle = FindFirstVehicle()
    local success
    repeat
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehicleCoords)
        if distance < radius then
            table.insert(vehicles, vehicle)
        end
        success, vehicle = FindNextVehicle(handle)
    until not success
    EndFindVehicle(handle)
    return vehicles
end

local function StoreVehicleInGarage()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.job.name ~= "police" then
        QBCore.Functions.Notify("Aracı Garaja Koymaya yetkin yetmiyor", "error")
        return
    end

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle ~= 0 then
        local vehicleProps = QBCore.Functions.GetVehicleProperties(vehicle)
        QBCore.Functions.DeleteVehicle(vehicle)
        
        -- Veritabanınızı güncelleyin ve aracı stored olarak işaretleyin
        -- exports.oxmysql:execute('UPDATE owned_vehicles SET stored = 1 WHERE plate = ?', {vehicleProps.plate})
        
        QBCore.Functions.Notify("Araç Garaja Koyuldu", "success")
    else
        QBCore.Functions.Notify("Araçta Değilsin!", "error")
    end
end

CreateThread(function()
    -- Garaj Blipleri
    for _, location in pairs(Config.cikarma) do
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, 357)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Police Garage")
        EndTextCommandSetBlipName(blip)
    end

    -- Araç Depolama Markerı
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local storeLocation = Config.garaj
        local distance = #(playerCoords - storeLocation)

        if distance < 10.0 then
            DrawMarker(1, storeLocation.x, storeLocation.y, storeLocation.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 10.0, 10.0, Config.acik, Config.red, Config.green, Config.blue, Config.alpha, false, false, 2, true, nil, nil, false)
            if distance < 2.0 then
                QBCore.Functions.DrawText3D(storeLocation.x, storeLocation.y, storeLocation.z, "~g~E~w~ - Garaja Koy")
                if IsControlJustReleased(0, 38) then
                    StoreVehicleInGarage()
                end
            end
        end
    end
end)
