local Authenticated = {}
local math_random = math.random

math.randomseed(os.time())

local function DebugLog(message)
  if Config.Debug then
    print(('[GamesFiveM] %s'):format(message))
  end
end

local function Trim(value)
  return (value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function NormalizeEmail(value)
  local email = Trim(value):lower():gsub('%s+', '')
  return email
end

local function IsValidEmail(value)
  if value == '' then
    return false
  end
  return value:match('^[%w%.%+%-_]+@[%w%-_]+%.[%w%.%-_]+$') ~= nil
end

local function CleanText(value, maxLength)
  local text = Trim(value):gsub('%s+', ' ')
  if maxLength and #text > maxLength then
    text = text:sub(1, maxLength)
  end
  return text
end

local function GetIdentifier(source)
  if GetPlayerIdentifierByType then
    local license = GetPlayerIdentifierByType(source, 'license')
    if license then
      return license
    end
  end

  local identifiers = GetPlayerIdentifiers(source)
  for _, identifier in ipairs(identifiers) do
    if identifier:find('license:') then
      return identifier
    end
  end

  return identifiers[1]
end

local function GenerateSalt(length)
  local alphabet = 'abcdef0123456789'
  local salt = {}
  for i = 1, length do
    local index = math_random(#alphabet)
    salt[i] = alphabet:sub(index, index)
  end
  return table.concat(salt)
end

local function RightRotate(value, bits)
  return ((value >> bits) | (value << (32 - bits))) & 0xffffffff
end

local function Sha256(message)
  local K = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
  }

  local H = {
    0x6a09e667,
    0xbb67ae85,
    0x3c6ef372,
    0xa54ff53a,
    0x510e527f,
    0x9b05688c,
    0x1f83d9ab,
    0x5be0cd19
  }

  local bytes = { message:byte(1, #message) }
  bytes[#bytes + 1] = 0x80

  while (#bytes % 64) ~= 56 do
    bytes[#bytes + 1] = 0x00
  end

  local bitLen = #message * 8
  for i = 7, 0, -1 do
    bytes[#bytes + 1] = (bitLen >> (i * 8)) & 0xff
  end

  for chunk = 1, #bytes, 64 do
    local w = {}
    for i = 0, 15 do
      local start = chunk + (i * 4)
      w[i] = ((bytes[start] << 24) | (bytes[start + 1] << 16) | (bytes[start + 2] << 8) | bytes[start + 3]) & 0xffffffff
    end

    for i = 16, 63 do
      local s0 = (RightRotate(w[i - 15], 7) ~ RightRotate(w[i - 15], 18) ~ (w[i - 15] >> 3)) & 0xffffffff
      local s1 = (RightRotate(w[i - 2], 17) ~ RightRotate(w[i - 2], 19) ~ (w[i - 2] >> 10)) & 0xffffffff
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff
    end

    local a = H[1]
    local b = H[2]
    local c = H[3]
    local d = H[4]
    local e = H[5]
    local f = H[6]
    local g = H[7]
    local h = H[8]

    for i = 0, 63 do
      local s1 = (RightRotate(e, 6) ~ RightRotate(e, 11) ~ RightRotate(e, 25)) & 0xffffffff
      local ch = ((e & f) ~ ((~e) & g)) & 0xffffffff
      local temp1 = (h + s1 + ch + K[i + 1] + w[i]) & 0xffffffff
      local s0 = (RightRotate(a, 2) ~ RightRotate(a, 13) ~ RightRotate(a, 22)) & 0xffffffff
      local maj = ((a & b) ~ (a & c) ~ (b & c)) & 0xffffffff
      local temp2 = (s0 + maj) & 0xffffffff

      h = g
      g = f
      f = e
      e = (d + temp1) & 0xffffffff
      d = c
      c = b
      b = a
      a = (temp1 + temp2) & 0xffffffff
    end

    H[1] = (H[1] + a) & 0xffffffff
    H[2] = (H[2] + b) & 0xffffffff
    H[3] = (H[3] + c) & 0xffffffff
    H[4] = (H[4] + d) & 0xffffffff
    H[5] = (H[5] + e) & 0xffffffff
    H[6] = (H[6] + f) & 0xffffffff
    H[7] = (H[7] + g) & 0xffffffff
    H[8] = (H[8] + h) & 0xffffffff
  end

  return string.format(
    '%08x%08x%08x%08x%08x%08x%08x%08x',
    H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
  )
end

local function HashPassword(password, salt)
  return Sha256(salt .. password)
end

local function HasCharacters(identifier)
  if not Config.CharacterCheck.Enabled then
    return true
  end

  local likePattern = Config.CharacterCheck.LikePattern or '%%%s%%'
  local query = ('SELECT 1 FROM %s WHERE %s LIKE ? LIMIT 1'):format(
    Config.CharacterCheck.Table,
    Config.CharacterCheck.IdentifierColumn
  )

  local ok, result = pcall(function()
    return MySQL.scalar.await(query, { string.format(likePattern, identifier) })
  end)

  if not ok then
    print(('[GamesFiveM] Character check failed: %s'):format(result))
    return Config.CharacterCheck.FallbackToMulticharacter
  end

  return result ~= nil
end

local function OpenMulticharacter(source)
  if Config.Multicharacter.EventSide == 'client' then
    TriggerClientEvent(Config.Multicharacter.Event, source)
  else
    TriggerEvent(Config.Multicharacter.Event, source)
  end
end

local function OpenIdentity(source)
  if Config.Identity.EventSide == 'client' then
    TriggerClientEvent(Config.Identity.Event, source)
  else
    TriggerEvent(Config.Identity.Event, source)
  end
end

RegisterNetEvent('gf_account:register', function(requestId, data)
  local source = source
  local identifier = GetIdentifier(source)
  if not identifier then
    TriggerClientEvent('gf_account:registerResult', source, requestId, false, 'No se pudo obtener tu identificador.')
    return
  end

  local email = NormalizeEmail(data.email or '')
  if not IsValidEmail(email) then
    TriggerClientEvent('gf_account:registerResult', source, requestId, false, 'Correo invalido.')
    return
  end

  local password = tostring(data.password or '')
  if #password < Config.Validation.MinPasswordLength or #password > Config.Validation.MaxPasswordLength then
    TriggerClientEvent(
      'gf_account:registerResult',
      source,
      requestId,
      false,
      ('La contrasena debe tener entre %d y %d caracteres.'):format(
        Config.Validation.MinPasswordLength,
        Config.Validation.MaxPasswordLength
      )
    )
    return
  end

  local username = CleanText(data.username or '', Config.Validation.MaxUsernameLength)
  if #username < Config.Validation.MinUsernameLength then
    TriggerClientEvent('gf_account:registerResult', source, requestId, false, 'Nombre de usuario invalido.')
    return
  end

  local nationality = CleanText(data.nationality or '', Config.Validation.MaxNationalityLength)
  if nationality == '' then
    TriggerClientEvent('gf_account:registerResult', source, requestId, false, 'Nacionalidad requerida.')
    return
  end

  local existing = MySQL.single.await(
    ('SELECT id FROM %s WHERE identifier = ? OR email = ? LIMIT 1'):format(Config.Database.AccountTable),
    { identifier, email }
  )

  if existing then
    TriggerClientEvent('gf_account:registerResult', source, requestId, false, 'Ya existe una cuenta con esos datos.')
    return
  end

  local salt = GenerateSalt(16)
  local passwordHash = HashPassword(password, salt)

  local accountId = MySQL.insert.await(
    ('INSERT INTO %s (identifier, email, password_hash, password_salt, username, nationality) VALUES (?, ?, ?, ?, ?, ?)'):format(Config.Database.AccountTable),
    { identifier, email, passwordHash, salt, username, nationality }
  )

  Authenticated[source] = {
    accountId = accountId,
    identifier = identifier,
    email = email,
    username = username,
    nationality = nationality
  }

  DebugLog(('Account created: %s (%s)'):format(email, identifier))

  TriggerClientEvent(
    'gf_account:registerResult',
    source,
    requestId,
    true,
    'Cuenta creada. Pulsa Jugar para continuar.',
    {
      email = email,
      username = username,
      nationality = nationality
    }
  )
end)

RegisterNetEvent('gf_account:login', function(requestId, data)
  local source = source
  local identifier = GetIdentifier(source)
  if not identifier then
    TriggerClientEvent('gf_account:loginResult', source, requestId, false, 'No se pudo obtener tu identificador.')
    return
  end

  local email = NormalizeEmail(data.email or '')
  if not IsValidEmail(email) then
    TriggerClientEvent('gf_account:loginResult', source, requestId, false, 'Correo invalido.')
    return
  end

  local password = tostring(data.password or '')
  if password == '' then
    TriggerClientEvent('gf_account:loginResult', source, requestId, false, 'Contrasena requerida.')
    return
  end

  local account = MySQL.single.await(
    ('SELECT id, identifier, password_hash, password_salt, username, nationality FROM %s WHERE email = ? LIMIT 1'):format(Config.Database.AccountTable),
    { email }
  )

  if not account then
    TriggerClientEvent('gf_account:loginResult', source, requestId, false, 'Cuenta no encontrada.')
    return
  end

  if account.identifier ~= identifier then
    TriggerClientEvent('gf_account:loginResult', source, requestId, false, 'Esta cuenta pertenece a otro identificador.')
    return
  end

  local passwordHash = HashPassword(password, account.password_salt)
  if passwordHash ~= account.password_hash then
    TriggerClientEvent('gf_account:loginResult', source, requestId, false, 'Contrasena incorrecta.')
    return
  end

  MySQL.update.await(
    ('UPDATE %s SET last_login = NOW() WHERE id = ?'):format(Config.Database.AccountTable),
    { account.id }
  )

  Authenticated[source] = {
    accountId = account.id,
    identifier = identifier,
    email = email,
    username = account.username,
    nationality = account.nationality
  }

  DebugLog(('Account login: %s (%s)'):format(email, identifier))

  TriggerClientEvent(
    'gf_account:loginResult',
    source,
    requestId,
    true,
    'Bienvenido. Pulsa Jugar para continuar.',
    {
      email = email,
      username = account.username,
      nationality = account.nationality
    }
  )
end)

RegisterNetEvent('gf_account:play', function(requestId)
  local source = source
  local session = Authenticated[source]
  if not session then
    TriggerClientEvent('gf_account:playResult', source, requestId, false, 'Debes iniciar sesion.')
    return
  end

  TriggerClientEvent('gf_account:playResult', source, requestId, true, 'Abriendo seleccion de personaje...')
  TriggerClientEvent('gf_account:close', source)

  local hasCharacter = HasCharacters(session.identifier)
  if hasCharacter then
    OpenMulticharacter(source)
  else
    OpenIdentity(source)
  end
end)

AddEventHandler('playerDropped', function()
  local source = source
  Authenticated[source] = nil
end)
