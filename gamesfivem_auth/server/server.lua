ESX = exports["es_extended"]:getSharedObject()

-- Configuración
local Config = {
    RequireAuth = true,
    PasswordSalt = "GamesFiveM_2024_SecureHash" -- Cambia esto por tu propia salt
}

-- Tabla para rastrear jugadores autenticados
local AuthenticatedPlayers = {}

-- Función para hashear contraseñas (simple hash, considera usar bcrypt en producción)
local function HashPassword(password)
    return GetPasswordHash(password, Config.PasswordSalt)
end

-- Verificar si el jugador está autenticado
local function IsPlayerAuthenticated(source)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    return AuthenticatedPlayers[identifier] ~= nil
end

-- Registrar nuevo usuario
ESX.RegisterServerCallback('gamesfivem_auth:register', function(source, cb, data)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    local license = GetPlayerIdentifierByType(source, 'license')
    
    if not data.email or not data.password or not data.username or not data.nationality then
        cb({success = false, message = 'Todos los campos son obligatorios'})
        return
    end

    -- Validar formato de email
    if not string.match(data.email, '^[%w._%+-]+@[%w.-]+%.%w%w+$') then
        cb({success = false, message = 'Formato de correo electrónico inválido'})
        return
    end

    -- Validar longitud de contraseña
    if string.len(data.password) < 6 then
        cb({success = false, message = 'La contraseña debe tener al menos 6 caracteres'})
        return
    end

    -- Hash de la contraseña
    local hashedPassword = HashPassword(data.password)

    -- Verificar si el email ya existe
    MySQL.Async.fetchScalar('SELECT id FROM gamesfivem_users WHERE email = @email', {
        ['@email'] = data.email
    }, function(existingId)
        if existingId then
            cb({success = false, message = 'Este correo electrónico ya está registrado'})
            return
        end

        -- Verificar si el username ya existe
        MySQL.Async.fetchScalar('SELECT id FROM gamesfivem_users WHERE username = @username', {
            ['@username'] = data.username
        }, function(existingUsername)
            if existingUsername then
                cb({success = false, message = 'Este nombre de usuario ya está en uso'})
                return
            end

            -- Insertar nuevo usuario
            MySQL.Async.insert('INSERT INTO gamesfivem_users (email, password, username, nationality) VALUES (@email, @password, @username, @nationality)', {
                ['@email'] = data.email,
                ['@password'] = hashedPassword,
                ['@username'] = data.username,
                ['@nationality'] = data.nationality
            }, function(userId)
                if userId then
                    -- Vincular identifier con el usuario
                    MySQL.Async.insert('INSERT INTO gamesfivem_user_identifiers (user_id, identifier, license) VALUES (@user_id, @identifier, @license)', {
                        ['@user_id'] = userId,
                        ['@identifier'] = identifier,
                        ['@license'] = license
                    }, function(insertId)
                        if insertId then
                            AuthenticatedPlayers[identifier] = {
                                userId = userId,
                                email = data.email,
                                username = data.username,
                                nationality = data.nationality
                            }
                            
                            print('^2[GamesFiveM Auth]^7 Nuevo usuario registrado: ' .. data.username .. ' (ID: ' .. userId .. ')')
                            cb({success = true, message = 'Registro exitoso'})
                        else
                            cb({success = false, message = 'Error al vincular la cuenta'})
                        end
                    end)
                else
                    cb({success = false, message = 'Error al crear la cuenta'})
                end
            end)
        end)
    end)
end)

