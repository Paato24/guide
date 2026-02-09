ESX = exports["es_extended"]:getSharedObject()

local isAuthenticated = false
local isUIOpen = false
local hasCheckedAuth = false

-- Desactivar controles mientras la UI está abierta
CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen then
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
        end
    end
end)

-- Función para abrir la UI de autenticación
local function OpenAuthUI()
    if isAuthenticated then
        return
    end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openAuth',
        display = true
    })
    
    -- Desactivar HUD
    DisplayRadar(false)
    DisplayHud(false)
end

-- Función para cerrar la UI
local function CloseAuthUI()
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'closeAuth',
        display = false
    })
    
    -- Reactivar HUD
    DisplayRadar(true)
    DisplayHud(true)
end

-- Callback desde NUI - Registro
RegisterNUICallback('register', function(data, cb)
    ESX.TriggerServerCallback('gamesfivem_auth:register', function(response)
        cb(response)
        
        if response.success then
            Wait(2000)
            isAuthenticated = true
            CloseAuthUI()
            
            -- Verificar si tiene personajes
            ESX.TriggerServerCallback('gamesfivem_auth:hasCharacters', function(hasChars)
                if hasChars then
                    -- Abrir multicharacter
                    TriggerEvent('esx_multicharacter:spawnPlayer')
                else
                    -- Abrir identity para crear primer personaje
                    TriggerEvent('esx_identity:showRegisterIdentity')
                end
            end)
        end
    end, data)
end)

-- Callback desde NUI - Login
RegisterNUICallback('login', function(data, cb)
    ESX.TriggerServerCallback('gamesfivem_auth:login', function(response)
        cb(response)
        
        if response.success then
            Wait(2000)
            isAuthenticated = true
            CloseAuthUI()
            
            -- Verificar si tiene personajes
            ESX.TriggerServerCallback('gamesfivem_auth:hasCharacters', function(hasChars)
                if hasChars then
                    -- Abrir multicharacter
                    TriggerEvent('esx_multicharacter:spawnPlayer')
                else
                    -- Abrir identity para crear primer personaje
                    TriggerEvent('esx_identity:showRegisterIdentity')
                end
            end)
        end
    end, data)
end)

-- Callback desde NUI - Cerrar (solo para debug, normalmente no se puede cerrar sin autenticar)
RegisterNUICallback('closeUI', function(data, cb)
    if isAuthenticated then
        CloseAuthUI()
    end
    cb('ok')
end)

-- Bloquear esx_multicharacter y esx_identity hasta autenticar
AddEventHandler('esx_multicharacter:beforeOpen', function()
    if not isAuthenticated then
        CancelEvent()
        OpenAuthUI()
    end
end)

AddEventHandler('esx_identity:beforeRegister', function()
    if not isAuthenticated then
        CancelEvent()
        OpenAuthUI()
    end
end)

-- Al spawnearse el jugador
AddEventHandler('playerSpawned', function()
    if not hasCheckedAuth then
        hasCheckedAuth = true
        
        -- Verificar si ya está autenticado en el servidor
        ESX.TriggerServerCallback('gamesfivem_auth:checkAuth', function(result)
            if result.authenticated then
                isAuthenticated = true
                
                -- Verificar si tiene personajes
                ESX.TriggerServerCallback('gamesfivem_auth:hasCharacters', function(hasChars)
                    if hasChars then
                        -- Abrir multicharacter
                        TriggerEvent('esx_multicharacter:spawnPlayer')
                    else
                        -- Abrir identity para crear primer personaje
                        TriggerEvent('esx_identity:showRegisterIdentity')
                    end
                end)
            else
                OpenAuthUI()
            end
        end)
    end
end)

-- Al conectarse al servidor
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    Wait(1000) -- Esperar a que ESX se inicialice
    
    if not hasCheckedAuth then
        hasCheckedAuth = true
        
        -- Verificar si ya está autenticado
        ESX.TriggerServerCallback('gamesfivem_auth:checkAuth', function(result)
            if result.authenticated then
                isAuthenticated = true
                
                -- Verificar si tiene personajes
                ESX.TriggerServerCallback('gamesfivem_auth:hasCharacters', function(hasChars)
                    if hasChars then
                        -- Abrir multicharacter
                        Wait(500)
                        TriggerEvent('esx_multicharacter:spawnPlayer')
                    else
                        -- Abrir identity para crear primer personaje
                        Wait(500)
                        TriggerEvent('esx_identity:showRegisterIdentity')
                    end
                end)
            else
                OpenAuthUI()
            end
        end)
    end
end)

-- Comando para reabrir UI (solo si no está autenticado)
RegisterCommand('auth', function()
    if not isAuthenticated then
        OpenAuthUI()
    else
        ESX.ShowNotification('Ya estás autenticado')
    end
end, false)

print('^2[GamesFiveM Auth]^7 Cliente cargado correctamente')
