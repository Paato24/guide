local function _hasOxMySQL()
  return GetResourceState('oxmysql') == 'started'
end

local function _assertDb()
  if not _hasOxMySQL() then
    error('[gf_auth] oxmysql no está iniciado. Asegura `ensure oxmysql` antes de gf_auth.')
  end
end

DB = {}

function DB.scalarAwait(query, params)
  _assertDb()
  return MySQL.scalar.await(query, params or {})
end

function DB.singleAwait(query, params)
  _assertDb()
  return MySQL.single.await(query, params or {})
end

function DB.queryAwait(query, params)
  _assertDb()
  return MySQL.query.await(query, params or {})
end

function DB.insertAwait(query, params)
  _assertDb()
  return MySQL.insert.await(query, params or {})
end

function DB.updateAwait(query, params)
  _assertDb()
  return MySQL.update.await(query, params or {})
end

