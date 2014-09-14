fs = require 'fs'
path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
inquirer = require 'inquirer'

{File} = require 'gulp-util'
Queue = require 'queue-async'
Module = null
Config = require './config'
fileToJSON = require './lib/file_to_json'

PackageUtils = require './lib/package_utils'

doInstall = (pkg, callback) ->
  PackageUtils.lookup(pkg, 'install') (err) => if err then callback(err) else pkg.loadModules(callback)

module.exports = class Package extends (require 'backbone').Model
  model_name: 'Package'
  schema:
    modules: -> ['hasMany', Module = require './module']
  sync: (require 'backbone-orm').sync(Package)

  @TYPES = [
    {type: 'npm', file_name: 'package.json'}
    {type: 'bower', file_name: 'bower.json'}
  ]

  setFile: (file, callback) ->
    fileToJSON file, (err, json) =>
      file_name = path.basename(file.path); info = _.find(Package.TYPES, (info) -> info.file_name is file_name)
      @save {path: file.path, name: json?.name, contents: json, type: info?.type}, (err) =>
        return callback(err) if err
        @loadModules (err) => callback(err, @)

  @findOrCreate: (require './lib/model_utils').findOrCreateByFileOverloadFn Package, Package::setFile

  @optionsToTypes: (options) ->
    if _.size(_.pick(options, _.pluck(Package.TYPES, 'type')))
      return (type for type in Package.TYPES when not options.hasOwnProperty('type') or !!options[type])
    else
      package_types = Config.get('package_types')
      console.log "Tinker has no package types configured. Have you run 'tinker init'?" unless package_types.length
      return _.filter(Package.TYPES, (type) -> type.type in package_types)

  @optionsToDirectories: (options) ->
    directory = if options.directory then path.join(process.cwd(), options.directory) else process.cwd()
    (path.join(directory, info.file_name) for info in Package.optionsToTypes(options))

  loadModules: (callback) ->
    queue = new Queue(1)
    queue.defer (callback) => Module.destroy({package_id: @id}, callback)

    # load modules from file system
    queue.defer (callback) => PackageUtils.lookup(@, 'loadModules')(callback)

    # load modules from config
    for module_info in _.filter(Config.get('modules') or [], (module) => module.package is @get('path'))
      do (module_info) => queue.defer (callback) =>
        Module.findOrCreate _.pick(module_info, 'name', 'path'), (err, module) =>
          return callback(err) if err
          module.set({package: @}).setFile(module_info.path, callback)

    queue.await callback

  moduleDirectory: -> path.dirname(@get('path'))
  relativeDirectory: -> base = base.substring(cwd.length+1) if (base = @moduleDirectory()).indexOf(cwd = process.cwd()) is 0; base
  install: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    fs.exists (modules_directory = PackageUtils.lookup(@, 'modulesDirectory')()), (exists) =>
      if exists
        unless options.force
          console.log "Package: #{@get('name')} already installed in #{@relativeDirectory() or 'cwd'}. Skipping. Use --force for replacement options.".yellow; return callback()

        console.log ''
        inquirer.prompt [{
          type: 'list', name: 'action', choices: ['Skip', 'Discard my changes', 'Install modules one-by-one']
          message: "Package: #{@get('name')} already installed in #{@relativeDirectory() or 'cwd'}"}
        ], (answers) =>
          switch answers.action
            when 'Discard my changes'
              queue = new Queue(1)
              queue.defer (callback) => @uninstall(callback)
              queue.defer (callback) => doInstall(@, callback)
              queue.await callback
            when 'Install modules one-by-one'
              @get 'modules', (err, modules) =>
                return callback(err) if err
                queue = new Queue(1)
                for module in modules
                  do (module) => queue.defer (callback) => module.install(options, callback)
                queue.await callback
            else callback()

      else
        doInstall(@, callback)

  uninstall: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    Module.destroy {package_id: @id}, (err) => if err then callback(err) else PackageUtils.lookup(@, 'uninstall')(callback)
