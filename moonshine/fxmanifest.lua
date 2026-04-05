fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'Moonshine System'
description 'A custom moonshine brewing system for FiveM servers.'
author 'Mich102'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/main.lua',
    'client/nui.lua',
    'client/effects.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua'
}

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js'
}

ui_page 'nui/index.html'