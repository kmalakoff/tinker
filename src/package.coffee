fs = require 'fs'
path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
inquirer = require 'inquirer'

Vinyl = require 'vinyl-fs'
{File} = require 'gulp-util'
es = require 'event-stream'
Queue = require 'queue-async'
Module = null
Config = require './config'
fileToJSON = require './lib/file_to_json'

TinkerUtils = require './lib/utils'
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
      file_path = file.path or file
      new_attributes = {path: file.path or file}
      file_name = path.basename(file_path); info = _.find(Package.TYPES, (info) -> info.file_name is file_name)
      new_attributes = {path: file_path, type: info.type}
      _.extend(new_attributes, {name: json.name, contents: json}) if json
      return callback(null, @) if _.isEqual(_.pick(@attributes, _.keys(new_attributes)), new_attributes) # no change
      @save new_attributes, (err) => if err then callback(err) else @loadModules((err) => callback(err, @))

  @findOrCreate: (require './lib/model_utils').findOrCreateByFileOverloadFn Package, Package::setFile

  @optionsToTypes: (options) ->
    if _.size(_.pick(options, _.pluck(Package.TYPES, 'type')))
      return (type for type in Package.TYPES when not options.hasOwnProperty('type') or !!options[type])
    else
      package_types = Config.get('package_types')
      return _.filter(Package.TYPES, (type) -> type.type in package_types)

  @optionsToDirectories: (options) ->
    directory = if options.directory then path.join(process.cwd(), options.directory) else process.cwd()
    directories = (path.join(directory, info.file_name) for info in Package.optionsToTypes(options))
    return directories

  loadModules: (callback) ->
    queue = new Queue(1)
    queue.defer (callback) => Module.destroy({package_id: @id}, callback)

    # load modules from file system
    queue.defer (callback) => PackageUtils.lookup(@, 'loadModules')(callback)

    # load modules from config
    for module_info in _.filter(Config.get('modules') or [], (module) => module.package_path is @get('path'))
      do (module_info) => queue.defer (callback) =>
        Module.findOrCreate _.pick(module_info, 'name', 'path'), (err, module) =>
          return callback(err) if err
          module.save {package: @}, (err) =>
            if err then callback(err) else module.setFile(module_info.path, callback)

    queue.await callback

  moduleDirectory: -> path.dirname(@get('path'))
  relativeDirectory: (options) -> TinkerUtils.relativeDirectory(@moduleDirectory(), options)

  install: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    fs.exists (modules_directory = PackageUtils.lookup(@, 'modulesDirectory')()), (exists) =>
      if exists
        unless options.force
          console.log "Package: #{@get('name')} already installed in #{@relativeDirectory(options) or 'cwd'}. Skipping. Use --force for replacement options.".yellow; return callback()

        console.log ''
        inquirer.prompt [{
          type: 'list', name: 'action', choices: ['Skip', 'Discard my changes (clean install)', 'Install modules one-by-one']
          message: "Package: #{@get('name')} already installed in #{@relativeDirectory(options) or 'cwd'}"}
        ], (answers) =>
          switch answers.action
            when 'Discard my changes (clean install)'
              @uninstall options, (err) => if err then callback(err) else doInstall(@, callback)
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
    @canModify options, (err, can_modify) =>
      return callback(err) if err
      return callback(new Error "Cannot modify install #{@get('name')}") unless can_modify
      Module.destroy {package_id: @id}, (err) => if err then callback(err) else PackageUtils.lookup(@, 'uninstall')(callback)

  canModify: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    Vinyl.src(path.join(PackageUtils.lookup(@, 'modulesDirectory')(), '**', '.git'), {read: false})
      .pipe es.writeArray (err, files) =>
        return callback(err) if err
        return callback(null, true) unless files.length

        module_names = (TinkerUtils.relativeDirectory(path.dirname(file.path), options) for file in files).join(' and ')
        unless options.force
          console.log "Modules #{module_names} have .git files for package #{@get('name')}. Skipping. Use --force for replacement options.".yellow
          callback(null, false)

        console.log ''
        inquirer.prompt [{type: 'confirm', name: 'allow', message: "Modules #{module_names} have .git files for package #{@get('name')}. Do you want to remove all files?"}
        ], (answers) -> return callback(null, answers.allow)
