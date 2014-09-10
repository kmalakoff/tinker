fs = require 'fs-extra'
path = require 'path'
pwuid = require 'pwuid'

module.exports = class GitUtils
  @cacheDirectory: -> path.join(pwuid().dir, '.tinker', 'cache')
  @cacheDirectoryEnsure: (callback) -> fs.ensureDir GitUtils.cacheDirectory(), -> callback()
  @cacheClear: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    fs.remove GitUtils.cacheDirectory(), -> GitUtils.cacheDirectoryEnsure(callback)
