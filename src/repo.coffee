fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
require 'colors'

lockedExec = require './lib/locked_exec'
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
    return callback(new Error "Invalid url: #{@get('url')}") unless url = RepoURL.parse(@get('url'))?.source

    @ensureCached (err) =>
      return callback(err) if err

      lockedExec @lockFile(), callback, (callback) =>
        fs.remove destination, (err) =>
          return callback(err) if err
          fs.copy @cacheDirectory(), destination, callback

  cloneGit: (destination, callback) ->
    return callback(new Error "Invalid url: #{@get('url')}") unless url = RepoURL.parse(@get('url'))?.source

    fs.exists destination, (exists) =>
      # only clone the .git and .gitignore files
      if exists
        queue = new Queue(1)
        queue.defer (callback) => @ensureCached(callback)
        queue.defer (callback) => @updateDestination(destination, callback)
        queue.await callback

      else
        return @clone(destination, callback)

  updateDestination: (destination, callback) ->
    lockedExec @lockFile(), callback, (callback) =>

      queue = new Queue(1)
      queue.defer (callback) =>
        url_parts = RepoURL.parse(@get('url'))
        return callback(new Error "Invalid url: #{@get('url')}") unless url = url_parts?.source
        spawn "git checkout #{url_parts?.target or 'master'}", {cwd: @cacheDirectory(), silent: true}, callback
      queue.defer (callback) => fs.copy path.join(@cacheDirectory(), '.git'), path.join(destination, '.git'), callback
      queue.defer (callback) => fs.copy path.join(@cacheDirectory(), '.gitignore'), path.join(destination, '.gitignore'), -> callback()
      queue.await callback

  ensureCached: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    return callback(new Error "Invalid url: #{@get('url')}") unless url = RepoURL.parse(@get('url'))?.source

    fs.exists @cacheDirectory(), (exists) =>
      return callback() if exists and not options.force

      lockedExec @lockFile(), callback, (callback) =>
        queue = new Queue(1)
        queue.defer (callback) => RepoUtils.cacheDirectoryEnsure(callback)
        queue.defer (callback) => fs.exists @cacheDirectory(), (exists) =>
          return callback() if exists
          spawn "git clone #{url} #{@cacheDirectory()}", callback
        queue.await (err) =>
          return callback() unless err

          # clean up failed install
          return fs.remove @cacheDirectory(), (remove_err) =>
            console.log "Failed to remove git directory: #{@cacheDirectory()}.\nYou should run 'tinker cache clear' to ensure the cache is not corrupted".red
            callback(err)

  cacheDirectory: -> path.join(RepoUtils.cacheDirectory(), encodeURIComponent(RepoURL.parse(@get('url'))?.source))
  lockFile: -> "#{@cacheDirectory()}.lock"
