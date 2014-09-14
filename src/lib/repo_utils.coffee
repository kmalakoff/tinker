fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
path = require 'path-extra'
require 'colors'

lockedExec = require './locked_exec'
RepoURL = require './repo_url'
spawn = require './spawn'

module.exports = class RepoUtils
  @cacheClear: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    fs.remove RepoUtils.cacheDirectory(), callback

  @cacheDirectory: (url) ->
    if url
      path.join(path.homedir(), '.tinker', 'cache', encodeURIComponent(RepoURL.parse(url)?.source))
    else
      path.join(path.homedir(), '.tinker', 'cache')

  @lockFile: (url) -> "#{RepoUtils.cacheDirectory()}.lock"

  @clone: (url, destination, callback) ->
    return callback(new Error "Invalid url: #{url}") unless url = RepoURL.parse(url)?.source
    cache_directory = RepoUtils.cacheDirectory(url)

    @ensureCached url, (err) =>
      return callback(err) if err

      lockedExec RepoUtils.lockFile(url), callback, (callback) =>
        fs.remove destination, (err) =>
          return callback(err) if err
          fs.copy cache_directory, destination, callback

  @cloneGit: (url, destination, callback) ->
    return callback(new Error "Invalid url: #{url}") unless url = RepoURL.parse(url)?.source

    fs.exists destination, (exists) =>
      # only clone the .git and .gitignore files
      if exists
        queue = new Queue(1)
        queue.defer (callback) => RepoUtils.ensureCached(url, callback)
        queue.defer (callback) => RepoUtils.updateDestination(url, destination, callback)
        queue.await callback

      else
        return RepoUtils.clone(destination, callback)

  @updateDestination: (url, destination, callback) ->
    lockedExec RepoUtils.lockFile(url), callback, (callback) =>
      cache_directory = RepoUtils.cacheDirectory(url)

      queue = new Queue(1)
      queue.defer (callback) =>
        url_parts = RepoURL.parse(url)
        return callback(new Error "Invalid url: #{url}") unless url = url_parts?.source
        spawn "git checkout #{url_parts?.target or 'master'}", {cwd: cache_directory, silent: true}, callback
      queue.defer (callback) => fs.copy path.join(cache_directory, '.git'), path.join(destination, '.git'), callback
      queue.defer (callback) => fs.copy path.join(cache_directory, '.gitignore'), path.join(destination, '.gitignore'), -> callback()
      queue.await callback

  @ensureCached: (url, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    return callback(new Error "Invalid url: #{url}") unless url = RepoURL.parse(url)?.source
    cache_directory = RepoUtils.cacheDirectory(url)

    lockedExec RepoUtils.lockFile(url), callback, (callback) =>
      queue = new Queue(1)
      queue.defer (callback) => fs.exists cache_directory, (exists) =>
        if exists
          console.log "Fetching lastest from #{url}"
          spawn 'git fetch --all', {cwd: cache_directory, silent: true}, callback
        else
          spawn "git clone #{url} #{cache_directory}", callback
      queue.await (err) =>
        return callback() unless err

        # clean up failed install
        return fs.remove cache_directory, (remove_err) =>
          console.log "Failed to remove git directory: #{cache_directory}.\nYou should run 'tinker cache clear' to ensure the cache is not corrupted".red
          callback(err)
