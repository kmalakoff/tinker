fs = require 'fs-extra'
path = require 'path'
pwuid = require 'pwuid'
RepoURL = require './repo_url'

module.exports = class RepoUtils
  @cacheDirectory: -> path.join(pwuid().dir, '.tinker', 'cache')
  @cacheDirectoryEnsure: (callback) -> fs.ensureDir RepoUtils.cacheDirectory(), -> callback()
  @cacheClear: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    fs.remove RepoUtils.cacheDirectory(), -> RepoUtils.cacheDirectoryEnsure(callback)
