# 🎮 GamesFiveM - Sistema de Autenticación

Sistema completo de autenticación para servidores FiveM con ESX Legacy. Interfaz NUI moderna y profesional con registro e inicio de sesión.

![Version](https://img.shields.io/badge/version-1.0.0-orange)
![ESX](https://img.shields.io/badge/ESX-Legacy-blue)
![FiveM](https://img.shields.io/badge/FiveM-Compatible-green)

## 📋 Características

- ✅ **Sistema de Registro Completo**
  - Email único
  - Nombre de usuario personalizado
  - Contraseña segura con hash
  - Selección de nacionalidad

- ✅ **Sistema de Inicio de Sesión**
  - Autenticación por email y contraseña
  - Sesiones persistentes
  - Reconexión automática

- ✅ **Integración con ESX**
  - Compatible con `esx_multicharacter`
  - Compatible con `esx_identity`
  - Abre automáticamente el sistema correcto según tenga personajes

- ✅ **Seguridad**
  - Contraseñas hasheadas
  - Validación de datos en cliente y servidor
  - Protección contra acceso no autorizado
  - Previene carga de personajes sin autenticación

- ✅ **Interfaz Moderna**
  - Diseño responsive
  - Animaciones suaves
  - Efectos visuales atractivos
  - Tema personalizado de GamesFiveM

## 📦 Requisitos

- ESX Legacy (última versión)
- oxmysql o mysql-async
- esx_multicharacter
- esx_identity

## 🚀 Instalación

### 1. Copiar el Recurso

Copia la carpeta `gamesfivem_auth` en tu carpeta de recursos de FiveM:

```
resources/[esx]/gamesfivem_auth/
```

### 2. Instalar Base de Datos

Ejecuta el archivo SQL en tu base de datos:

```bash
mysql -u usuario -p nombre_base_datos < gamesfivem_auth/sql/install.sql
```

O importa el archivo `sql/install.sql` usando phpMyAdmin o similar.

### 3. Agregar el Logo

Coloca tu logo del servidor en:

```
gamesfivem_auth/html/logo.png
```

Recomendaciones:
- Formato: PNG con transparencia
- Tamaño: 512x512 px
- Peso: < 500KB

### 4. Configurar server.cfg

Añade el recurso a tu `server.cfg`:

```lua
ensure gamesfivem_auth
ensure esx_multicharacter
ensure esx_identity
```

**IMPORTANTE:** `gamesfivem_auth` debe cargarse ANTES de `esx_multicharacter` y `esx_identity`.

### 5. Reiniciar el Servidor

Reinicia tu servidor de FiveM o ejecuta:

```
restart gamesfivem_auth
```

## ⚙️ Configuración

### Cambiar el Salt de Contraseñas

Edita `server/server.lua` y cambia esta línea:

```lua
PasswordSalt = "GamesFiveM_2024_SecureHash" -- Cambia esto por tu propia salt
```

**IMPORTANTE:** Hazlo ANTES de que los usuarios se registren. Si cambias el salt después, las contraseñas existentes no funcionarán.

### Personalizar Información del Servidor

Edita `html/index.html` para cambiar:
- Nombre del servidor
- Descripción
- Características destacadas
- Estadísticas del servidor

### Personalizar Colores

Edita `html/style.css` y modifica las variables CSS:

```css
:root {
    --primary-color: #ff6b00;      /* Color principal */
    --accent-color: #ffd700;        /* Color de acento */
    --primary-dark: #e55d00;        /* Color oscuro */
    /* ... más colores ... */
}
```

## 📊 Base de Datos

### Tabla: gamesfivem_users

Almacena los usuarios registrados:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | INT | ID único del usuario |
| email | VARCHAR(255) | Email único |
| password | VARCHAR(255) | Contraseña hasheada |
| username | VARCHAR(50) | Nombre de usuario único |
| nationality | VARCHAR(50) | País del usuario |
| created_at | TIMESTAMP | Fecha de registro |
| last_login | TIMESTAMP | Último inicio de sesión |

### Tabla: gamesfivem_user_identifiers

Vincula identifiers de FiveM con cuentas:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | INT | ID único |
| user_id | INT | FK a gamesfivem_users |
| identifier | VARCHAR(255) | Identifier único de FiveM |
| license | VARCHAR(255) | License de FiveM |
| created_at | TIMESTAMP | Fecha de vinculación |

## 🎯 Uso

### Para Jugadores

1. Al conectar al servidor, aparecerá automáticamente la pantalla de autenticación
2. Si es nuevo:
   - Clic en "Regístrate aquí"
   - Completa el formulario con tus datos
   - Clic en "Crear Cuenta"
3. Si ya tiene cuenta:
   - Ingresa tu email y contraseña
   - Clic en "Iniciar Sesión"
4. Después de autenticarse:
   - Si tienes personajes: se abrirá el selector de personajes
   - Si no tienes personajes: se abrirá el creador de personajes

### Para Administradores

**Ver jugadores autenticados** (solo consola del servidor):

```
authlist
```

**Forzar apertura de UI** (jugador):

```
/auth
```

## 🔒 Seguridad

### Hash de Contraseñas

El sistema utiliza el hash nativo de FiveM con un salt personalizado. Para mayor seguridad en producción, considera implementar bcrypt.

### Validaciones

- **Cliente:** Validación de formato y campos requeridos
- **Servidor:** Validación de datos, verificación de duplicados, sanitización

### Protecciones

- Previene carga de `esx_multicharacter` sin autenticación
- Previene carga de `esx_identity` sin autenticación
- Expulsa jugadores que intenten cargar personajes sin autenticar

## 🐛 Solución de Problemas

### La UI no se abre

1. Verifica que el recurso esté iniciado: `ensure gamesfivem_auth`
2. Revisa la consola F8 del cliente para errores
3. Verifica que ESX esté cargado correctamente

### Errores de Base de Datos

1. Verifica que las tablas se crearon correctamente
2. Comprueba la conexión a MySQL en tu `server.cfg`
3. Revisa los logs del servidor

### No redirige a multicharacter/identity

1. Verifica que `esx_multicharacter` y `esx_identity` estén instalados
2. Asegúrate de que se inicien DESPUÉS de `gamesfivem_auth`
3. Revisa los eventos en `client/client.lua`

### Las contraseñas no funcionan después de cambiar el salt

Esto es normal. Si cambias el salt, debes:
1. Truncar las tablas de usuarios
2. Pedir a los usuarios que se registren nuevamente

## 📝 Comandos

| Comando | Descripción | Permisos |
|---------|-------------|----------|
| `/auth` | Abre la UI de autenticación (si no está autenticado) | Todos |
| `authlist` | Lista jugadores autenticados | Consola del servidor |

## 🎨 Personalización Avanzada

### Añadir Campos al Registro

1. Añade el campo en `html/index.html` en el formulario
2. Añade la columna en la tabla SQL
3. Modifica `server/server.lua` para guardar el nuevo campo
4. Actualiza las validaciones en `html/script.js`

### Cambiar el Sistema de Personajes

Si usas otro sistema diferente a `esx_multicharacter`:

Edita `client/client.lua` y cambia esta línea:

```lua
TriggerEvent('esx_multicharacter:spawnPlayer')
```

Por el evento de tu sistema de personajes.

## 📄 Licencia

Este recurso es de código abierto para GamesFiveM.

## 🤝 Soporte

Para soporte o reportar bugs:
1. Revisa la sección de Solución de Problemas
2. Verifica los logs del servidor y cliente (F8)
3. Contacta al equipo de desarrollo de GamesFiveM

## 📸 Capturas

La interfaz incluye:
- Panel de información con logo y características
- Formulario de inicio de sesión elegante
- Formulario de registro completo
- Animaciones y efectos visuales modernos
- Diseño responsive para todas las resoluciones

## 🔄 Actualizaciones

### v1.0.0 (2024)
- ✅ Lanzamiento inicial
- ✅ Sistema de registro completo
- ✅ Sistema de inicio de sesión
- ✅ Integración con ESX
- ✅ Interfaz NUI moderna
- ✅ Base de datos completa

## 🎮 Sobre GamesFiveM

**GamesFiveM** es el mejor servidor de minijuegos en FiveM, ofreciendo:
- 🎯 Sumo competitivo
- 🤼 Face to Face épico
- 🏎️ Carreras callejeras emocionantes
- 🚀 Mega Rampas extremas
- 🛍️ Tiendas de personalización
- ⚖️ Sin pay-to-win, solo diversión

---

**Desarrollado con ❤️ para la comunidad de GamesFiveM**
