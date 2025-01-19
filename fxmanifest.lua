fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Orion Studios'
description 'A Fun Script For Your FiveM Server'
version '1.0.0'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'ox_lib' 
}

shared_scripts {
    '@ox_lib/init.lua'
}
