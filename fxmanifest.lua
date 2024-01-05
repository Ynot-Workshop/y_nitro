fx_version 'cerulean'
game 'gta5'

description 'qbx_nitro'
repository 'https://github.com/Qbox-project/qbx_nitro'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
}

client_script 'client/main.lua'

server_script 'server/main.lua'

ui_page "html/index.html"
files {
	"html/index.html",
    "html/style.css",
    "html/script.js",
    "config/client.lua",
    "locales/*.json"
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'