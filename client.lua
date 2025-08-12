ESX = exports["es_extended"]:getSharedObject()

local jobList = {}

Citizen.CreateThread(function()
    local blip = AddBlipForCoord(Config.AgenceSocieter.Blip.Pos.x, Config.AgenceSocieter.Blip.Pos.y, Config.AgenceSocieter.Blip.Pos.z)
    SetBlipSprite(blip, Config.AgenceSocieter.Blip.Sprite)
    SetBlipDisplay(blip, Config.AgenceSocieter.Blip.Display)
    SetBlipScale(blip, Config.AgenceSocieter.Blip.Scale)
    SetBlipColour(blip, Config.AgenceSocieter.Blip.Colour)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Agence des Sociétés")
    EndTextCommandSetBlipName(blip)

    RequestModel(GetHashKey(Config.AgentPed))
    while not HasModelLoaded(GetHashKey(Config.AgentPed)) do
        Wait(1)
    end
    
    local agent = CreatePed(4, GetHashKey(Config.AgentPed), Config.AgentCoords.x, Config.AgentCoords.y, Config.AgentCoords.z - 1, Config.AgentCoords.w, false, true)
    FreezeEntityPosition(agent, true)
    SetEntityInvincible(agent, true)
    SetBlockingOfNonTemporaryEvents(agent, true)
    
    if Config.UseTarget then
        exports.ox_target:addLocalEntity(agent, {
            {
                name = 'society_agent',
                icon = 'fas fa-building',
                label = 'Parler à l\'agent',
                onSelect = function()
                    OpenSocietyMenu()
                end
            }
        })
    end
end)

Citizen.CreateThread(function()
    if not Config.UseTarget then
        while true do
            local wait = 1000
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - vector3(Config.AgentCoords.x, Config.AgentCoords.y, Config.AgentCoords.z))
            
            if distance < 3.0 then
                wait = 0
                ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour parler à l\'agent')
                
                if IsControlJustPressed(0, 38) then -- Touche E
                    OpenSocietyMenu()
                end
            end
            
            Citizen.Wait(wait)
        end
    end
end)

function GetJobList()
    ESX.TriggerServerCallback('buy_sell_jobs:getJobList', function(result)
        jobList = {}
        for i = 1, #result do
            if Config.Jobs.jobs[result[i].name] then
                jobList[result[i].name] = result[i]
            end
        end
    end)
end

Citizen.CreateThread(function()
    GetJobList()
end)

function OpenSocietyMenu()
    GetJobList()
    Wait(100) 
    
    lib.registerContext({
        id = 'society_menu',
        title = 'Agence des Sociétés',
        options = {
            {
                title = "Acheter une société",
                description = "Voir les sociétés disponibles à l'achat",
                icon = 'shopping-cart',
                onSelect = function()
                    OpenBuySocietyMenu()
                end
            },
            {
                title = "Vendre ma société",
                description = "Mettre votre société en vente",
                icon = 'dollar-sign',
                onSelect = function()
                    OpenSellSocietyMenu()
                end
            }
        }
    })
    
    lib.showContext('society_menu')
end

function OpenBuySocietyMenu()
    ESX.TriggerServerCallback('buy_sell_jobs:getJobList', function(result)
        jobList = {}
        for i = 1, #result do
            if Config.Jobs.jobs[result[i].name] then
                jobList[result[i].name] = result[i]
            end
        end
        
        local options = {}
        local jobsFound = false
        
        for jobName, jobData in pairs(jobList) do
            if (jobData.for_sale == false or jobData.for_sale == 0) and jobData.sale_price ~= nil then
                jobsFound = true
                
                local description = Config.Jobs.jobs[jobName].description or "Aucune description disponible"
                
                table.insert(options, {
                    title = Config.Jobs.jobs[jobName].label,
                    description = description .. "\nPrix: " .. jobData.sale_price .. "$",
                    icon = 'building',
                    image = Config.SocietyImages[jobName] or "https://i.imgur.com/default.png",
                    onSelect = function()
                        ConfirmBuySociety(jobName, jobData.sale_price)
                    end
                })
            end
        end
        
        if not jobsFound then
            table.insert(options, {
                title = "Aucune société disponible",
                description = "Il n'y a aucune société à vendre actuellement.",
                icon = 'times-circle',
                onSelect = function()
                    OpenSocietyMenu()
                end
            })
        end
        
        lib.registerContext({
            id = 'buy_society_menu',
            title = 'Sociétés à vendre',
            menu = 'society_menu',
            options = options
        })
        
        lib.showContext('buy_society_menu')
    end)
