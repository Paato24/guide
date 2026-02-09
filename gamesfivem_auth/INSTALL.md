# 🚀 Guía de Instalación Rápida - GamesFiveM Auth

## Instalación en 5 Minutos

### 1️⃣ Copiar el Recurso

```bash
# Copia la carpeta gamesfivem_auth a tu servidor
cp -r gamesfivem_auth /ruta/tu/servidor/resources/[esx]/
```

### 2️⃣ Instalar Base de Datos

Ejecuta el archivo SQL en tu base de datos:

```sql
-- Opción 1: Desde MySQL CLI
mysql -u root -p tu_base_datos < gamesfivem_auth/sql/install.sql

-- Opción 2: Copia y pega el contenido del archivo en phpMyAdmin
```

### 3️⃣ Agregar Logo

```bash
# Copia tu logo a la carpeta html
cp tu_logo.png gamesfivem_auth/html/logo.png
```

**Importante:** El logo debe ser PNG, 512x512px, y menos de 500KB.

### 4️⃣ Configurar server.cfg

Añade al final de tu `server.cfg`:

```cfg
# Sistema de Autenticación
ensure gamesfivem_auth
```

**IMPORTANTE:** Debe estar ANTES de estos recursos:

```cfg
ensure gamesfivem_auth  # ← PRIMERO
ensure esx_multicharacter
ensure esx_identity
```

### 5️⃣ Configurar Seguridad

Edita `gamesfivem_auth/server/server.lua` línea 6:

```lua
PasswordSalt = "TU_SALT_SUPER_SECRETO_AQUI_2024"
```

⚠️ **MUY IMPORTANTE:** Hazlo ANTES de que alguien se registre.

### 6️⃣ Iniciar el Servidor

```bash
# Reinicia tu servidor o ejecuta:
restart gamesfivem_auth
```

## ✅ Verificar Instalación

### En la Consola del Servidor

Deberías ver:

```
[GamesFiveM Auth] Sistema de autenticación cargado correctamente
```

### En el Cliente (F8)

Deberías ver:

```
[GamesFiveM Auth] Cliente cargado correctamente
```

### Probar el Sistema

1. Conéctate al servidor
2. Deberías ver la pantalla de autenticación automáticamente
3. Intenta registrarte con un email de prueba
4. Verifica que se guarde en la base de datos

## 🗄️ Verificar Base de Datos

```sql
-- Ver usuarios registrados
SELECT * FROM gamesfivem_users;

-- Ver identifiers vinculados
SELECT * FROM gamesfivem_user_identifiers;
```

## ⚙️ Configuración Opcional

### Personalizar Colores

Edita `gamesfivem_auth/html/style.css`:

```css
:root {
    --primary-color: #ff6b00;  /* Tu color principal */
    --accent-color: #ffd700;    /* Tu color de acento */
}
```

### Personalizar Información

Edita `gamesfivem_auth/html/index.html`:

- Línea 34: Nombre del servidor
- Línea 38: Descripción
- Líneas 42-67: Características del servidor

### Cambiar Minijuegos Mostrados

Edita `gamesfivem_auth/html/index.html` sección de features:

```html
<div class="feature-item">
    <div class="feature-icon">🎯</div>
    <div class="feature-text">
        <h3>Tu Minijuego</h3>
        <p>Descripción del minijuego</p>
    </div>
</div>
```

## 🔧 Comandos Útiles

```bash
# Reiniciar solo el recurso
restart gamesfivem_auth

# Ver logs en tiempo real
tail -f server.log | grep GamesFiveM

# Comprobar recursos cargados
ensure gamesfivem_auth
```

## 🆘 Solución de Problemas Rápida

### La UI no aparece

```lua
-- En F8 del cliente, ejecuta:
/auth
```

### Error de base de datos

```bash
# Verifica que oxmysql esté instalado
ensure oxmysql
```

### No redirige a multicharacter

Verifica el orden en `server.cfg`:

```cfg
ensure gamesfivem_auth     # ← DEBE SER PRIMERO
ensure esx_multicharacter  # ← SEGUNDO
ensure esx_identity        # ← TERCERO
```

## 📞 Soporte

Si tienes problemas:

1. ✅ Revisa los logs del servidor
2. ✅ Revisa F8 en el cliente
3. ✅ Verifica que las tablas SQL se crearon
4. ✅ Confirma el orden de recursos en server.cfg
5. ✅ Lee el README.md completo

## 🎉 ¡Listo!

Tu sistema de autenticación está instalado y funcionando.

**¡Bienvenido a GamesFiveM!** 🎮
