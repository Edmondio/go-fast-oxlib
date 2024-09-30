fx_version 'cerulean'
game 'gta5'

author 'Edmondio'
description 'Système de Go-Fast pour FiveM'
version '1.0.0'
discord 'https://discord.gg/yRfwHxynpg'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
    'locales/*.lua',
    '@es_extended/imports.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

dependencies {
    'ox_lib',
    'ox_inventory'
}

lua54 'yes'