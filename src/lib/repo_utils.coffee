fs = require 'fs-extra'
path = require 'path'
pwuid = require 'pwuid'
gitURLNormalizer = require 'github-url-from-git'

module.exports = class RepoUtils
  @cacheDirectory: -> path.join(pwuid().dir, '.tinker', 'cache')
  @cacheDirectoryEnsure: (callback) -> fs.ensureDir RepoUtils.cacheDirectory(), -> callback()
  @cacheClear: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    fs.remove RepoUtils.cacheDirectory(), -> RepoUtils.cacheDirectoryEnsure(callback)

  @isURL: (url) -> !!RepoUtils.normalizeURL(url)
  @normalizeURL: (url) -> gitURLNormalizer(url)