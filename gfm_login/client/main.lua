local isLoggedIn = false
local hasOpenedNUI = false

-- Prevent esx_multicharacter and esx_identity from auto-opening
-- We block the default spawning until the player logs in through our system
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- Hide HUD elements during login
    DisplayRadar(false)
    
    -- Wait a moment for everything to load
    Citizen.Wait(1000)
    
    -- Open our login NUI
    if not hasOpenedNUI then
        hasOpenedNUI = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "open"
        })
        
        -- Request account check from server
        TriggerServerEvent('gfm_login:checkAccount')
    end
end)

-- Disable controls while NUI is open
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if not isLoggedIn then
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            -- Keep the game paused visually
            SetCloudHatOpacity(0.01)
        else
            Citizen.Wait(500)
        end
    end
end)

-- Account found - player has registered before
RegisterNetEvent('gfm_login:accountFound')
AddEventHandler('gfm_login:accountFound', function(data)
    SendNUIMessage({
        action = "accountFound",
        email = data.email,
        username = data.username
    })
end)

-- No account found
RegisterNetEvent('gfm_login:noAccount')
AddEventHandler('gfm_login:noAccount', function()
    SendNUIMessage({
        action = "noAccount"
    })
end)

-- Server response (login/register result)
RegisterNetEvent('gfm_login:response')
AddEventHandler('gfm_login:response', function(data)
    SendNUIMessage({
        action = "response",
        success = data.success,
        message = data.message,
        responseAction = data.action or ""
    })
end)

-- Start game - close NUI and open multicharacter
RegisterNetEvent('gfm_login:startGame')
AddEventHandler('gfm_login:startGame', function()
    isLoggedIn = true
    
    -- Close our NUI
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "close"
    })
    
    -- Small delay before opening multicharacter
    Citizen.Wait(500)
    
    -- Show radar again
    DisplayRadar(true)
    
    -- Trigger esx_multicharacter to open
    -- This is the standard way ESX Legacy handles it
    TriggerEvent('esx_multicharacter:open')
end)

-- NUI Callbacks
RegisterNUICallback('register', function(data, cb)
    TriggerServerEvent('gfm_login:register', {
        email = data.email,
        password = data.password,
        username = data.username,
        nationality = data.nationality
    })
    cb('ok')
end)

RegisterNUICallback('login', function(data, cb)
    TriggerServerEvent('gfm_login:login', {
        email = data.email,
        password = data.password
    })
    cb('ok')
end)

RegisterNUICallback('play', function(data, cb)
    TriggerServerEvent('gfm_login:play')
    cb('ok')
end)

-- Prevent default spawning until logged in
AddEventHandler('esx:playerLoaded', function(xPlayer)
    -- Player loaded through ESX, handled after our login
end)

-- Block multicharacter if not logged in
AddEventHandler('esx_multicharacter:open', function()
    if not isLoggedIn then
        -- Cancel this event - player hasn't logged in yet
        return
    end
end)
