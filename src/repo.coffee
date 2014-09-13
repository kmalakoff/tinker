fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
RepoUtils = require './lib/repo_utils'
RepoURL = require './lib/repo_url'
spawn = require './lib/spawn'

module.exports = class GitRepo extends (require 'backbone').Model
  model_name: 'GitRepo'
  sync: (require 'backbone-orm').sync(GitRepo)

  @load: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    callback()

  clone: (destination, callback) ->
    (console.log 'Missing url'; return callback()) unless @repoURL()

    @ensureCached (err) =>
      return callback(err) if err

      fs.remove destination, (err) =>
        return callback(err) if err
        fs.copy @cacheDirectory(), destination, callback

  cloneGit: (destination, callback) ->
    (console.log 'Missing url'; return callback()) unless @repoURL()

    fs.exists destination, (exists) =>
      # only clone the .git and .gitignore files
      if exists
        @ensureCached (err) =>
          return callback(err) if err

          queue = new Queue()
          queue.defer (callback) => fs.copy path.join(@cacheDirectory(), '.git'), path.join(destination, '.git'), callback
          queue.defer (callback) => fs.copy path.join(@cacheDirectory(), '.gitignore'), path.join(destination, '.gitignore'), -> callback()
          queue.await callback

      else
        return @clone(destination, callback)

  ensureCached: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    (console.log 'Missing url'; return callback()) unless @repoURL()

    fs.exists @cacheDirectory(), (exists) =>
      return callback() if exists and not options.force

      RepoUtils.cacheDirectoryEnsure (err) =>
        return callback(err) if err
        spawn "git clone #{@repoURL()} #{@cacheDirectory()}", (err) => callback(err)

  cacheDirectory: -> path.join(RepoUtils.cacheDirectory(), encodeURIComponent(@repoURL()))
  repoURL: ->
    return unless url = @get('url')
    url = RepoURL.normalize(url) or url
    url = url.split('#').shift() if url.indexOf('#')
    return url