-- Iniciar sesión
ESX.RegisterServerCallback('gamesfivem_auth:login', function(source, cb, data)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    local license = GetPlayerIdentifierByType(source, 'license')
    
    if not data.email or not data.password then
        cb({success = false, message = 'Correo y contraseña son obligatorios'})
        return
    end

    local hashedPassword = HashPassword(data.password)

    -- Buscar usuario por email y contraseña
    MySQL.Async.fetchAll('SELECT * FROM gamesfivem_users WHERE email = @email AND password = @password', {
        ['@email'] = data.email,
        ['@password'] = hashedPassword
    }, function(result)
        if result[1] then
            local user = result[1]
            
            -- Verificar si ya existe vinculación con este identifier
            MySQL.Async.fetchScalar('SELECT id FROM gamesfivem_user_identifiers WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            }, function(existingLink)
                if existingLink then
                    -- Verificar que el identifier pertenezca a este usuario
                    MySQL.Async.fetchScalar('SELECT user_id FROM gamesfivem_user_identifiers WHERE identifier = @identifier', {
                        ['@identifier'] = identifier
                    }, function(linkedUserId)
                        if linkedUserId ~= user.id then
                            cb({success = false, message = 'Este identifier ya está vinculado a otra cuenta'})
                            return
                        end
                        
                        -- Actualizar último login
                        MySQL.Async.execute('UPDATE gamesfivem_users SET last_login = NOW() WHERE id = @id', {
                            ['@id'] = user.id
                        })

                        AuthenticatedPlayers[identifier] = {
                            userId = user.id,
                            email = user.email,
                            username = user.username,
                            nationality = user.nationality
                        }
                        
                        print('^2[GamesFiveM Auth]^7 Usuario autenticado: ' .. user.username .. ' (ID: ' .. user.id .. ')')
                        cb({success = true, message = 'Inicio de sesión exitoso', username = user.username})
                    end)
                else
                    -- Vincular identifier con la cuenta existente
                    MySQL.Async.insert('INSERT INTO gamesfivem_user_identifiers (user_id, identifier, license) VALUES (@user_id, @identifier, @license)', {
                        ['@user_id'] = user.id,
                        ['@identifier'] = identifier,
                        ['@license'] = license
                    }, function(insertId)
                        -- Actualizar último login
                        MySQL.Async.execute('UPDATE gamesfivem_users SET last_login = NOW() WHERE id = @id', {
                            ['@id'] = user.id
                        })

                        AuthenticatedPlayers[identifier] = {
                            userId = user.id,
                            email = user.email,
                            username = user.username,
                            nationality = user.nationality
                        }
                        
                        print('^2[GamesFiveM Auth]^7 Usuario autenticado: ' .. user.username .. ' (ID: ' .. user.id .. ')')
                        cb({success = true, message = 'Inicio de sesión exitoso', username = user.username})
                    end)
                end
            end)
        else
            cb({success = false, message = 'Correo o contraseña incorrectos'})
        end
    end)
end)

-- Verificar si el jugador ya está autenticado (al conectarse)
ESX.RegisterServerCallback('gamesfivem_auth:checkAuth', function(source, cb)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    
    MySQL.Async.fetchAll('SELECT u.* FROM gamesfivem_users u INNER JOIN gamesfivem_user_identifiers ui ON u.id = ui.user_id WHERE ui.identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] then
            local user = result[1]
            AuthenticatedPlayers[identifier] = {
                userId = user.id,
                email = user.email,
                username = user.username,
                nationality = user.nationality
            }
            
            print('^2[GamesFiveM Auth]^7 Usuario reconectado: ' .. user.username .. ' (ID: ' .. user.id .. ')')
            cb({authenticated = true, username = user.username})
        else
            cb({authenticated = false})
        end
    end)
end)

-- Verificar si tiene personajes creados
ESX.RegisterServerCallback('gamesfivem_auth:hasCharacters', function(source, cb)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM users WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(count)
        cb(count and count > 0)
    end)
end)

-- Evento cuando el jugador se desconecta
AddEventHandler('playerDropped', function(reason)
    local source = source
    local identifier = GetPlayerIdentifierByType(source, 'license')
    
    if AuthenticatedPlayers[identifier] then
        print('^3[GamesFiveM Auth]^7 Usuario desconectado: ' .. AuthenticatedPlayers[identifier].username)
        AuthenticatedPlayers[identifier] = nil
    end
end)

-- Proteger esx_multicharacter y esx_identity
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    local identifier = GetPlayerIdentifierByType(playerId, 'license')
    
    if not IsPlayerAuthenticated(playerId) then
        print('^1[GamesFiveM Auth]^7 Jugador no autenticado intentó cargar personaje. Expulsando...')
        DropPlayer(playerId, 'Debes autenticarte primero en GamesFiveM')
    end
end)

-- Comando para ver jugadores autenticados (admin)
RegisterCommand('authlist', function(source, args, rawCommand)
    if source == 0 then -- Solo consola del servidor
        print('^2[GamesFiveM Auth]^7 Jugadores autenticados:')
        for identifier, data in pairs(AuthenticatedPlayers) do
            print('  - ' .. data.username .. ' (ID: ' .. data.userId .. ') | Email: ' .. data.email)
        end
    end
end, true)

print('^2[GamesFiveM Auth]^7 Sistema de autenticación cargado correctamente')
