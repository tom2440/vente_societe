fx_version 'cerulean'
game 'gta5'

name 'vente_societe'
description 'Système d\'achat et de vente de sociétés pour ESX Legacy'
author 'tom2440'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
    'ox_target'
}