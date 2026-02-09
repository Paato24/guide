local Players = {}

local function nowUtc()
  return os.date('!%Y-%m-%d %H:%M:%S')
end

local function trim(s)
  if type(s) ~= 'string' then return '' end
  return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function isValidEmail(email)
  if type(email) ~= 'string' then return false end
  email = trim(email):lower()
  if #email < 6 or #email > 128 then return false end
  -- validación básica (no RFC completa)
  return email:match('^[%w%._%+%-]+@[%w%-]+%.%w%w+$') ~= nil
end

local function isValidUsername(name)
  if type(name) ~= 'string' then return false end
  name = trim(name)
  if #name < 3 or #name > 24 then return false end
  -- letras, números, espacio, guión, guión bajo
  return name:match('^[%w_%-%s]+$') ~= nil
end

local function randomHex(len)
  local t = {}
  for _ = 1, len do
    t[#t + 1] = string.format('%x', math.random(0, 15))
  end
  return table.concat(t)
end

local function getLicense(source)
  local license = GetPlayerIdentifierByType(source, 'license')
  if license and license ~= '' then return license end

  for i = 0, GetNumPlayerIdentifiers(source) - 1 do
    local id = GetPlayerIdentifier(source, i)
    if id and id:sub(1, 8) == 'license:' then
      return id
    end
  end
  return nil
end

local function cooldownOk(source, action, cooldownMs)
  Players[source] = Players[source] or {}
  Players[source].cooldowns = Players[source].cooldowns or {}

  local last = Players[source].cooldowns[action] or 0
  local now = GetGameTimer()
  if (now - last) < (cooldownMs or 1000) then
    return false
  end
  Players[source].cooldowns[action] = now
  return true
end

local function setBucket(source, enabled)
  if not Config.UseRoutingBucket then return end
  local bucket = enabled and (Config.RoutingBucketBase + source) or 0
  SetPlayerRoutingBucket(source, bucket)
end

local function replyAuth(source, payload)
  TriggerClientEvent('gf_auth:client:authResult', source, payload)
end

local function ensureState(source)
  Players[source] = Players[source] or {}
  Players[source].authenticated = Players[source].authenticated or false
  Players[source].canOpenESX = Players[source].canOpenESX or false
  Players[source].accountId = Players[source].accountId or nil
end

AddEventHandler('playerDropped', function()
  local src = source
  Players[src] = nil
end)

-- Exports para parches en otros recursos (esx_multicharacter / esx_identity)
exports('IsAuthenticated', function(source)
  ensureState(source)
  return Players[source].authenticated == true
end)

exports('CanOpenESX', function(source)
  ensureState(source)
  return Players[source].canOpenESX == true
end)

RegisterNetEvent('gf_auth:server:hello', function()
  local src = source
  ensureState(src)

  if Config.ShowOnJoin and not Players[src].authenticated then
    setBucket(src, true)
    TriggerClientEvent('gf_auth:client:open', src, {
      serverName = Config.ServerName,
      tagline = Config.Tagline,
      about = Config.AboutParagraph,
      minPasswordLength = Config.MinPasswordLength,
      maxPasswordLength = Config.MaxPasswordLength,
    })
  end
end)

RegisterNetEvent('gf_auth:server:closeUi', function()
  local src = source
  if not Players[src] then return end
  -- No habilitamos ESX aquí: solo se habilita al pulsar "Jugar"
  setBucket(src, false)
end)

local function createTableIfMissing()
  -- Crea la tabla si no existe (compatible con MySQL/MariaDB)
  local tableName = Config.TableName
  DB.queryAwait(([[
    CREATE TABLE IF NOT EXISTS `%s` (
      `id` INT NOT NULL AUTO_INCREMENT,
      `license` VARCHAR(64) NOT NULL,
      `email` VARCHAR(128) NOT NULL,
      `salt` CHAR(32) NOT NULL,
      `password_hash` CHAR(64) NOT NULL,
      `username` VARCHAR(24) NOT NULL,
      `nationality` VARCHAR(48) NOT NULL,
      `created_at` DATETIME NOT NULL,
      `last_login` DATETIME NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uniq_email` (`email`),
      UNIQUE KEY `uniq_license` (`license`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  ]]):format(tableName))
end

CreateThread(function()
  math.randomseed(os.time() + GetGameTimer())
  createTableIfMissing()
  print(('[gf_auth] listo. Tabla `%s` verificada.'):format(Config.TableName))
end)

RegisterNetEvent('gf_auth:server:register', function(payload)
  local src = source
  ensureState(src)

  if not cooldownOk(src, 'register', Config.ActionCooldownMs) then
    return replyAuth(src, { ok = false, code = 'COOLDOWN', message = 'Espera un momento y vuelve a intentar.' })
  end

  if Players[src].authenticated then
    return replyAuth(src, { ok = true, code = 'ALREADY', message = 'Ya estás autenticado.' })
  end

  payload = payload or {}
  local email = trim(payload.email or ''):lower()
  local password = payload.password or ''
  local username = trim(payload.username or '')
  local nationality = trim(payload.nationality or '')

  if not isValidEmail(email) then
    return replyAuth(src, { ok = false, code = 'BAD_EMAIL', message = 'Correo inválido.' })
  end
  if type(password) ~= 'string' or #password < Config.MinPasswordLength or #password > Config.MaxPasswordLength then
    return replyAuth(src, { ok = false, code = 'BAD_PASSWORD', message = ('La contraseña debe tener entre %d y %d caracteres.'):format(Config.MinPasswordLength, Config.MaxPasswordLength) })
  end
  if not isValidUsername(username) then
    return replyAuth(src, { ok = false, code = 'BAD_USERNAME', message = 'Nombre de usuario inválido (3-24, letras/números/espacios/guión/guión bajo).' })
  end
  if nationality == '' or #nationality > 48 then
    return replyAuth(src, { ok = false, code = 'BAD_NATIONALITY', message = 'Nacionalidad inválida.' })
  end

  local license = getLicense(src)
  if not license then
    return replyAuth(src, { ok = false, code = 'NO_LICENSE', message = 'No se pudo obtener tu licencia de FiveM.' })
  end

  local tableName = Config.TableName

  -- Evitar duplicados por email o por license
  local existing = DB.singleAwait(('SELECT id FROM `%s` WHERE email = ? OR license = ? LIMIT 1'):format(tableName), { email, license })
  if existing and existing.id then
    return replyAuth(src, { ok = false, code = 'EXISTS', message = 'Ya existe una cuenta con ese correo o esta licencia.' })
  end

  local salt = randomHex(32)
  local id = DB.insertAwait(
    ('INSERT INTO `%s` (license, email, salt, password_hash, username, nationality, created_at) VALUES (?, ?, ?, SHA2(CONCAT(?, ?), 256), ?, ?, ?)'):format(tableName),
    { license, email, salt, salt, password, username, nationality, nowUtc() }
  )

  Players[src].authenticated = true
  Players[src].canOpenESX = false
  Players[src].accountId = id

  replyAuth(src, {
    ok = true,
    code = 'REGISTER_OK',
    message = 'Cuenta creada. Pulsa "Jugar" para continuar.',
    profile = { email = email, username = username, nationality = nationality },
  })
end)

RegisterNetEvent('gf_auth:server:login', function(payload)
  local src = source
  ensureState(src)

  if not cooldownOk(src, 'login', Config.ActionCooldownMs) then
    return replyAuth(src, { ok = false, code = 'COOLDOWN', message = 'Espera un momento y vuelve a intentar.' })
  end

  if Players[src].authenticated then
    return replyAuth(src, { ok = true, code = 'ALREADY', message = 'Ya estás autenticado.' })
  end

  payload = payload or {}
  local email = trim(payload.email or ''):lower()
  local password = payload.password or ''

  if not isValidEmail(email) then
    return replyAuth(src, { ok = false, code = 'BAD_EMAIL', message = 'Correo inválido.' })
  end
  if type(password) ~= 'string' or #password < 1 then
    return replyAuth(src, { ok = false, code = 'BAD_PASSWORD', message = 'Contraseña inválida.' })
  end

  local license = getLicense(src)
  if not license then
    return replyAuth(src, { ok = false, code = 'NO_LICENSE', message = 'No se pudo obtener tu licencia de FiveM.' })
  end

  local tableName = Config.TableName

  local row = DB.singleAwait(
    ('SELECT id, license, email, username, nationality FROM `%s` WHERE email = ? AND password_hash = SHA2(CONCAT(salt, ?), 256) LIMIT 1'):format(tableName),
    { email, password }
  )

  if not row or not row.id then
    return replyAuth(src, { ok = false, code = 'INVALID', message = 'Correo o contraseña incorrectos.' })
  end

  if row.license ~= license then
    return replyAuth(src, { ok = false, code = 'LICENSE_MISMATCH', message = 'Esta cuenta no pertenece a esta licencia.' })
  end

  DB.updateAwait(('UPDATE `%s` SET last_login = ? WHERE id = ?'):format(tableName), { nowUtc(), row.id })

  Players[src].authenticated = true
  Players[src].canOpenESX = false
  Players[src].accountId = row.id

  replyAuth(src, {
    ok = true,
    code = 'LOGIN_OK',
    message = 'Sesión iniciada. Pulsa "Jugar" para continuar.',
    profile = { email = row.email, username = row.username, nationality = row.nationality },
  })
end)

local function guessHasCharacters(src, license)
  -- Heurística ESX Legacy multicharacter:
  -- identifiers suelen ser: char1:license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  -- Si falla la query (tabla no existe), devolvemos true para que el server abra multicharacter.
  local ok, result = pcall(function()
    local users = DB.scalarAwait("SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'users' LIMIT 1")
    if not users then return true end
    local exists = DB.scalarAwait("SELECT 1 FROM users WHERE identifier LIKE CONCAT('char%:', ?) LIMIT 1", { license })
    return exists ~= nil
  end)
  if not ok then
    return true
  end
  return result == true
end

RegisterNetEvent('gf_auth:server:play', function()
  local src = source
  ensureState(src)

  if not cooldownOk(src, 'play', 500) then return end
  if not Players[src].authenticated then
    return TriggerClientEvent('gf_auth:client:notify', src, { type = 'error', message = 'Debes iniciar sesión o registrarte.' })
  end

  Players[src].canOpenESX = true
  setBucket(src, false)

  local license = getLicense(src)
  local hasCharacters = license and guessHasCharacters(src, license) or true

  TriggerClientEvent('gf_auth:client:beginESXFlow', src, {
    hasCharacters = hasCharacters,
    multicharacter = Config.MulticharacterResource,
    identity = Config.IdentityResource,
  })
end)

