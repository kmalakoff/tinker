fs = require 'fs'
path = require 'path'
_ = require 'underscore'
GitRepo = require './git_repo'
Wrench = require 'wrench'
colors = require 'colors'

PROPERTIES = ['name', 'root', 'path', 'url', 'package_url', 'owner']

module.exports = class Module
  constructor: (options) ->
    @[key] = value for key, value of _.pick(options, PROPERTIES)
    throw new Error "Module missing #{key}" for key in PROPERTIES when not @hasOwnProperty(key)
    @repo = new GitRepo({path: @path, url: @url or @package_url})

  on: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    console.log "Tinkering on #{@name} (#{@relativePath()})"

    @isInstalled true, (err, is_installed) =>
      return callback(err) if err
      if is_installed
        if options.force
          console.log "Git #{@name} exists in #{@relativePath()}. Forcing".yellow
        else
          (console.log "Git #{@name} exists in #{@relativePath()}. Skipping".green; return callback())

      Wrench.rmdirSyncRecursive(@path, true)
      @repo.clone callback

  off: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    console.log "Tinkering off #{@name} (#{@relativePath()})"

    @isInstalled false, (err, is_installed) =>
      return callback(err) if err
      if is_installed
        if options.force
          console.log "Module #{@name} exists in #{@relativePath()}. Forcing".yellow
        else
          (console.log "Module #{@name} exists in #{@relativePath()}. Skipping".green; return callback())

      Wrench.rmdirSyncRecursive(@path, true)
      @owner.installModule @, callback

  relativePath: -> @path.replace("#{@root}/", '')
  isInstalled: (git, callback) ->
    fs.exists path.join(@path, '.git'), (exists) =>
      return callback(null, exists) if git
      return callback(null, false) if exists
      fs.exists @path, (exists) => callback(null, exists)
