# GamesFiveM Account NUI

Script de autenticacion y creacion de cuenta para ESX Legacy con NUI.

## Requisitos

- ESX Legacy
- oxmysql
- esx_multicharacter
- esx_identity

## Instalacion

1. Importa la tabla en tu base de datos:

```
sql/gf_accounts.sql
```

2. Agrega el recurso en tu `server.cfg` (orden recomendado):

```
ensure oxmysql
ensure es_extended
ensure esx_multicharacter
ensure esx_identity
ensure gamesfivem_account
```

3. En `config.lua` ajusta los eventos si tu multicharacter/identity usan otros nombres.

## Importante

Este script solo dispara `esx_multicharacter` o `esx_identity` despues de pulsar **Jugar**.
Si esos recursos se abren automaticamente al entrar, desactiva su auto-open en sus configs.

## Configuracion de personajes

Por defecto se revisa la tabla `users` con un `LIKE '%identifier%'`.
Si tu estructura es diferente, cambia:

- `Config.CharacterCheck.Table`
- `Config.CharacterCheck.IdentifierColumn`
- `Config.CharacterCheck.LikePattern`

## Seguridad

Las contrasenas se guardan con SHA-256 y un salt aleatorio.
