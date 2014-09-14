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

module.exports = class Module extends (require 'backbone').Model
  model_name: 'Module'
  schema:
    package: -> ['belongsTo', Package = require './package']
  sync: (require 'backbone-orm').sync(Module)

  @load: (src, callback) ->
    Vinyl.src(src)
      .pipe jsonFileParse()
      .pipe es.writeArray (err, files) ->
        return callback(err) if err
        package_queue = new Queue()
        for file in files
          do (file) -> package_queue.defer (callback) -> Module.createByFile(file, callback)
        package_queue.await (err) -> callback(err, Array::splice.call(arguments, 1))

  @createByFile: (file, callback) ->
    new Module(_.extend({name: file.contents.name}, _.pick(file, 'cwd', 'path', 'contents'))).save(callback)

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
    console.log "Tinkering on #{@get('name')} (#{@relativeDirectory()})"
    (console.log "Module: #{@get('name')} has no url #{@relativeDirectory()}. Skipping".yellow; return callback()) unless url = (config = Config.configByModule(@))?.url

    @installStatus (status) =>
      console.log 'status', status
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
        RepoUtils.cloneGit(url, @moduleDirectory(), callback)

      else
        RepoUtils.clone(url, @moduleDirectory(), callback)

  tinkerOff: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    console.log "Tinkering off #{@get('name')} (#{@relativeDirectory()})"
    (console.log "Module: #{@get('name')} has no url #{@relativeDirectory()}. Skipping".yellow; return callback()) unless url = (config = Config.configByModule(@))?.url

    @installStatus (status) =>
      if status.git
        fs.remove path.join(@moduleDirectory(), '.git'), callback

      else if status.directory
        unless options.force
          console.log "Module: #{@get('name')} .git exists in #{@relativeDirectory()}. Skipping. Use --force for replacement options.".yellow; return callback()

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
    (console.log "Module: #{@get('name')} has no url #{@relativeDirectory()}. Skipping".yellow; return callback()) unless url = (config = Config.configByModule(@))?.url

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

    @get 'package', (err, pkg) =>
      return callback(err) if err
      return callback(new Error "Couldn't find package for #{@get('name')}") unless pkg
      PackageUtils.apply(pkg, 'installModule', @, callback)

  repositories: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    repositories = []

    queue = new Queue()
    queue.defer (callback) =>
      @get 'package', (err, pkg) =>
        return callback(err) if err
        return callback(new Error "Couldn't find package for #{@get('name')}") unless pkg
        PackageUtils.apply pkg, 'repositories', @, (err, _repositories) =>
          return callback(err) if err
          repositories = repositories.concat(_repositories)
          callback()

    for repository_service in (Config.get('repository_services') or [])
      do (repository_service) => queue.defer (callback) =>
        request.head(url = "#{repository_service}/#{@get('name')}").end (res) =>
          repositories.push(url) if res.status is 200
          callback()

    queue.await (err) => callback(err, _.uniq(RepoURL.normalize(repository) for repository in repositories).sort())
