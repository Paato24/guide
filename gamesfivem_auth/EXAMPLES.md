# 📚 Ejemplos de Uso - GamesFiveM Auth

## 🎯 Ejemplos para Usuarios

### Ejemplo 1: Registro de Nuevo Usuario

1. **Conectar al servidor**
   - Se abre automáticamente la pantalla de autenticación

2. **Hacer clic en "Regístrate aquí"**

3. **Completar el formulario:**
   - Email: `jugador@gmail.com`
   - Usuario: `MegaGamer123`
   - Contraseña: `miPassword123`
   - Confirmar: `miPassword123`
   - País: `🇲🇽 México`

4. **Clic en "Crear Cuenta"**

5. **Resultado:**
   - ✅ Mensaje: "¡Cuenta creada exitosamente! Bienvenido, MegaGamer123!"
   - Se abre automáticamente el creador de personajes (esx_identity)

### Ejemplo 2: Inicio de Sesión

1. **Conectar al servidor**
   - Se abre automáticamente la pantalla de autenticación

2. **Completar el formulario de login:**
   - Email: `jugador@gmail.com`
   - Contraseña: `miPassword123`

3. **Clic en "Iniciar Sesión"**

4. **Resultado:**
   - ✅ Mensaje: "¡Bienvenido de vuelta, MegaGamer123!"
   - Se abre el selector de personajes (esx_multicharacter)

### Ejemplo 3: Reconexión Automática

1. **Usuario ya registrado se desconecta y reconecta**

2. **Resultado:**
   - No necesita autenticarse nuevamente
   - Se abre directamente el selector de personajes
   - Sesión reconocida automáticamente

## 💻 Ejemplos para Desarrolladores

### Ejemplo 1: Verificar si un Jugador está Autenticado

```lua
-- En cualquier recurso del servidor
ESX.RegisterServerCallback('mi_recurso:hacerAlgo', function(source, cb)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    
    -- Verificar si existe en gamesfivem_user_identifiers
    MySQL.Async.fetchScalar('SELECT user_id FROM gamesfivem_user_identifiers WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(userId)
        if userId then
            -- Usuario autenticado
            cb({authenticated = true, userId = userId})
        else
            -- Usuario NO autenticado
            cb({authenticated = false})
        end
    end)
end)
```

### Ejemplo 2: Obtener Datos del Usuario Autenticado

```lua
-- En el servidor
ESX.RegisterServerCallback('mi_recurso:getUserData', function(source, cb)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    
    MySQL.Async.fetchAll('SELECT u.* FROM gamesfivem_users u INNER JOIN gamesfivem_user_identifiers ui ON u.id = ui.user_id WHERE ui.identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] then
            cb({
                username = result[1].username,
                email = result[1].email,
                nationality = result[1].nationality,
                created_at = result[1].created_at,
                last_login = result[1].last_login
            })
        else
            cb(nil)
        end
    end)
end)
```

### Ejemplo 3: Agregar un Campo Personalizado

**Paso 1: Modificar la base de datos**

```sql
ALTER TABLE gamesfivem_users ADD COLUMN discord VARCHAR(100) NULL;
```

**Paso 2: Añadir el campo en el HTML**

```html
<!-- En html/index.html, dentro del formulario de registro -->
<div class="input-group">
    <label for="register-discord">Discord (Opcional)</label>
    <div class="input-wrapper">
        <span class="input-icon">💬</span>
        <input type="text" id="register-discord" name="discord" placeholder="Usuario#1234">
    </div>
</div>
```

**Paso 3: Capturar el dato en el JavaScript**

```javascript
// En html/script.js, en el handler del formulario de registro
const discord = document.getElementById('register-discord').value.trim();

// Añadir al objeto que se envía
const response = await sendToClient('register', {
    email: email,
    username: username,
    password: password,
    nationality: nationality,
    discord: discord // ← Nuevo campo
});
```

**Paso 4: Guardar en el servidor**

```lua
-- En server/server.lua, en la callback de registro
MySQL.Async.insert('INSERT INTO gamesfivem_users (email, password, username, nationality, discord) VALUES (@email, @password, @username, @nationality, @discord)', {
    ['@email'] = data.email,
    ['@password'] = hashedPassword,
    ['@username'] = data.username,
    ['@nationality'] = data.nationality,
    ['@discord'] = data.discord -- ← Nuevo campo
}, function(userId)
    -- ... resto del código
end)
```