end

function ConfirmBuySociety(jobName, price)
    ESX.TriggerServerCallback('buy_sell_jobs:getBankMoney', function(money)
        if money >= price then
            local alert = lib.alertDialog({
                header = 'Confirmation d\'achat',
                content = 'Êtes-vous sûr de vouloir acheter cette société pour ' .. price .. '$ ? Le montant sera prélevé sur votre compte bancaire.',
                centered = true,
                cancel = true
            })
            
            if alert == 'confirm' then
                TriggerServerEvent('buy_sell_jobs:buySociety', jobName, price)
            end
        else
            lib.notify({
                title = 'Achat impossible',
                description = 'Vous n\'avez pas assez d\'argent en banque pour acheter cette société.',
                type = 'error'
            })
        end
    end)
end

function OpenSellSocietyMenu()
    ESX.TriggerServerCallback('buy_sell_jobs:getJobList', function(result)
        jobList = {}
        for i = 1, #result do
            if Config.Jobs.jobs[result[i].name] then
                jobList[result[i].name] = result[i]
            end
        end
        
        local options = {}
        local player = ESX.GetPlayerData()
        local found = false
        
        for jobName, jobData in pairs(jobList) do
            if jobData.owner_identifier == player.identifier then
                found = true
                
                local description = Config.Jobs.jobs[jobName].description or "Aucune description disponible"
                
                table.insert(options, {
                    title = Config.Jobs.jobs[jobName].label,
                    description = description .. "\nPrix d'achat: " .. jobData.sale_price .. "$",
                    icon = 'dollar-sign',
                    image = Config.SocietyImages[jobName] or "https://i.imgur.com/default.png",
                    onSelect = function()
                        ConfirmSellSociety(jobName, jobData.sale_price)
                    end
                })
            end
        end
        
        if not found then
            table.insert(options, {
                title = "Aucune société à vendre",
                description = "Vous ne possédez aucune société que vous pouvez vendre.",
                icon = 'times-circle',
                onSelect = function()
                    OpenSocietyMenu()
                end
            })
        end
        
        lib.registerContext({
            id = 'sell_society_menu',
            title = 'Vendre votre société',
            menu = 'society_menu',
            options = options
        })
        
        lib.showContext('sell_society_menu')
    end)
end

function ConfirmSellSociety(jobName, buyPrice)
    local input = lib.inputDialog('Vendre votre société', {
        {type = 'number', label = 'Prix de vente', description = 'Prix auquel vous avez acheté: ' .. buyPrice .. '$', icon = 'dollar-sign', min = 1, required = true}
    })
    
    if input then
        local sellPrice = input[1]
        
        local alert = lib.alertDialog({
            header = 'Confirmation de vente',
            content = 'Êtes-vous sûr de vouloir mettre en vente votre société pour ' .. sellPrice .. '$ ?',
            centered = true,
            cancel = true
        })
        
        if alert == 'confirm' then
            TriggerServerEvent('buy_sell_jobs:sellSociety', jobName, sellPrice)
        end
    end
end

RegisterNetEvent('buy_sell_jobs:refreshJobList')
AddEventHandler('buy_sell_jobs:refreshJobList', function()
    GetJobList()
end)

RegisterNetEvent('buy_sell_jobs:notify')
AddEventHandler('buy_sell_jobs:notify', function(title, message, type)
    lib.notify({
        title = title,
        description = message,
        type = type
    })
end)