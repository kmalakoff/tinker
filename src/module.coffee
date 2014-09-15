fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
request = require 'superagent'
Queue = require 'queue-async'
Async = require 'async'
minimatch = require 'minimatch'
inquirer = require 'inquirer'
require 'colors'

PackageUtils = require './lib/package_utils'
RepoUtils = require './lib/repo_utils'
TinkerUtils = require './lib/utils'
RepoURL = require './lib/repo_url'
Package = null
Config = require './config'
moduleInit = require './init/module'
{File} = require 'gulp-util'
fileToJSON = require './lib/file_to_json'
spawn = require './lib/spawn'

doInstall = (module, callback) ->
  module.get 'package', (err, pkg) =>
    return callback(err) if err
    return callback(new Error "Couldn't find package for #{@get('name')}") unless pkg
    PackageUtils.lookup(pkg, 'installModule')(module, callback)

doEachByGlob = (name, options, fn, callback) ->
  Module.findByGlob options, (err, modules) ->
    return callback(err) if err
    return callback(new Error "No modules found for glob #{options.glob}") if modules.length is 0
    Async[name].call(Async, modules, fn, callback)

module.exports = class Module extends (require 'backbone').Model
  model_name: 'Module'
  schema:
    package: -> ['belongsTo', Package = require './package']
  sync: (require 'backbone-orm').sync(Module)

  setFile: (file, callback) ->
    fileToJSON file, (err, json) =>
      new_attributes = {path: file.path or file}
      _.extend(new_attributes, {name: json.name, contents: json}) if json
      return callback(null, @) if _.isEqual(_.pick(@attributes, _.keys(new_attributes)), new_attributes) # no change
      @save new_attributes, callback

  @findOrCreate: (require './lib/model_utils').findOrCreateByFileOverloadFn Module, Module::setFile

  @findByGlob: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    glob = options.glob or ''

    Module.cursor({'package.type': {$in: _.pluck(Package.optionsToTypes(options), 'type')}}).toModels (err, modules) ->
      return callback(err) if err
      return callback(null, modules) if glob is '*'
      if glob.indexOf('**') >= 0
        callback(null, (module for module in modules when minimatch(module.get('path'), glob)))
      else
        callback(null, (module for module in modules when minimatch(module.get('name'), glob)))

  @eachByGlob: (options, fn, callback) -> doEachByGlob 'each', options, fn, callback
  @eachSeriesByGlob: (options, fn, callback) -> doEachByGlob 'eachSeries', options, fn, callback

  init: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    moduleInit(@, options, callback)

  toConfig: ->
    config = _.pick(@attributes, 'name', 'path', 'url')
    console.log "Module config is missing package #{@get('name')}".red unless pkg = @get('package')
    config.package_path = pkg?.get('path')
    return config

  install: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    fs.exists module_directory = @moduleDirectory(), (exists) =>
      if exists
        unless options.force
          console.log "Module: #{@get('name')} already installed in #{@relativeDirectory(options)}. Skipping. Use --force for replacement options.".yellow; return callback()

        console.log ''
        inquirer.prompt [{
          type: 'list', name: 'action', choices: ['Skip', 'Discard my changes (clean install)']
          message: "Module: #{@get('name')} already installed in #{@relativeDirectory(options)}"}
        ], (answers) =>
          switch answers.action
            when 'Discard my changes (clean install)'
              fs.remove @moduleDirectory(), (err) => if err then callback(err) else doInstall(@, callback)
            else callback()
      else
        doInstall(@, callback)

  uninstall: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    @canUninstall options, (err, can_modify) =>
      return callback(err) if err
      return callback(new Error "Cannot modify install #{@get('name')}") unless can_modify
      fs.remove(@moduleDirectory(), callback)

  tinkerOn: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    @ensureInitialized options, (initialized) =>
      return callback() unless url = (config = Config.configByModule(@))?.url
      console.log '\n****************'
      console.log "Tinkering on #{@get('name')} (#{@relativeDirectory(options)})"

      @installStatus (status) =>
        if status.git
          unless options.force
            console.log "Module: #{@get('name')} .git exists in #{@relativeDirectory(options)}. Skipping. Use --force for replacement options.".yellow; return callback()

          console.log ''
          inquirer.prompt [{
            type: 'list', name: 'action', choices: ['Skip', 'Discard my changes (git clone)', 'Update git (copy .git folder)']
            message: "Module: #{@get('name')} .git exists in #{@relativeDirectory(options)}"}
          ], (answers) =>
            switch answers.action
              when 'Discard my changes (git clone)'
                fs.remove @moduleDirectory(), (err) =>
                  if err then callback(err) else RepoUtils.clone(url, @moduleDirectory(), callback)
              when 'Update git (copy .git folder)'
                fs.remove path.join(@moduleDirectory(), '.git'), (err) =>
                  if err then callback(err) else RepoUtils.cloneGit(url, @moduleDirectory(), callback)
              else callback()

        else if status.directory
          console.log ''
          inquirer.prompt [{
            type: 'list', name: 'action', choices: ['Skip', 'Discard my changes (git clone)', 'Keep my changes (copy .git folder)']
            message: "Module: #{@get('name')} exists in #{@relativeDirectory(options)}"}
          ], (answers) =>
            switch answers.action
              when 'Discard my changes (git clone)'
                fs.remove @moduleDirectory(), (err) =>
                  if err then callback(err) else RepoUtils.clone(url, @moduleDirectory(), callback)
              when 'Keep my changes (copy .git folder)'
                fs.remove path.join(@moduleDirectory(), '.git'), (err) =>
                  if err then callback(err) else RepoUtils.cloneGit(url, @moduleDirectory(), callback)
              else callback()

        else
          RepoUtils.clone(url, @moduleDirectory(), callback)

  tinkerOff: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    @ensureInitialized options, (initialized) =>
      return callback() unless url = (config = Config.configByModule(@))?.url
      console.log '\n****************'
      console.log "Tinkering off #{@get('name')} (#{@relativeDirectory(options)})"

      @installStatus (status) =>
        if status.git
          fs.remove path.join(@moduleDirectory(), '.git'), callback

        else if status.directory
          unless options.force
            console.log "Module: #{@get('name')} folder exists in #{@relativeDirectory(options)}. Skipping. Use --force for replacement options.".yellow; return callback()

          console.log ''
          inquirer.prompt [{
            type: 'list', name: 'action', choices: ['Skip', 'Discard my changes (fresh install)']
            message: "Module: #{@get('name')} folder exists in #{@relativeDirectory(options)}"}
          ], (answers) =>
            switch answers.action
              when 'Discard my changes (fresh install)'
                fs.remove @moduleDirectory(), (err) =>
                  if err then callback(err) else @install(callback)
              else callback()

        else
          @install(callback)

  exec: (args, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    @ensureInitialized options, (initialized) =>
      return callback() unless initialized
      console.log '\n****************'
      console.log "Exec #{args.join(' ')} on #{@get('name')} (#{@relativeDirectory(options)})"
      commands = args.join(' ').split(';')
      queue = new Queue(1)
      for command in commands
        do (command) => queue.defer (callback) => spawn command, {cwd: @moduleDirectory()}, callback
      queue.await callback

  moduleDirectory: -> path.dirname(@get('path'))
  relativeDirectory: (options) -> TinkerUtils.relativeDirectory(@moduleDirectory(), options)

  installStatus: (callback) ->
    queue = new Queue()
    queue.defer (callback) => fs.exists path.join(@moduleDirectory(), '.git'), (exists) => callback(null, {git: exists})
    queue.defer (callback) => fs.exists @moduleDirectory(), (exists) => callback(null, {directory: exists})
    queue.await => callback(_.extend.apply(_, Array::slice.call(arguments, 1)))

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
        request.head(url = "#{repository_service}/#{@get('name')}").end (res) => repositories.push(url) if res.status is 200; callback()

    queue.await (err) => callback(err, _.uniq(RepoURL.normalize(repository) for repository in repositories).sort())

  ensureInitialized: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    return callback(!!url) if url = (config = Config.configByModule(@))?.url
    @init options, (err) =>
      console.log "Module: #{@get('name')} has no url #{@relativeDirectory(options)}. Do you need to initialize it?".yellow unless url = (config = Config.configByModule(@))?.url
      callback(!!url)

  canUninstall: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    fs.exists path.join(@moduleDirectory(), '.git'), (exists) =>
      return callback(null, true) unless exists

      unless options.force
        console.log "Module #{@get('name')} has .git files. Skipping. Use --force for replacement options.".yellow
        callback(null, false)

      console.log ''
      inquirer.prompt [{type: 'confirm', name: 'allow', message: "Module #{@get('name')} has .git files. Do you want to discard your changes?"}
      ], (answers) -> return callback(null, answers.allow)
