               require "cosy.util.string"
local ignore = require "cosy.util.ignore"

local global = _G

local Platform = {}

-- Preload
-- =======
if not pcall (function ()
  Platform.i18n = require "i18n"
  Platform.i18n.load { en = require "cosy.i18n.en" }
end) then
  error "Missing dependency"
end

-- Logger
-- ======
Platform.logger = {}
if pcall (function ()
  local logging   = require "logging"
  logging.console = require "logging.console"
  local backend   = logging.console "%level %message\n"
  function Platform.logger.debug (t)
    if Platform.logger.enabled then
      backend:debug (Platform.i18n (t [1], t))
    end
  end
  function Platform.logger.info (t)
    if Platform.logger.enabled then
      backend:info (Platform.i18n (t [1], t))
    end
  end
  function Platform.logger.warning (t)
    if Platform.logger.enabled then
      backend:warn (Platform.i18n (t [1], t))
    end
  end
  function Platform.logger.error (t)
    if Platform.logger.enabled then
      backend:error (Platform.i18n (t [1], t))
    end
  end
end) then
  Platform.logger.enabled = true
  Platform.logger.debug {
    "available_dependency",
    component  = "logger",
    dependency = "lualogging",
  }
elseif pcall (function ()
  local backend = require "log".new ("debug",
    require "log.writer.console.color".new ()
  )
  function Platform.logger.debug (t)
    if Platform.logger.enabled then
      backend.notice (Platform.i18n (t [1], t))
    end
  end
  function Platform.logger.info (t)
    if Platform.logger.enabled then
      backend.info (Platform.i18n (t [1], t))
    end
  end
  function Platform.logger.warning (t)
    if Platform.logger.enabled then
      backend.warning (Platform.i18n (t [1], t))
    end
  end
  function Platform.logger.error (t)
    if Platform.logger.enabled then
      backend.error (Platform.i18n (t [1], t))
    end
  end
end) then
  Platform.logger.enabled = true
  Platform.logger.debug {
    "available_dependency",
    component  = "logger",
    dependency = "lua-log",
  }
else
  function Platform.logger.debug ()
  end
  function Platform.logger.info ()
  end
  function Platform.logger.warning ()
  end
  function Platform.logger.error ()
  end
end

