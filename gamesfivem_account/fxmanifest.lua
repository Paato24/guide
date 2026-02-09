fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'GamesFiveM'
description 'NUI de autenticacion y cuenta para ESX Legacy'
version '1.0.0'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/styles.css',
  'html/app.js',
  'html/img/logo.svg'
}

shared_scripts {
  'config.lua'
}

client_scripts {
  'client.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server.lua'
}
