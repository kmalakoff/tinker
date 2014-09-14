fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
request = require 'superagent'
Queue = require 'queue-async'
minimatch = require 'minimatch'
inquirer = require 'inquirer'
require 'colors'

PackageUtils = require './lib/package_utils'
RepoUtils = require './lib/repo_utils'
RepoURL = require './lib/repo_url'
Package = null
Config = require './config'
moduleInit = require './init/module'
spawn = require './lib/spawn'

doInstall = (module, callback) ->
  module.get 'package', (err, pkg) =>
    return callback(err) if err
    return callback(new Error "Couldn't find package for #{@get('name')}") unless pkg
    PackageUtils.lookup(pkg, 'installModule')(module, callback)

module.exports = class Module extends (require 'backbone').Model
  model_name: 'Module'
  schema:
    package: -> ['belongsTo', Package = require './package']
  sync: (require 'backbone-orm').sync(Module)

  @findOrCreateByFile: (file, callback) ->
    Module.findOrCreate _.pick(file, 'path'), (err, model) ->
      return callback(err) if err
      model.save({name: file.contents?.name, contents: file.contents}, callback)

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

  toConfig: ->
    config = _.pick(@attributes, 'name', 'path', 'url')
    console.log "Module config is missing package #{@get('name')}".red unless pkg = @get('package')
    config.package = pkg?.get('path')
    return config

  tinkerOn: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    @ensureInitialized options, (initialized) =>
      return callback() unless url = (config = Config.configByModule(@))?.url
      console.log "Tinkering on #{@get('name')} (#{@relativeDirectory()})"

      @installStatus (status) =>
        if status.git
          unless options.force
            console.log "Module: #{@get('name')} .git exists in #{@relativeDirectory()}. Skipping. Use --force for replacement options.".yellow; return callback()

          inquirer.prompt [{
            type: 'list', name: 'action', choices: ['Skip', 'Discard my changes', 'Replace .git folder']
            message: "Module: #{@get('name')} .git exists in #{@relativeDirectory()}"}
          ], (answers) =>
            queue = new Queue(1)
            switch answers.action
              when 'Discard my changes'
                queue.defer (callback) => fs.remove(@moduleDirectory(), callback)
                queue.defer (callback) => RepoUtils.clone(url, @moduleDirectory(), callback)
              when 'Replace .git folder'
                queue.defer (callback) => fs.remove(path.join(@moduleDirectory(), '.git'), callback)
                queue.defer (callback) => RepoUtils.cloneGit(url, @moduleDirectory(), callback)
            queue.await callback

        else if status.directory
          inquirer.prompt [{
            type: 'list', name: 'action', choices: ['Skip', 'Discard my changes', 'Install .git folder']
            message: "Module: #{@get('name')} exists in #{@relativeDirectory()}"}
          ], (answers) =>
            queue = new Queue(1)
            switch answers.action
              when 'Discard my changes'
                queue.defer (callback) => fs.remove(@moduleDirectory(), callback)
                queue.defer (callback) => RepoUtils.clone(url, @moduleDirectory(), callback)
              when 'Install .git folder'
                queue.defer (callback) => fs.remove(path.join(@moduleDirectory(), '.git'), callback)
                queue.defer (callback) => RepoUtils.cloneGit(url, @moduleDirectory(), callback)
            queue.await callback

        else
          RepoUtils.clone(url, @moduleDirectory(), callback)

  tinkerOff: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    @ensureInitialized options, (initialized) =>
      return callback() unless url = (config = Config.configByModule(@))?.url
      console.log "Tinkering off #{@get('name')} (#{@relativeDirectory()})"

      @installStatus (status) =>
        if status.git
          fs.remove path.join(@moduleDirectory(), '.git'), callback

        else if status.directory
          unless options.force
            console.log "Module: #{@get('name')} folder exists in #{@relativeDirectory()}. Skipping. Use --force for replacement options.".yellow; return callback()

          inquirer.prompt [{
            type: 'list', name: 'action', choices: ['Skip', 'Discard my changes']
            message: "Module: #{@get('name')} folder exists in #{@relativeDirectory()}"}
          ], (answers) =>
            queue = new Queue(1)
            switch answers.action
              when 'Discard my changes'
                queue.defer (callback) => fs.remove(@moduleDirectory(), callback)
                queue.defer (callback) => @install(callback)
            queue.await callback

        else
          @install(callback)

  exec: (args, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    @ensureInitialized options, (initialized) =>
      return callback() unless initialized
      spawn args.join(' '), {cwd: @moduleDirectory()}, callback

  moduleDirectory: -> path.dirname(@get('path'))
  relativeDirectory: -> base = base.substring(cwd.length+1) if (base = @moduleDirectory()).indexOf(cwd = @get('cwd')) is 0; base

  installStatus: (callback) ->
    queue = new Queue()
    queue.defer (callback) => fs.exists path.join(@moduleDirectory(), '.git'), (exists) => callback(null, {git: exists})
    queue.defer (callback) => fs.exists @moduleDirectory(), (exists) => callback(null, {directory: exists})
    queue.await => callback(_.extend.apply(_, Array::slice.call(arguments, 1)))

  install: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    fs.exists module_directory = @moduleDirectory(), (exists) =>
      if exists
        unless options.force
          console.log "Module: #{@get('name')} already installed in #{module_directory}. Skipping. Use --force for replacement options.".yellow; return callback()

        inquirer.prompt [{
          type: 'list', name: 'action', choices: ['Skip', 'Discard my changes']
          message: "Module: #{@get('name')} already installed in #{module_directory}"}
        ], (answers) =>
          switch answers.action
            when 'Discard my changes'
              queue = new Queue(1)
              queue.defer (callback) => @uninstall(callback)
              queue.defer (callback) => doInstall(@, callback)
              queue.await callback
            else callback()
      else
        doInstall(@, callback)

  uninstall: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    fs.remove(path.dirname(@get('path')), callback)

  repositories: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    repositories = []
    queue = new Queue()
    queue.defer (callback) =>
      @get 'package', (err, pkg) =>
        return callback(err) if err
        return callback(new Error "Couldn't find package for #{@get('name')}") unless pkg
        PackageUtils.lookup(pkg, 'repositories') @, (err, _repositories) =>
          return callback(err) if err
          repositories = repositories.concat(_repositories)
          callback()

    for repository_service in (Config.get('repository_services') or [])
      do (repository_service) => queue.defer (callback) =>
        request.head(url = "#{repository_service}/#{@get('name')}").end (res) =>
          repositories.push(url) if res.status is 200
          callback()

    queue.await (err) => callback(err, _.uniq(RepoURL.normalize(repository) for repository in repositories).sort())

  ensureInitialized: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    return callback(!!url) if url = (config = Config.configByModule(@))?.url
    @init options, (err) =>
      console.log "Module: #{@get('name')} has no url #{@relativeDirectory()}. Do you need to initialize it?".yellow unless url = (config = Config.configByModule(@))?.url
      callback(!!url)
