path = require 'path'
_ = require 'underscore'
GitRepo = require './git_repo'
Wrench = require 'wrench'

PROPERTIES = ['name', 'root', 'path', 'url', 'package_url', 'owner']

module.exports = class Module
  constructor: (options) ->
    @[key] = value for key, value of _.pick(options, PROPERTIES)
    throw new Error "Module missing #{key}" for key in PROPERTIES when not @hasOwnProperty(key)
    @repo = new GitRepo({path: @path, url: @url or @package_url})

  on: (callback) ->
    console.log "Tinkering on #{@name} (#{@path.replace("#{@root}/", '')})"
    Wrench.rmdirSyncRecursive(@path, true)
    @repo.clone callback

  off: (callback) ->
    console.log "Tinkering off #{@name} (#{@path.replace("#{@root}/", '')})"
    Wrench.rmdirSyncRecursive(@path, true)
    @owner.installModule @, callback
