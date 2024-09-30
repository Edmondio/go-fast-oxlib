local isOnMission = false
local missionVehicle = nil
local deliveryBlip = nil

local language = Config.Language
local T = require("locales." .. language)

print(T.welcome)

function CreateGoFastPed()
    local model = Config.PedModel
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    local pedCoords = Config.PedLocation
    local ped = CreatePed(4, model, pedCoords.x, pedCoords.y, pedCoords.z - 1, pedCoords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'start_gofast',
            icon = 'fas fa-car',
            label = T.start_gofast,
            distance = 1.5,
            onSelect = function()
                ESX.TriggerServerCallback('gofast:getMinPolice', function(minPolice) 
                    if minPolice >= Config.MinPolice then
                        checkDrugsAndShowMenu()
                    else
                        lib.notify({
                            title = T.unknown_title,
                            description = T.come_back_later,
                            type = 'error',
                            duration = 5000,
                            position = Config.OxNotifyPosition
                        })
                    end
                end)
            end
        }
    })
end

local function CompleteGoFast(drugType, amount)
    TriggerServerEvent('gofast:completeMission', drugType.name, amount)
    isOnMission = false
    missionVehicle = nil
end

function StartGoFastTimer(drugType, amount)
    lib.notify({
        title = T.gofast_title,
        description = T.move_quickly,
        type = 'info',
        duration = 5000,
        position = Config.OxNotifyPosition
    })

    local waitTime = math.random(Config.TimerBeforeAlert.min, Config.TimerBeforeAlert.max)
    Wait(waitTime * 1000)  -- Convertir en millisecondes

    TriggerServerEvent('gofast:alertPolice')
    lib.notify({
        title = T.gofast_title,
        description = T.police_alerted,
        type = 'error',
        duration = 5000,
        position = Config.OxNotifyPosition
    })

    local policeAlertDuration = math.random(Config.PoliceAlertDuration.min, Config.PoliceAlertDuration.max)
    
    CreateThread(function()
        local endTime = GetGameTimer() + (policeAlertDuration * 1000)
        while GetGameTimer() < endTime do
            Wait(Config.PoliceUpdateInterval * 1000)
            local playerCoords = GetEntityCoords(PlayerPedId())
            TriggerServerEvent('gofast:updatePoliceBlip', playerCoords)
        end

        TriggerServerEvent('gofast:signalLost')
        lib.notify({
            title = T.gofast_title,
            description = T.signal_jammed,
            type = 'success',
            duration = 5000,
            position = Config.OxNotifyPosition
        })

        local deliveryPoint = Config.DeliveryPoints[math.random(#Config.DeliveryPoints)]
        local deliveryBlip = AddBlipForCoord(deliveryPoint.x, deliveryPoint.y, deliveryPoint.z)
        SetBlipRoute(deliveryBlip, true)

        CreateThread(function()
            while true do
                Wait(1000)
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - vector3(deliveryPoint.x, deliveryPoint.y, deliveryPoint.z))
                if distance < 5.0 then
                    CompleteGoFast(drugType, amount)
                    RemoveBlip(deliveryBlip)
                    break
                end
            end
        end)
    end)
end



function StartGoFastMission(drugType, amount, plate)
    local model = GetHashKey(Config.VehicleModels[math.random(#Config.VehicleModels)])
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    local vehicleCoords = Config.VehicleSpawnPoint
    missionVehicle = CreateVehicle(model, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleCoords.w, true, false)
    SetEntityAsMissionEntity(missionVehicle, true, true)
    SetVehicleNumberPlateText(missionVehicle, plate)
    SetNewWaypoint(vehicleCoords.x, vehicleCoords.y)
    lib.notify({
        title = T.gofast_title,
        description = T.vehicle_ready,
        type = 'info',
        duration = 5000,
        position = Config.OxNotifyPosition
    })

    CreateThread(function()
        while true do
            Wait(1000)
            if IsPedInVehicle(PlayerPedId(), missionVehicle, false) then
                StartGoFastTimer(drugType, amount)
                break
            end
        end
    end)
end

function showDrugMenu(availableDrugs)
    if #availableDrugs == 0 then
        lib.notify({
            title = T.gofast_title,
            description = T.no_drugs_available,
            type = 'error',
            duration = 5000,
            position = Config.OxNotifyPosition
        })
        return
    end

    local options = {}
    for _, drug in ipairs(availableDrugs) do
        table.insert(options, {
            title = drug.label or T.unknown_drug,
            description = string.format('%s, %s, %s', 
                string.format(T.reward_format, drug.rewardPerUnit),
                string.format(T.max_amount_format, drug.maxAmount),
                string.format(T.available_amount_format, drug.playerAmount)),
            icon = 'cannabis',
            onSelect = function()
                local maxAmount = math.min(drug.maxAmount, drug.playerAmount)
                local input = lib.inputDialog(string.format('%s %s', T.quantity_label, drug.label), {
                    {
                        type = 'number', 
                        label = T.quantity_label, 
                        description = string.format(T.max_quantity_description, maxAmount),
                        required = true, 
                        min = 1, 
                        max = maxAmount
                    }
                })
                if input and input[1] then
                    local amount = math.floor(input[1])
                    if amount > 0 and amount <= maxAmount then
                        TriggerServerEvent('gofast:startMission', drug.name, amount)
                    else
                        lib.notify({
                            title = T.gofast_title,
                            description = T.invalid_quantity,
                            type = 'error',
                            duration = 5000,
                            position = Config.OxNotifyPosition
                        })
                    end
                end
            end
        })
    end

    lib.showContext('gofast_drug_selection')
end


function registerDrugMenu(options)
    lib.registerContext({
        id = 'gofast_drug_selection',
        title = T.drug_selection_title,
        options = options
    })
end

function checkDrugsAndShowMenu()
    if not isOnMission then
        ESX.TriggerServerCallback('gofast:getDrugList', function(availableDrugs)            
            local options = {}
            for _, drug in ipairs(availableDrugs) do
                table.insert(options, {
                    title = drug.label or T.unknown_drug,
                    description = string.format(T.reward_min_max_available_format, 
                        drug.rewardPerUnit, drug.minAmount, drug.maxAmount, drug.playerAmount),
                    icon = 'cannabis',
                    onSelect = function()
                        local maxAmount = math.min(drug.maxAmount, drug.playerAmount)
                        local input = lib.inputDialog(string.format('%s %s', T.quantity_label, drug.label), {
                            {
                                type = 'number', 
                                label = T.quantity_label, 
                                description = string.format(T.min_max_quantity_description, drug.minAmount, maxAmount),
                                required = true, 
                                min = drug.minAmount, 
                                max = maxAmount
                            }
                        })
                        if input and input[1] then
                            local amount = math.floor(input[1])
                            if amount >= drug.minAmount and amount <= maxAmount then
                                TriggerServerEvent('gofast:startMission', drug.name, amount)
                            else
                                lib.notify({
                                    title = T.gofast_title,
                                    description = string.format(T.invalid_quantity_range, drug.minAmount, maxAmount),
                                    type = 'error',
                                    duration = 5000,
                                    position = Config.OxNotifyPosition
                                })
                            end
                        end
                    end
                })
            end
            
            registerDrugMenu(options)
            showDrugMenu(availableDrugs)
        end)
    else
        lib.notify({
            title = T.gofast_title,
            description = T.mission_in_progress,
            type = 'error',
            duration = 5000,
            position = Config.OxNotifyPosition
        })
    end
end


RegisterNetEvent('gofast:startMission')
AddEventHandler('gofast:startMission', function(drugType, amount, plate)
    if not isOnMission then
        isOnMission = true
        StartGoFastMission(drugType, amount, plate)
    end
end)

RegisterNetEvent('gofast:signalLost')
AddEventHandler('gofast:signalLost', function()
    lib.notify({
        title = T.gofast_title,
        description = T.police_lost_trace,
        type = 'success'
    })
end)



RegisterNetEvent('gofast:showPoliceBlip')
AddEventHandler('gofast:showPoliceBlip', function(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 1)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(T.gofast_suspect)
    EndTextCommandSetBlipName(blip)
    PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)

    Wait(Config.PoliceBlipDuration * 1000)
    RemoveBlip(blip)
end)


-- Initialisation
CreateThread(function()
    CreateGoFastPed()
end)