# gf_auth (GamesFiveM)

Recurso NUI para creación de cuenta e inicio de sesión, pensado para ESX Legacy.

Objetivo principal: `esx_multicharacter` y `esx_identity` NO deben abrirse antes de que el jugador pulse **Jugar** tras autenticarse.

## Requisitos

- `oxmysql` iniciado antes que este recurso.
- ESX Legacy (última versión).
- Si usas `esx_multicharacter` y `esx_identity`, deben quedar “guardados” para que no disparen su UI automáticamente.

## Instalación

- Copia `fivem/resources/[games]/gf_auth` a tu carpeta `resources/[games]/gf_auth` del servidor.
- En tu `server.cfg` asegúrate del orden:
  - `ensure oxmysql`
  - `ensure gf_auth`
  - `ensure es_extended`
  - `ensure esx_multicharacter`
  - `ensure esx_identity`

La tabla de cuentas se crea automáticamente al arrancar. Si prefieres crearla manualmente, usa `sql/gf_accounts.sql`.

## Flujo

- Al entrar, el jugador ve el panel NUI de GamesFiveM con:
  - info del servidor
  - pestañas: iniciar sesión / registrarse
- Registro: correo, contraseña, nombre de usuario y nacionalidad (se guarda en MySQL).
- Login: correo y contraseña.
- Tras autenticarse, se habilita el botón **Jugar**.
- Solo al pulsar **Jugar** se dispara el flujo ESX:
  - si el jugador ya tiene personajes, abre `esx_multicharacter`
  - si no tiene, abre `esx_identity` (fallback)

## MUY IMPORTANTE (bloquear auto-apertura de ESX)

Para garantizar “bajo ninguna circunstancia”, debes añadir un check al inicio del punto donde `esx_multicharacter` o `esx_identity` abren su UI automáticamente.

Este recurso expone:

- `exports['gf_auth']:CanOpenESX(source)` (server) devuelve true solo después de pulsar **Jugar**
- `exports['gf_auth']:IsAuthenticated(source)` (server) devuelve true cuando el jugador inició sesión/registró

### Parche sugerido para esx_multicharacter (server)

En el handler que se ejecuta al entrar y/o el que lanza el menú de personajes (normalmente `SetupCharacters` o similar), agrega:

- si `exports['gf_auth']:CanOpenESX(source)` es false, entonces return (no abrir nada)

### Parche sugerido para esx_identity (client o server)

En el punto donde el recurso muestra el formulario de identidad automáticamente al cargar jugador:

- si `exports['gf_auth']:CanOpenESX(source)` es false (server) o si el server no lo permite, no abras la UI

Nota: la ubicación exacta de estos checks depende de tu versión de ESX, pero la regla es siempre la misma: si no hay “Jugar”, no hay UI.

