# GFM Login - Sistema de Cuentas de Jugador

Sistema completo de registro e inicio de sesión para GamesFiveM (ESX Legacy / FiveM).

## Requisitos

- **ESX Legacy** (última versión)
- **oxmysql** (para operaciones de base de datos)
- **esx_multicharacter** (para selección de personajes)
- **esx_identity** (para creación de identidad)

## Instalación

1. **Copia** la carpeta `gfm_login` dentro de tu carpeta `resources/[esx]` o `resources/[local]`.

2. **Importa la base de datos** ejecutando el archivo `sql/install.sql` en tu base de datos MySQL/MariaDB.

3. **Coloca tu logo** en `html/img/logo.png` (recomendado 180x180px, formato PNG con transparencia).

4. **Agrega el recurso** a tu `server.cfg`:
   ```
   ensure gfm_login
   ```
   
   > **IMPORTANTE:** `gfm_login` debe iniciar **ANTES** de `esx_multicharacter` y `esx_identity` en tu `server.cfg`.

5. **Configura esx_multicharacter** para que no se abra automáticamente al conectar. Debes asegurarte de que el evento `esx_multicharacter:open` solo se dispare desde nuestro script.

## Estructura

```
gfm_login/
├── fxmanifest.lua          # Manifiesto del recurso
├── client/
│   └── main.lua            # Lógica del cliente (NUI, eventos)
├── server/
│   └── main.lua            # Lógica del servidor (DB, auth)
├── html/
│   ├── index.html          # Interfaz NUI
│   ├── style.css           # Estilos
│   ├── app.js              # JavaScript del NUI
│   └── img/
│       └── logo.png        # Logo del servidor (coloca el tuyo)
└── sql/
    └── install.sql          # Tabla de la base de datos
```

## Características

- Registro con correo, contraseña, usuario y nacionalidad
- Inicio de sesión con correo y contraseña
- Protección contra duplicados de correo y usuario
- Contraseñas hasheadas
- Integración con esx_multicharacter y esx_identity
- Bloqueo de multicharacter/identity hasta autenticación
- Diseño profesional con animaciones
- Notificaciones en pantalla
- Validación de campos en cliente y servidor
- Soporte de teclado (Enter para enviar)
- Partículas animadas de fondo
