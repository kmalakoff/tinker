fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
GitUtils = require './lib/git_utils'
gitURLNormalizer = require 'github-url-from-git'
spawn = require './lib/spawn'

module.exports = class GitRepo extends (require 'backbone').Model
  model_name: 'GitRepo'
  sync: (require 'backbone-orm').sync(GitRepo)

  @load: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    callback()

  clone: (destination, callback) ->
    (console.log 'Missing git_url'; return callback()) unless @gitURL()

    @ensureCached (err) =>
      return callback(err) if err

      fs.remove destination, (err) =>
        return callback(err) if err
        fs.copy @cacheDirectory(), destination, callback

  cloneGit: (destination, callback) ->
    (console.log 'Missing git_url'; return callback()) unless @gitURL()

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
    (console.log 'Missing git_url'; return callback()) unless @gitURL()

    fs.exists @cacheDirectory(), (exists) =>
      return callback() if exists and not options.force

      GitUtils.cacheDirectoryEnsure (err) =>
        return callback(err) if err
        spawn "git clone #{@gitURL()} #{@cacheDirectory()}", (err) => callback(err)

  cacheDirectory: -> path.join(GitUtils.cacheDirectory(), encodeURIComponent(@gitURL()))
  gitURL: ->
    return unless url = @get('git_url')
    url = gitURLNormalizer(url) or url
    url = url.split('#').shift() if url.indexOf('#')
    return url
