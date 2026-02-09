local uiOpen = false
local authenticated = false
local canPlay = false

local function setUi(state)
  uiOpen = state
  SetNuiFocus(state, state)
  SetNuiFocusKeepInput(state)
  SendNUIMessage({ type = 'setVisible', visible = state })
end

local function softLockPlayer(state)
  local ped = PlayerPedId()
  FreezeEntityPosition(ped, state)
  SetEntityInvincible(ped, state)
  SetPlayerInvincible(PlayerId(), state)
  SetEntityVisible(ped, not state, false)
  if state then
    SetEntityCoordsNoOffset(ped, 0.0, 0.0, -100.0, false, false, false)
  end
end

CreateThread(function()
  -- Espera a que el player exista
  while not NetworkIsPlayerActive(PlayerId()) do
    Wait(250)
  end
  Wait(800)
  TriggerServerEvent('gf_auth:server:hello')
end)

RegisterNetEvent('gf_auth:client:open', function(payload)
  if uiOpen then return end
  authenticated = false
  canPlay = false
  softLockPlayer(true)
  SendNUIMessage({
    type = 'boot',
    payload = payload or {},
  })
  setUi(true)
end)

RegisterNetEvent('gf_auth:client:authResult', function(result)
  if type(result) ~= 'table' then return end
  if result.ok then
    authenticated = true
    canPlay = true
  end
  SendNUIMessage({ type = 'authResult', result = result })
end)

RegisterNetEvent('gf_auth:client:notify', function(data)
  SendNUIMessage({ type = 'notify', data = data or {} })
end)

RegisterNetEvent('gf_auth:client:beginESXFlow', function(data)
  data = data or {}
  setUi(false)
  softLockPlayer(false)

  -- Intentamos disparar el flujo ESX SOLO después de "Jugar".
  local mc = data.multicharacter or 'esx_multicharacter'
  local id = data.identity or 'esx_identity'

  local function resourceStarted(res)
    return GetResourceState(res) == 'started'
  end

  if data.hasCharacters and resourceStarted(mc) then
    -- Evento más común en ESX Legacy para abrir multicharacter
    TriggerServerEvent('esx_multicharacter:SetupCharacters')
    return
  end

  -- Fallback: identidad (si el server decide que no hay personajes)
  if resourceStarted(id) then
    -- Algunos servers lo exponen como client event
    TriggerEvent('esx_identity:showRegisterIdentity')
  else
    -- Si no está identity, al menos informamos.
    TriggerEvent('chat:addMessage', { args = { '^1GamesFiveM', 'No se encontró esx_identity. Revisa tu configuración.' } })
  end
end)

-- Control lock mientras UI está abierta
CreateThread(function()
  while true do
    if uiOpen then
      DisableAllControlActions(0)
      EnableControlAction(0, 1, true)   -- look left/right
      EnableControlAction(0, 2, true)   -- look up/down
      EnableControlAction(0, 200, true) -- ESC
      Wait(0)
    else
      Wait(250)
    end
  end
end)

RegisterNUICallback('close', function(_, cb)
  setUi(false)
  TriggerServerEvent('gf_auth:server:closeUi')
  softLockPlayer(false)
  cb({ ok = true })
end)

RegisterNUICallback('login', function(data, cb)
  TriggerServerEvent('gf_auth:server:login', data)
  cb({ ok = true })
end)

RegisterNUICallback('register', function(data, cb)
  TriggerServerEvent('gf_auth:server:register', data)
  cb({ ok = true })
end)

RegisterNUICallback('play', function(_, cb)
  if not authenticated or not canPlay then
    cb({ ok = false })
    return
  end
  TriggerServerEvent('gf_auth:server:play')
  cb({ ok = true })
end)

