fx_version 'cerulean'
game 'gta5'

description 'qbx_nitro'
repository 'https://github.com/Qbox-project/qbx_nitro'
version '1.0.0'

ox_lib 'locale'
shared_script '@ox_lib/init.lua'

client_scripts {
    '@qbx_core/modules/lib.lua',
    'client/main.lua'
}

server_script 'server/main.lua'

files {
    "config/client.lua",
    "locales/*.json"
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
