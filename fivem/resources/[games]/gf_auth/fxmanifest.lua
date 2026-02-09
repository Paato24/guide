fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'gf_auth'
author 'GamesFiveM'
description 'NUI login/registro con guard para ESX (multicharacter/identity) - GamesFiveM'
version '1.0.0'

shared_scripts {
  'shared/config.lua',
}

client_scripts {
  'client/main.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/db.lua',
  'server/main.lua',
}

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/assets/logo.svg',
}
