fx_version 'cerulean'
game 'gta5'

author 'GamesFiveM'
description 'Sistema de autenticación completo para GamesFiveM'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

client_scripts {
    'client/client.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/logo.png'
}

dependencies {
    'es_extended',
    'oxmysql',
    'esx_multicharacter',
    'esx_identity'
}