### Ejemplo 4: Evento Personalizado al Registrarse

```lua
-- En server/server.lua, después de un registro exitoso

-- Disparar evento personalizado
TriggerEvent('gamesfivem_auth:playerRegistered', source, {
    userId = userId,
    username = data.username,
    email = data.email,
    nationality = data.nationality
})

-- En otro recurso, escuchar el evento
AddEventHandler('gamesfivem_auth:playerRegistered', function(source, userData)
    print('Nuevo usuario registrado: ' .. userData.username)
    
    -- Dar bienvenida especial
    TriggerClientEvent('chat:addMessage', source, {
        color = {255, 107, 0},
        multiline = true,
        args = {"GamesFiveM", "¡Bienvenido " .. userData.username .. "! Disfruta nuestros minijuegos."}
    })
    
    -- Dar dinero inicial (ejemplo)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.addMoney(5000)
    end
end)
```

### Ejemplo 5: Webhook de Discord al Registrarse

```lua
-- En server/server.lua, después de un registro exitoso

local function sendDiscordWebhook(username, email, nationality)
    local webhook = "TU_WEBHOOK_URL_AQUI"
    
    local embed = {
        {
            ["color"] = 16744192, -- Naranja
            ["title"] = "🎮 Nuevo Registro en GamesFiveM",
            ["description"] = "Un nuevo jugador se ha registrado",
            ["fields"] = {
                {
                    ["name"] = "👤 Usuario",
                    ["value"] = username,
                    ["inline"] = true
                },
                {
                    ["name"] = "📧 Email",
                    ["value"] = email,
                    ["inline"] = true
                },
                {
                    ["name"] = "🌍 País",
                    ["value"] = nationality,
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "GamesFiveM Auth System"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = "GamesFiveM Auth",
        embeds = embed
    }), {['Content-Type'] = 'application/json'})
end

-- Llamar después del registro
sendDiscordWebhook(data.username, data.email, data.nationality)
```

### Ejemplo 6: Bloquear Recurso si No está Autenticado

```lua
-- En cualquier recurso que quieras proteger

RegisterNetEvent('mi_recurso:hacerAlgo')
AddEventHandler('mi_recurso:hacerAlgo', function()
    local _source = source
    local identifier = GetPlayerIdentifierByType(_source, 'license')
    
    -- Verificar autenticación
    MySQL.Async.fetchScalar('SELECT user_id FROM gamesfivem_user_identifiers WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(userId)
        if not userId then
            -- No autenticado
            TriggerClientEvent('esx:showNotification', _source, '~r~Debes autenticarte primero')
            return
        end
        
        -- Autenticado, continuar con la lógica
        -- ... tu código aquí
    end)
end)
```

## 🔧 Ejemplos para Administradores

### Ejemplo 1: Ver Usuarios Registrados

```sql
-- Consulta SQL para ver todos los usuarios
SELECT 
    u.id,
    u.username,
    u.email,
    u.nationality,
    u.created_at,
    u.last_login,
    COUNT(users.identifier) as personajes
FROM gamesfivem_users u
LEFT JOIN gamesfivem_user_identifiers ui ON u.id = ui.user_id
LEFT JOIN users ON ui.identifier = users.identifier
GROUP BY u.id
ORDER BY u.created_at DESC;
```

### Ejemplo 2: Buscar Usuario por Email

```sql
-- Buscar un usuario específico
SELECT * FROM gamesfivem_users WHERE email = 'jugador@gmail.com';
```

### Ejemplo 3: Ver Usuarios Online

```bash
# En la consola del servidor
authlist
```

### Ejemplo 4: Eliminar una Cuenta (con precaución)

```sql
-- PRECAUCIÓN: Esto eliminará la cuenta y todos sus personajes
DELETE FROM gamesfivem_users WHERE email = 'jugador@gmail.com';
-- Los identifiers y personajes vinculados se eliminarán automáticamente por CASCADE
```

### Ejemplo 5: Resetear Contraseña Manualmente

```lua
-- Ejecuta esto en la consola del servidor para generar un hash
-- Cambia "nuevaPassword123" por la contraseña que quieras

local password = "nuevaPassword123"
local salt = "GamesFiveM_2024_SecureHash" -- Usa tu salt configurado
local hash = GetPasswordHash(password, salt)
print("Hash: " .. hash)
```

