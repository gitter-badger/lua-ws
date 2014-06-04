-- Tests for the extension of `require` to HTTP URLs
-- =================================================

-- These tests depend on `luassert` for assertions.
local assert = require "luassert"

-- Without the extension, a URL cannot be loaded as a Lua module.
assert.has.error (function ()
  require "https://raw.githubusercontent.com/CosyVerif/lang/master/test-data/a_module.lua"
end)

-- With the extension, a URL can be loaded.
assert.has.no.error (function ()
  require "cosy.util.http_require"
  require "https://raw.githubusercontent.com/CosyVerif/lang/master/test-data/a_module.lua"
end)

-- The extended `require` loads effectively the required module.
local remote_module = require "https://raw.githubusercontent.com/CosyVerif/lang/master/test-data/a_module.lua"

-- The distant module and its local equivalent are the same:
assert.are.same (remote_module, {
  a = true,
  b = true,
})