fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
minimatch = require 'minimatch'
colors = require 'colors'

GitRepo = require './git_repo'
PackageUtils = require './lib/package_utils'
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
    (console.log "Module: #{@get('name')} has no git_url #{@relativePath()}. Skipping".yellow; return callback()) unless git_url = @get('git_url')

    @isInstalled true, (err, is_installed) =>
      if is_installed
        if options.force
          console.log "Git: #{@get('name')} exists in #{@relativePath()}. Forcing".yellow
        else
          console.log "Git: #{@get('name')} exists in #{@relativePath()}. Skipping".green; return callback()

      fs.exists @get('path'), (exists) =>
        git_repo = new GitRepo({git_url})
        git_repo[if exists then 'cloneGit' else 'clone'].call(git_repo, @get('path'), callback)

  tinkerOff: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    console.log "Tinkering off #{@get('name')} (#{@relativePath()})"
    (console.log "Module: #{@get('name')} has no git_url #{@relativePath()}. Skipping".yellow; return callback()) unless git_url = @get('git_url')

    @isInstalled false, (err, is_installed) =>
      return callback(err) if err
      if is_installed
        if options.force
          console.log "Module: #{@get('name')} exists in #{@relativePath()}. Forcing".yellow
        else
          console.log "Module: #{@get('name')} exists in #{@relativePath()}. Skipping".green; return callback()

      fs.exists @get('path'), (exists) =>
        if exists
          fs.remove path.join(@get('path'), '.git'), callback
        else
          @install(callback)

  relativePath: -> @get('path').replace("#{@get('root')}/", '')
  isInstalled: (git, callback) ->
    fs.exists path.join(@get('path'), '.git'), (exists) =>
      return callback(null, exists) if git
      return callback(null, false) if exists
      fs.exists @get('path'), (exists) => callback(null, exists)

  install: (callback) ->
    @get 'package', (err, pkg) =>
      return callback(err) if err
      return callback(new Error "Couldn't find package for #{@get('name')}") unless pkg
      PackageUtils.call(pkg, 'installModule', [@, callback])