Luego ejecuta en SQL:

```sql
UPDATE gamesfivem_users 
SET password = 'HASH_GENERADO_AQUI' 
WHERE email = 'jugador@gmail.com';
```

### Ejemplo 6: Estadísticas de Registros

```sql
-- Registros por día (últimos 30 días)
SELECT 
    DATE(created_at) as fecha,
    COUNT(*) as registros
FROM gamesfivem_users
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(created_at)
ORDER BY fecha DESC;

-- Registros por país
SELECT 
    nationality,
    COUNT(*) as total
FROM gamesfivem_users
GROUP BY nationality
ORDER BY total DESC;

-- Total de usuarios registrados
SELECT COUNT(*) as total_usuarios FROM gamesfivem_users;
```

## 🎨 Ejemplos de Personalización

### Ejemplo 1: Cambiar Colores

```css
/* En html/style.css */
:root {
    --primary-color: #00ff88;      /* Verde neón */
    --accent-color: #00d4ff;       /* Azul cyan */
    --primary-dark: #00cc6f;       /* Verde oscuro */
}
```

### Ejemplo 2: Cambiar Texto de Bienvenida

```html
<!-- En html/index.html -->
<h2 class="welcome-title">¡Únete a la Acción!</h2>
<p class="server-description">
    El servidor más <strong>épico</strong> de GTA V
</p>
```

### Ejemplo 3: Añadir más Países

```html
<!-- En html/index.html, dentro del select -->
<option value="FR">🇫🇷 Francia</option>
<option value="IT">🇮🇹 Italia</option>
<option value="DE">🇩🇪 Alemania</option>
```

### Ejemplo 4: Cambiar Requisitos de Contraseña

```lua
-- En server/server.lua
if string.len(data.password) < 8 then -- Cambiar a 8 caracteres mínimo
    cb({success = false, message = 'La contraseña debe tener al menos 8 caracteres'})
    return
end
```

```javascript
// En html/script.js
if (password.length < 8) {
    showMessage('register', 'error', 'La contraseña debe tener al menos 8 caracteres');
    return;
}
```

## 🐛 Ejemplos de Debugging

### Ejemplo 1: Debug en Cliente

```lua
-- En client/client.lua, al inicio
local DEBUG = true

-- Añadir logs de debug
if DEBUG then
    print('[DEBUG] isAuthenticated: ' .. tostring(isAuthenticated))
    print('[DEBUG] hasCheckedAuth: ' .. tostring(hasCheckedAuth))
end
```

### Ejemplo 2: Debug en Servidor

```lua
-- En server/server.lua, en la callback de login
print('[DEBUG] Intentando login:')
print('  Email: ' .. data.email)
print('  Identifier: ' .. identifier)

-- Después de la consulta
print('[DEBUG] Resultado de consulta: ' .. json.encode(result))
```

### Ejemplo 3: Ver Errores SQL

```lua
-- Modificar consultas para mostrar errores
MySQL.Async.fetchAll('SELECT * ...', {}, function(result)
    if not result then
        print('[ERROR] Consulta SQL falló')
        return
    end
    print('[DEBUG] Resultado: ' .. json.encode(result))
end)
```

## 📞 Ejemplos de Integración

### Ejemplo 1: Integración con Sistema de Niveles

```lua
-- Al registrarse, crear entrada en tabla de niveles
AddEventHandler('gamesfivem_auth:playerRegistered', function(source, userData)
    MySQL.Async.insert('INSERT INTO player_levels (user_id, level, xp) VALUES (@user_id, 1, 0)', {
        ['@user_id'] = userData.userId
    })
end)
```

### Ejemplo 2: Integración con Sistema de Economía

```lua
-- Dar dinero inicial al primer personaje
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    -- Verificar si es su primer personaje
    local identifier = xPlayer.identifier
    
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM users WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(count)
        if count == 1 then
            -- Primer personaje, dar dinero inicial
            xPlayer.addMoney(10000)
            xPlayer.addAccountMoney('bank', 50000)
            TriggerClientEvent('esx:showNotification', playerId, 'Bono de bienvenida: $10,000 + $50,000 en banco')
        end
    end)
end)
```

---

**¿Necesitas más ejemplos? Revisa el código fuente, está bien comentado y es fácil de entender** 📚
