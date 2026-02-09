Config = {}

Config.ServerName = 'GamesFiveM'
Config.Tagline = 'Servidor dedicado a minijuegos'

Config.AboutParagraph = [[
Bienvenido a GamesFiveM: un servidor dedicado 100% a minijuegos.
Sumo, Face to Face, Carreras Callejeras, Mega Rampas, Carreras y mucho más.
Contamos con tiendas con mejoras estéticas: nada de pay to win.
]]

-- NUI / UX
Config.ShowOnJoin = true
Config.MinPasswordLength = 6
Config.MaxPasswordLength = 72

-- Anti-spam básico (ms) por acción
Config.ActionCooldownMs = 1200

-- Routing bucket mientras está en login (para aislarlo del mundo)
Config.UseRoutingBucket = true
Config.RoutingBucketBase = 7000 -- se suma el playerId

-- DB
Config.TableName = 'gf_accounts'

-- Integración ESX
-- Si tienes `esx_multicharacter` y `esx_identity`, el flujo se dispara al pulsar "Jugar".
-- Para que NO se abran antes, aplica los parches recomendados en `README.md` del recurso.
Config.MulticharacterResource = 'esx_multicharacter'
Config.IdentityResource = 'esx_identity'

