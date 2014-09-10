fs = require 'fs'
path = require 'path'
_ = require 'underscore'
minimatch = require 'minimatch'
rimraf = require 'rimraf'
colors = require 'colors'

GitRepo = require '../git/repo'
Package = null

module.exports = class Module extends (require 'backbone').Model
  model_name: 'Module'
  schema:
    package: -> ['belongsTo', Package = require './package']
  sync: (require 'backbone-orm').sync(Module)

  @findByGlob: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2

    Module.cursor({'package.type': {$in: _.pluck(Package.optionsToTypes(options), 'type')}}).toModels (err, modules) ->
      return callback(err) if err
      callback(null, (module for module in modules when minimatch(module.get('name'), glob)))

  tinkerOn: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    console.log "Tinkering on #{@get('name')} (#{@relativePath()})"

    @isInstalled true, (err, is_installed) =>
      return callback(err) if err
      if is_installed
        if options.force
          console.log "Git: #{@get('name')} exists in #{@relativePath()}. Forcing".yellow
        else
          (console.log "Git: #{@get('name')} exists in #{@relativePath()}. Skipping".green; return callback())

      rimraf @get('path'), (err) =>
        return callback(err) if err
        new GitRepo({path: @get('path'), url: @get('git_url')}).clone callback

  tinkerOff: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    console.log "Tinkering off #{@get('name')} (#{@relativePath()})"

    @isInstalled false, (err, is_installed) =>
      return callback(err) if err
      if is_installed
        if options.force
          console.log "Module: #{@get('name')} exists in #{@relativePath()}. Forcing".yellow
        else
          (console.log "Module: #{@get('name')} exists in #{@relativePath()}. Skipping".green; return callback())

      Wrench.rmdirSyncRecursive(@get('path'), true)
      @owner.installModule @, callback

  relativePath: -> @get('path').replace("#{@get('root')}/", '')
  isInstalled: (git, callback) ->
    fs.exists path.join(@get('path'), '.git'), (exists) =>
      return callback(null, exists) if git
      return callback(null, false) if exists
      fs.exists @get('path'), (exists) => callback(null, exists)
