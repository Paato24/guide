local uiOpen = false
local hasOpened = false
local pendingCallbacks = {}
local requestCounter = 0

local function DebugLog(message)
  if Config.Debug then
    print(('[GamesFiveM] %s'):format(message))
  end
end

local function CreateRequestId()
  requestCounter = requestCounter + 1
  return ('%s-%s'):format(GetGameTimer(), requestCounter)
end

local function SetUiVisible(visible)
  uiOpen = visible
  SetNuiFocus(visible, visible)
  SetNuiFocusKeepInput(false)
  SendNUIMessage({ action = visible and 'show' or 'hide' })

  local ped = PlayerPedId()
  if ped and ped > 0 then
    FreezeEntityPosition(ped, visible)
    SetEntityInvincible(ped, visible)
  end

  DisplayRadar(not visible)
  DebugLog(visible and 'UI opened' or 'UI closed')
end

local function OpenUi()
  if uiOpen then
    return
  end
  SetUiVisible(true)
end

local function CloseUi()
  if not uiOpen then
    return
  end
  SetUiVisible(false)
end

CreateThread(function()
  while true do
    if uiOpen then
      DisableAllControlActions(0)
      Wait(0)
    else
      Wait(500)
    end
  end
end)

AddEventHandler('playerSpawned', function()
  if hasOpened then
    return
  end
  Wait(800)
  OpenUi()
  hasOpened = true
end)

AddEventHandler('onClientResourceStart', function(resourceName)
  if resourceName ~= GetCurrentResourceName() then
    return
  end
  Wait(800)
  OpenUi()
  hasOpened = true
end)

RegisterNetEvent('gf_account:close', function()
  CloseUi()
end)

RegisterNetEvent('gf_account:loginResult', function(requestId, ok, message, account)
  local cb = pendingCallbacks[requestId]
  if cb then
    cb({ ok = ok, message = message or '' })
    pendingCallbacks[requestId] = nil
  end

  if ok then
    SendNUIMessage({ action = 'setAuthenticated', account = account or {} })
  end
end)

RegisterNetEvent('gf_account:registerResult', function(requestId, ok, message, account)
  local cb = pendingCallbacks[requestId]
  if cb then
    cb({ ok = ok, message = message or '' })
    pendingCallbacks[requestId] = nil
  end

  if ok then
    SendNUIMessage({ action = 'setAuthenticated', account = account or {} })
  end
end)

RegisterNetEvent('gf_account:playResult', function(requestId, ok, message)
  local cb = pendingCallbacks[requestId]
  if cb then
    cb({ ok = ok, message = message or '' })
    pendingCallbacks[requestId] = nil
  end
end)

RegisterNUICallback('login', function(data, cb)
  local requestId = CreateRequestId()
  pendingCallbacks[requestId] = cb
  TriggerServerEvent('gf_account:login', requestId, data or {})
end)

RegisterNUICallback('register', function(data, cb)
  local requestId = CreateRequestId()
  pendingCallbacks[requestId] = cb
  TriggerServerEvent('gf_account:register', requestId, data or {})
end)

RegisterNUICallback('play', function(_, cb)
  local requestId = CreateRequestId()
  pendingCallbacks[requestId] = cb
  TriggerServerEvent('gf_account:play', requestId)
end)

RegisterNUICallback('uiReady', function(_, cb)
  cb({ ok = true })
end)
