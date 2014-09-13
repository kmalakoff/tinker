fs = require 'fs-extra'
path = require 'path'
pwuid = require 'pwuid'

# based on https://github.com/visionmedia/node-github-url-from-git.git
REGEX =
  default: new RegExp(
    /^(?:https?:\/\/|git:\/\/|git\+ssh:\/\/|git\+https:\/\/)?/.source +
    '([0-9A-Za-z-\\.@:%_\+~#=]+)' +
    /[:\/]([^\/]+\/[^\/]+?|[0-9]+)$/.source
  )

  no_auth: new RegExp(
    /^(?:https?:\/\/|git:\/\/|git\+ssh:\/\/|git\+https:\/\/)?(?:[^@]+@)?/.source +
    '([0-9A-Za-z-\\.@:%_\+~#=]+)' +
    /[:\/]([^\/]+\/[^\/]+?|[0-9]+)$/.source
  )

module.exports = class RepoUtils
  @cacheDirectory: -> path.join(pwuid().dir, '.tinker', 'cache')
  @cacheDirectoryEnsure: (callback) -> fs.ensureDir RepoUtils.cacheDirectory(), -> callback()
  @cacheClear: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    fs.remove RepoUtils.cacheDirectory(), -> RepoUtils.cacheDirectoryEnsure(callback)

  @isURL: (url) -> !!RepoUtils.normalizeURL(url)
  @normalizeURL: (url, no_auth) ->
    regex = if no_auth then REGEX.no_auth else REGEX.default
    try return "https://#{match[1]}/#{match[2]}" if match = regex.exec(url?.replace(/\.git(#.*)?$/, '') or '')
