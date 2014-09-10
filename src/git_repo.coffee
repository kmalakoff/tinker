fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
GitUtils = require './lib/git_utils'
Git = require 'nodegit'

module.exports = class GitRepo extends (require 'backbone').Model
  model_name: 'GitRepo'
  sync: (require 'backbone-orm').sync(GitRepo)

  @load: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    callback()

  clone: (destination, callback) ->
    @ensureCached (err) =>
      return callback(err) if err
      fs.remove destination, (err) =>
        return callback(err) if err
        fs.copy @cacheDirectory(), destination, callback

  ensureCached: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    (console.log "Missing git_url"; return callback()) unless @get('git_url')

    fs.exists @cacheDirectory(), (exists) =>
      return callback() if exists and not options.force

      GitUtils.cacheDirectoryEnsure (err) =>
        return callback(err) if err
        Git.Repo.clone @get('git_url'), @cacheDirectory(), null, (err) => callback(err)

  cacheDirectory: -> path.join(GitUtils.cacheDirectory(), encodeURIComponent(@get('git_url')))
