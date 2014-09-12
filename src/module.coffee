fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
minimatch = require 'minimatch'
colors = require 'colors'

GitRepo = require './git_repo'
PackageUtils = require './lib/package_utils'
Package = null
Config = require './lib/config'
moduleInit = require './init/module'

module.exports = class Module extends (require 'backbone').Model
  model_name: 'Module'
  schema:
    package: -> ['belongsTo', Package = require './package']
  sync: (require 'backbone-orm').sync(Module)

  @findByGlob: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    glob = options.glob or ''

    Module.cursor({'package.type': {$in: _.pluck(Package.optionsToTypes(options), 'type')}}).toModels (err, modules) ->
      return callback(err) if err
      if glob.indexOf('*') >= 0
        return callback(null, modules) if glob is '*' # all
        callback(null, (module for module in modules when minimatch(module.get('path'), glob)))
      else
        callback(null, (module for module in modules when minimatch(module.get('name'), glob)))

  init: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    moduleInit(@, options, callback)

  tinkerOn: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    console.log "Tinkering on #{@get('name')} (#{@relativeDirectory()})"

    @gitURL options, (err, url) =>
      return callback(err) if err
      (console.log "Module: #{@get('name')} has no url #{@relativeDirectory()}. Skipping".yellow; return callback()) unless url

      @isInstalled true, (is_installed) =>
        if is_installed
          if options.force
            console.log "Git: #{@get('name')} exists in #{@relativeDirectory()}. Forcing".yellow
          else
            console.log "Git: #{@get('name')} exists in #{@relativeDirectory()}. Skipping".green; return callback()

        fs.exists @moduleDirectory(), (exists) =>
          git_repo = new GitRepo({url})
          git_repo[if exists then 'cloneGit' else 'clone'].call(git_repo, @moduleDirectory(), callback)

  tinkerOff: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    console.log "Tinkering off #{@get('name')} (#{@relativeDirectory()})"

    @gitURL options, (err, url) =>
      return callback(err) if err
      (console.log "Module: #{@get('name')} has no url #{@relativeDirectory()}. Skipping".yellow; return callback()) unless url

      @isInstalled false, (is_installed) =>
        if is_installed
          if options.force
            console.log "Module: #{@get('name')} exists in #{@relativeDirectory()}. Forcing".yellow
          else
            console.log "Module: #{@get('name')} exists in #{@relativeDirectory()}. Skipping".green; return callback()

        fs.exists @moduleDirectory(), (exists) =>
          if exists
            fs.remove path.join(@moduleDirectory(), '.git'), callback
          else
            @install(callback)

  moduleDirectory: -> path.dirname(@get('path'))
  relativeDirectory: -> base = base.substring(cwd.length+1) if (base = @moduleDirectory()).indexOf(cwd = @get('cwd')) is 0; base

  isInstalled: (git_exists, callback) ->
    fs.exists path.join(@moduleDirectory(), '.git'), (exists) =>
      return callback(exists) if git_exists
      return callback(false) if exists
      fs.exists @moduleDirectory(), (exists) =>
        console.log 'exists', exists
        callback(exists)

  install: (callback) ->
    @get 'package', (err, pkg) =>
      return callback(err) if err
      return callback(new Error "Couldn't find package for #{@get('name')}") unless pkg
      PackageUtils.apply(pkg, 'installModule', @, callback)

  gitURL: (options, callback) ->
    return callback(null, url) if url = (config = Config.configByModule(@))?.url
