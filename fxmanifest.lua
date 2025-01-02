fx_version 'cerulean'
game 'gta5'

author 'Ynot'
description 'y_nitro'
repository 'https://github.com/ynot-workshop/y_nitro'
version '1.0.1'

ox_lib 'locale'
shared_script '@ox_lib/init.lua'

client_scripts {
    '@qbx_core/modules/lib.lua',
    'client/main.lua'
}

server_script 'server/main.lua'

files {
    'config/client.lua',
    'locales/*.json'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
