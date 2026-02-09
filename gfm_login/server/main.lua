local loggedInPlayers = {}

-- Utility: Hash passwords using game's native hash + salt
local function HashPassword(password)
    local salt = Config.PasswordSalt or "gfm_salt_2024_secure"
    local hash = GetHashKey(password .. salt)
    return tostring(hash)
end

-- Check if player has an account linked to their license
RegisterNetEvent('gfm_login:checkAccount')
AddEventHandler('gfm_login:checkAccount', function()
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    
    if not license then
        DropPlayer(src, "No se pudo obtener tu licencia. Reinicia FiveM.")
        return
    end

    MySQL.query('SELECT id, email, username FROM gfm_accounts WHERE license = ?', {license}, function(result)
        if result and #result > 0 then
            -- Player has account(s), send info for auto-fill
            TriggerClientEvent('gfm_login:accountFound', src, {
                email = result[1].email,
                username = result[1].username
            })
        else
            TriggerClientEvent('gfm_login:noAccount', src)
        end
    end)
end)

-- Register new account
RegisterNetEvent('gfm_login:register')
AddEventHandler('gfm_login:register', function(data)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    
    if not license then
        TriggerClientEvent('gfm_login:response', src, {
            success = false,
            message = "Error: No se pudo verificar tu licencia."
        })
        return
    end

    -- Validate fields
    if not data.email or data.email == '' then
        TriggerClientEvent('gfm_login:response', src, {success = false, message = "El correo es obligatorio."})
        return
    end
    if not data.password or data.password == '' or #data.password < 6 then
        TriggerClientEvent('gfm_login:response', src, {success = false, message = "La contraseña debe tener al menos 6 caracteres."})
        return
    end
    if not data.username or data.username == '' or #data.username < 3 then
        TriggerClientEvent('gfm_login:response', src, {success = false, message = "El nombre de usuario debe tener al menos 3 caracteres."})
        return
    end
    if not data.nationality or data.nationality == '' then
        TriggerClientEvent('gfm_login:response', src, {success = false, message = "La nacionalidad es obligatoria."})
        return
    end

    -- Check if email already exists
    MySQL.query('SELECT id FROM gfm_accounts WHERE email = ?', {data.email}, function(emailResult)
        if emailResult and #emailResult > 0 then
            TriggerClientEvent('gfm_login:response', src, {
                success = false,
                message = "Este correo ya está registrado."
            })
            return
        end

        -- Check if username already exists
        MySQL.query('SELECT id FROM gfm_accounts WHERE username = ?', {data.username}, function(usernameResult)
            if usernameResult and #usernameResult > 0 then
                TriggerClientEvent('gfm_login:response', src, {
                    success = false,
                    message = "Este nombre de usuario ya está en uso."
                })
                return
            end

            -- Hash password and insert
            local hashedPassword = HashPassword(data.password)
            
            MySQL.insert('INSERT INTO gfm_accounts (license, email, username, password, nationality) VALUES (?, ?, ?, ?, ?)', 
                {license, data.email, data.username, hashedPassword, data.nationality}, 
                function(insertId)
                    if insertId then
                        loggedInPlayers[src] = {
                            id = insertId,
                            email = data.email,
                            username = data.username,
                            license = license
                        }
                        TriggerClientEvent('gfm_login:response', src, {
                            success = true,
                            message = "¡Cuenta creada exitosamente! Bienvenido a GamesFiveM.",
                            action = "registered"
                        })
                        print(("[GFM Login] Nueva cuenta registrada: %s (%s)"):format(data.username, data.email))
                    else
                        TriggerClientEvent('gfm_login:response', src, {
                            success = false,
                            message = "Error al crear la cuenta. Intenta de nuevo."
                        })
                    end
                end
            )
        end)
    end)
end)

-- Login existing account
RegisterNetEvent('gfm_login:login')
AddEventHandler('gfm_login:login', function(data)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    
    if not license then
        TriggerClientEvent('gfm_login:response', src, {
            success = false,
            message = "Error: No se pudo verificar tu licencia."
        })
        return
    end

    if not data.email or data.email == '' then
        TriggerClientEvent('gfm_login:response', src, {success = false, message = "El correo es obligatorio."})
        return
    end
    if not data.password or data.password == '' then
        TriggerClientEvent('gfm_login:response', src, {success = false, message = "La contraseña es obligatoria."})
        return
    end

    local hashedPassword = HashPassword(data.password)

    MySQL.query('SELECT * FROM gfm_accounts WHERE email = ? AND password = ?', {data.email, hashedPassword}, function(result)
        if result and #result > 0 then
            local account = result[1]
            
            -- Update license if different (player might have changed PC) and last_login
            MySQL.update('UPDATE gfm_accounts SET license = ?, last_login = NOW() WHERE id = ?', {license, account.id})
            
            loggedInPlayers[src] = {
                id = account.id,
                email = account.email,
                username = account.username,
                license = license
            }

            TriggerClientEvent('gfm_login:response', src, {
                success = true,
                message = "¡Inicio de sesión exitoso! Bienvenido de nuevo, " .. account.username,
                action = "loggedin"
            })
            print(("[GFM Login] Inicio de sesión: %s (%s)"):format(account.username, account.email))
        else
            TriggerClientEvent('gfm_login:response', src, {
                success = false,
                message = "Correo o contraseña incorrectos."
            })
        end
    end)
end)

-- Player wants to play - open multicharacter or identity
RegisterNetEvent('gfm_login:play')
AddEventHandler('gfm_login:play', function()
    local src = source
    
    if not loggedInPlayers[src] then
        TriggerClientEvent('gfm_login:response', src, {
            success = false,
            message = "Debes iniciar sesión primero."
        })
        return
    end

    -- Signal client to close NUI and proceed to character selection
    TriggerClientEvent('gfm_login:startGame', src)
    print(("[GFM Login] Jugador entrando al juego: %s"):format(loggedInPlayers[src].username))
end)

-- Clean up on player drop
AddEventHandler('playerDropped', function(reason)
    local src = source
    if loggedInPlayers[src] then
        print(("[GFM Login] Jugador desconectado: %s - Razón: %s"):format(loggedInPlayers[src].username, reason))
        loggedInPlayers[src] = nil
    end
end)

-- Prevent multicharacter from auto-opening (export check)
-- This makes sure esx_multicharacter waits for our signal
exports('isPlayerLoggedIn', function(playerId)
    return loggedInPlayers[playerId] ~= nil
end)