-- Internationalization
-- ====================
if pcall (require, "lfs") then
  local lfs = require "lfs"
  Platform.logger.debug {
    "available_dependency",
    component  = "i18n",
    dependency = "i18n",
  }
  for path in package.path:gmatch "([^;]+)" do
    if path:sub (-5) == "?.lua" then
      path = path:sub (1, #path - 5) .. "cosy/i18n/"
      if lfs.attributes (path, "mode") == "directory" then
        for file in lfs.dir (path) do
          if lfs.attributes (path .. file, "mode") == "file"
          and file:sub (1,1) ~= "." then
            local name = file:gsub (".lua", "")
            Platform.i18n.load { name = require ("cosy.i18n." .. name) }
            Platform.logger.debug {
              "available_locale",
              locale  = name,
            }
          end
        end
      end
    end
  end
else
  Platform.logger.debug {
    "missing_dependency",
    component  = "i18n",
  }
  error "Missing dependency"
end

-- Foreign Function Interface
-- ==========================
--[[
if global.jit then
  Platform.ffi = require "ffi"
  Platform.logger.debug (Platform.i18n ("available_dependency", {
    component  = "ffi",
    dependency = "luajit",
  }))
elseif pcall (function ()
  Platform.ffi = require "luaffi"
end) then
  Platform.logger.debug (Platform.i18n ("available_dependency", {
    component  = "ffi",
    dependency = "luaffi",
  }))
else
  Platform.logger.debug (Platform.i18n ("missing_dependency", {
    component  = "ffi",
  }))
  error "Missing dependency"
end
--]]

-- Unique ID generator
-- ===================
Platform.unique = {}
function Platform.unique.id ()
  error "Not implemented yet"
end
function Platform.unique.uuid ()
  local run    = io.popen ("uuidgen", "r")
  local result = run:read "*l"
  run:close ()
  return result
end

-- Table dump
-- ==========
if pcall (function ()
  local serpent = require "serpent"
  Platform.table = {}
  function Platform.table.encode (t)
    return serpent.dump (t)
  end
  function Platform.table.decode (s)
    return loadstring (s) ()
  end
end) then
  Platform.logger.debug {
    "available_dependency",
    component  = "table dump",
    dependency = "serpent",
  }
else
  Platform.logger.debug {
    "missing_dependency",
    component  = "table dump",
  }
  error "Missing dependency"
end

-- JSON
-- ====
if pcall (function ()
  Platform.json = require "cjson"
end) then
  Platform.logger.debug {
    "available_dependency",
    component  = "json",
    dependency = "cjson",
  }
elseif pcall (function ()
  global.always_try_using_lpeg = true
  Platform.json = require "dkjson"
end) then
  Platform.logger.debug {
    "available_dependency",
    component  = "json",
    dependency = "dkjson+lpeg",
  }
elseif pcall (function ()
  global.always_try_using_lpeg = false
  Platform.json = require "dkjson"
end) then
  Platform.logger.debug {
    "available_dependency",
    component  = "json",
    dependency = "dkjson",
  }
else
  Platform.logger.debug {
    "missing_dependency",
    component  = "JSON",
  }
  error "Missing dependency"
end

-- YAML
-- ====
if pcall (function ()
  local yaml = require "lyaml"
  Platform.yaml = {
    encode = yaml.dump,
    decode = yaml.load,
  }
end) then
  Platform.logger.debug {
    "available_dependency",
    component  = "yaml",
    dependency = "lyaml",
  }
elseif pcall (function ()
  local yaml = require "yaml"
  Platform.yaml = {
    encode = yaml.dump,
    decode = yaml.load,
  }
end) then
  Platform.logger.debug {
    "available_dependency",
    component  = "yaml",
    dependency = "yaml",
  }
elseif pcall (function ()
  local yaml = require "luayaml"
  Platform.yaml = {
    encode = yaml.dump,
    decode = yaml.load,
  }
end) then
  Platform.logger.debug {
    "available_dependency",
    component  = "yaml",
    dependency = "luayaml",
  }
else
  Platform.logger.debug {
    "missing_dependency",
    component  = "yaml",
  }
  error "Missing dependency"
end

-- Compression
-- ===========
Platform.compression = {}

Platform.compression.available = {}
do
  Platform.compression.available.id = {
    compress   = function (x) return x end,
    decompress = function (x) return x end,
  }
  Platform.logger.debug {
    "available_compression",
    compression = "none",
  }
end
ignore (pcall (function ()
  Platform.compression.available.lz4 = require "lz4"
  Platform.logger.debug {
    "available_compression",
    compression = "lz4",
  }
end))
ignore (pcall (function ()
  Platform.compression.available.snappy = require "snappy"
  Platform.logger.debug {
    "available_compression",
    compression = "snappy",
  }
end))

function Platform.compression.format (x)
  return x:match "^(%w+):"
end

function Platform.compression.compress (x, format)
  return format .. ":" .. Platform.Compressions[format].compress (x)
end
function Platform.compression.decompress (x)
  local format = Platform.compression.format (x)
  local Compression = Platform.Compressions[format]
  return Compression
     and Compression.decompress (x:sub (#format+2))
      or error ("Compression format '%{format}' is not available" % {
        format = format,
      })
end

-- Password Hashing
-- ================
Platform.password = {}
Platform.password.computation_time = 0.010 -- milliseconds
if pcall (function ()
  local bcrypt = require "bcrypt"
  local socket = require "socket"
  local function compute_rounds ()
    for _ = 1, 5 do
      local rounds = 5
      while true do
        local start = socket.gettime ()
        bcrypt.digest ("some random string", rounds)
        local delta = socket.gettime () - start
        if delta > Platform.password.computation_time then
          Platform.password.rounds = math.max (Platform.password.rounds or 0, rounds)
          break
        end
        rounds = rounds + 1
      end
    end
    return Platform.password.rounds
  end
  compute_rounds ()
  function Platform.password.hash (password)
    return bcrypt.digest (password, Platform.password.rounds)
  end
  function Platform.password.verify (password, digest)
    return bcrypt.verify (password, digest)
  end
  function Platform.password.is_too_cheap (digest)
    return tonumber (digest:match "%$%w+%$(%d+)%$") < Platform.password.rounds
  end
end) then
  Platform.logger.debug {
    "available_dependency",
    component  = "password hashing",
    dependency = "bcrypt",
  }
  Platform.logger.debug {
    "bcrypt_rounds",
    count = Platform.password.rounds,
    time  = Platform.password.computation_time * 1000,
  }
else
  Platform.logger.debug {
    "missing_dependency",
    component  = "password hashing",
  }
  error "Missing dependency"
end

-- Redis
-- =====
if pcall (function ()
  Platform.redis = require "redis"
end) then
  Platform.logger.debug {
    "available_dependency",
    component  = "redis",
    dependency = "redis-lua",
  }
else
  Platform.logger.debug {
    "missing_dependency",
    component  = "redis",
  }
  error "Missing dependency"
end

-- Configuration
-- =============
Platform.configuration = {}

Platform.configuration.paths = {
  "/etc",
  os.getenv "HOME" .. "/.cosy",
  os.getenv "PWD",
}
function Platform.configuration.read (path)
  local handle = io.open (path, "r")
  if handle ~=nil then
    local content = handle:read "*all"
    io.close (handle)
    return content
  else
    return nil
  end
end

-- Scheduler
-- =========
Platform.scheduler = require "cosy.util.scheduler" .create ()

return Platform