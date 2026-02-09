Config = {}

Config.Debug = false

Config.Validation = {
  MinPasswordLength = 6,
  MaxPasswordLength = 64,
  MinUsernameLength = 3,
  MaxUsernameLength = 24,
  MaxNationalityLength = 32
}

Config.Database = {
  AccountTable = 'gf_accounts'
}

Config.CharacterCheck = {
  Enabled = true,
  Table = 'users',
  IdentifierColumn = 'identifier',
  -- Se busca el identifier en la columna con LIKE '%identifier%'
  -- Ajusta esto si tu multicharacter usa otra estructura.
  LikePattern = '%%%s%%',
  -- Si falla la consulta, se abrira multicharacter por seguridad.
  FallbackToMulticharacter = true
}

Config.Multicharacter = {
  Event = 'esx_multicharacter:openUI',
  EventSide = 'server'
}

Config.Identity = {
  Event = 'esx_identity:showRegisterIdentity',
  EventSide = 'client'
}
