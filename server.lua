ESX = exports["es_extended"]:getSharedObject()

function SendWebhook(webhook, title, description, color)
    if webhook ~= '' then
        local embed = {
            {
                ["color"] = color or 16711680,
                ["title"] = title,
                ["description"] = description,
                ["footer"] = {
                    ["text"] = "Système de sociétés",
                },
                ["timestamp"] = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }
        }
        
        PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
    end
end

ESX.RegisterServerCallback('buy_sell_jobs:getMoney', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        cb(xPlayer.getMoney())
    else
        cb(0)
    end
end)

ESX.RegisterServerCallback('buy_sell_jobs:getBankMoney', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        cb(xPlayer.getAccount('bank').money)
    else
        cb(0)
    end
end)

ESX.RegisterServerCallback('buy_sell_jobs:getJobList', function(source, cb)
    MySQL.query('SELECT * FROM jobs WHERE 1', {}, function(result)
        cb(result)
    end)
end)

RegisterServerEvent('buy_sell_jobs:sellSociety')
AddEventHandler('buy_sell_jobs:sellSociety', function(jobName, sellPrice)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    local result = MySQL.query.await('SELECT * FROM jobs WHERE name = ? AND owner_identifier = ?', {jobName, xPlayer.identifier})
    
    if result and #result > 0 then
        local jobData = result[1]
        
        local commission = math.floor(sellPrice * Config.Percentage)
        
        MySQL.update('UPDATE addon_account_data SET money = money + ? WHERE account_name = ?', {commission, Config.Society})
        
        MySQL.update('UPDATE jobs SET for_sale = 0, sale_price = ?, owner_identifier = NULL, owner_firstname = NULL, owner_lastname = NULL WHERE name = ?', 
            {sellPrice, jobName})
        
        xPlayer.setJob('unemployed', 0)
        
        TriggerClientEvent('buy_sell_jobs:notify', source, "Mise en vente", "Votre société a été mise en vente pour " .. sellPrice .. "$\nCommission de l'agence: " .. commission .. "$", "success")
        
        TriggerClientEvent('buy_sell_jobs:refreshJobList', -1)
        
        SendWebhook(Config.WebhookSocietyForSale, "Société mise en vente", 
            "**Société:** " .. Config.Jobs.jobs[jobName].label .. "\n" ..
            "**Vendeur:** " .. xPlayer.getName() .. "\n" ..
            "**Prix demandé:** " .. sellPrice .. "$\n" ..
            "**Commission agence:** " .. commission .. "$", 15105570)
    else
        TriggerClientEvent('buy_sell_jobs:notify', source, "Vente impossible", "Cette société ne vous appartient pas.", "error")
    end
end)

RegisterServerEvent('buy_sell_jobs:buySociety')
AddEventHandler('buy_sell_jobs:buySociety', function(jobName, price)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
  
    local result = MySQL.query.await('SELECT * FROM jobs WHERE name = ?', {jobName})
    
    if result and #result > 0 then
        local jobData = result[1]
        
        local isForSale = (jobData.for_sale == false or jobData.for_sale == 0)
        local salePrice = tonumber(jobData.sale_price) or 0
        
        if isForSale and salePrice > 0 then
            if xPlayer.getAccount('bank').money >= salePrice then
                
                xPlayer.removeAccountMoney('bank', salePrice)
                
                local govPart = math.floor(salePrice * Config.Percentage)
                
                if jobData.owner_identifier and jobData.owner_identifier ~= 'null' and jobData.owner_identifier ~= '' and jobData.owner_identifier ~= nil then
                    local oldOwner = ESX.GetPlayerFromIdentifier(jobData.owner_identifier)
                    local ownerPart = salePrice - govPart
                    
                    print("Ancien propriétaire : " .. tostring(jobData.owner_identifier))
                    print("Part propriétaire : " .. ownerPart)
                    
                    if oldOwner then
                        oldOwner.addAccountMoney('bank', ownerPart)
                        TriggerClientEvent('buy_sell_jobs:notify', oldOwner.source, "Vente de société", "Votre société a été vendue pour " .. ownerPart .. "$ (versés sur votre compte bancaire)", "success")
                    else
                        MySQL.update('UPDATE users SET bank = bank + ? WHERE identifier = ?', {ownerPart, jobData.owner_identifier})
                    end
                else
                    govPart = salePrice
                end
                
                MySQL.update('UPDATE addon_account_data SET money = money + ? WHERE account_name = ?', {govPart, Config.Society})
                
                local playerIdentifier = xPlayer.identifier
                local playerFirstName = xPlayer.get('firstName') or "Inconnu"
                local playerLastName = xPlayer.get('lastName') or "Inconnu"
                
                MySQL.update('UPDATE jobs SET for_sale = 1, owner_identifier = ?, owner_firstname = ?, owner_lastname = ? WHERE name = ?', 
                    {playerIdentifier, playerFirstName, playerLastName, jobName}, function(rowsChanged)
                                        
                    if rowsChanged > 0 then
                        
                        local gradeMax = Config.Jobs.jobs[jobName] and Config.Jobs.jobs[jobName].grade or 0
                        xPlayer.setJob(jobName, gradeMax)
                        
                        TriggerClientEvent('buy_sell_jobs:notify', source, "Achat réussi", "Vous avez acheté la société pour " .. salePrice .. "$ (prélevés sur votre compte bancaire)", "success")
                        
                        TriggerClientEvent('buy_sell_jobs:refreshJobList', -1)
                        
                        SendWebhook(Config.WebhookSocietyBought, "Achat de société", 
                            "**Société:** " .. (Config.Jobs.jobs[jobName] and Config.Jobs.jobs[jobName].label or jobName) .. "\n" ..
                            "**Acheteur:** " .. xPlayer.getName() .. "\n" ..
                            "**Prix:** " .. salePrice .. "$\n" ..
                            "**Part agence immobilière:** " .. govPart .. "$", 5763719)
                    else
                        xPlayer.addAccountMoney('bank', salePrice)
                        TriggerClientEvent('buy_sell_jobs:notify', source, "Achat impossible", "Une erreur est survenue lors de l'achat. Vous avez été remboursé.", "error")
                    end
                end)
            else
                TriggerClientEvent('buy_sell_jobs:notify', source, "Achat impossible", "Vous n'avez pas assez d'argent en banque pour acheter cette société.", "error")
            end
        else
            TriggerClientEvent('buy_sell_jobs:notify', source, "Achat impossible", "Cette société n'est pas à vendre ou n'a pas de prix valide.", "error")
        end
    else
        TriggerClientEvent('buy_sell_jobs:notify', source, "Achat impossible", "Cette société n'existe pas.", "error")
    end
end)
