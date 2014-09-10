fs = require 'fs-extra'
path = require 'path'
pwuid = require 'pwuid'

module.exports = class GitUtils
  @cacheDirectory: -> path.join(pwuid().dir, '.tinker')
  @ensureCacheDirectory: (callback) -> fs.ensureDir @cacheDirectory(), -> callback()
  @clearCacheDirectory: (callback) -> fs.remove @cacheDirectory(), -> @ensureCacheDirectory(callback)
