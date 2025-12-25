fx_version 'cerulean'
game 'gta5'

author 'https://em4nu3l69dll.dev/'
description 'Sistema de tablet basico '
version '1.0.0'
license 'MIT'

lua54 'yes'

dependencies {
    'oxmysql'
}

shared_scripts {
    '@oxmysql/lib/MySQL.lua',
    'shared/configuracion.lua',
    'shared/configuracion_tablet.lua'
}

client_scripts {
    'cliente/tablet.lua'
}

server_scripts {
    'servidor/tablet.lua'
}

ui_page 'html/tablet/index.html'

files {
    'html/tablet/**/*'
}
