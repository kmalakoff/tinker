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
      if glob.indexOf('*') >= 0
        return callback(null, modules) if glob is '*' # all
        callback(null, (module for module in modules when minimatch(module.get('path'), glob)))
      else
        callback(null, (module for module in modules when minimatch(module.get('name'), glob)))

  tinkerOn: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    console.log "Tinkering on #{@get('name')} (#{@relativeDirectory()})"

    @gitURL (err, git_url) =>
      return callback(err) if err
      (console.log "Module: #{@get('name')} has no git_url #{@relativeDirectory()}. Skipping".yellow; return callback()) unless git_url

      @isInstalled true, (err, is_installed) =>
        if is_installed
          if options.force
            console.log "Git: #{@get('name')} exists in #{@relativeDirectory()}. Forcing".yellow
          else
            console.log "Git: #{@get('name')} exists in #{@relativeDirectory()}. Skipping".green; return callback()

        fs.exists (module_directory = @moduleDirectory()), (exists) =>
          git_repo = new GitRepo({git_url})
          git_repo[if exists then 'cloneGit' else 'clone'].call(git_repo, module_directory, callback)

  tinkerOff: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    console.log "Tinkering off #{@get('name')} (#{@relativeDirectory()})"

    @gitURL (err, git_url) =>
      return callback(err) if err
      (console.log "Module: #{@get('name')} has no git_url #{@relativeDirectory()}. Skipping".yellow; return callback()) unless git_url

      @isInstalled false, (err, is_installed) =>
        return callback(err) if err
        if is_installed
          if options.force
            console.log "Module: #{@get('name')} exists in #{@relativeDirectory()}. Forcing".yellow
          else
            console.log "Module: #{@get('name')} exists in #{@relativeDirectory()}. Skipping".green; return callback()

        fs.exists (module_directory = @moduleDirectory()), (exists) =>
          if exists
            fs.remove path.join(module_directory, '.git'), callback
          else
            @install(callback)

  packageJSON: -> @package_json or= require(@get('path')) # TODO: make async
  moduleDirectory: -> path.join(@get('base'))
  relativeDirectory: -> base = base.substring(cwd.length+1) if (base = @get('base')).indexOf(cwd = @get('cwd')) is 0; base

  isInstalled: (git, callback) ->
    module_directory = @moduleDirectory()
    fs.exists path.join(module_directory, '.git'), (exists) =>
      return callback(null, exists) if git
      return callback(null, false) if exists
      fs.exists module_directory, (exists) => callback(null, exists)

  install: (callback) ->
    @get 'package', (err, pkg) =>
      return callback(err) if err
      return callback(new Error "Couldn't find package for #{@get('name')}") unless pkg
      PackageUtils.apply(pkg, 'installModule', @, callback)

  gitURL: (callback) ->
    @get 'package', (err, pkg) =>
      return callback(err) if err
      return callback(new Error "Couldn't find package for #{@get('name')}") unless pkg
      PackageUtils.apply(pkg, 'gitURL', @, callback)
