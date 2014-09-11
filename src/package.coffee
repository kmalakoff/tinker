fs = require 'fs'
path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
Vinyl = require 'vinyl-fs'
es = require 'event-stream'

File = require 'vinyl'
Queue = require 'queue-async'
Module = null

PackageUtils = require './lib/package_utils'

module.exports = class Package extends (require 'backbone').Model
  model_name: 'Package'
  schema:
    modules: -> ['hasMany', Module = require './module']
  sync: (require 'backbone-orm').sync(Package)

  @TYPES = [
    {type: 'npm', file_name: 'package.json'}
    {type: 'bower', file_name: 'bower.json'}
  ]

  @load: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    Package.destroy (err) ->
      return callback(err) if err

      Vinyl.src(Package.optionsToDirectories(options), {read: false})
        .pipe es.writeArray (err, files) ->
          return callback(err) if err
          queue = new Queue()
          for file in files
            do (file) -> queue.defer (callback) ->
              file_name = path.basename(file.path)
              info = _.find(Package.TYPES, (info) -> info.file_name is file_name)

              new Package(_.extend({type: info.type}, _.pick(file, 'cwd', 'base', 'path'))).save (err, pkg) ->
                return callback(err) if err
                pkg.loadModules (err) -> callback(err, pkg)

          queue.await (err) -> callback(err, Array::splice.call(arguments, 1))

  @optionsToTypes: (options) ->
    types = Package.TYPES
    if _.size(load_types = _.pick(options, _.pluck(Package.TYPES, 'type'))) # filter
      types = _.filter(Package.TYPES, (info) -> !!load_types[info.type])
    return types

  @optionsToDirectories: (options) ->
    directory = if options.directory then path.join(process.cwd(), options.directory) else process.cwd()
    (path.join(directory, info.file_name) for info in Package.optionsToTypes(options))

  packageJSON: -> @package_json or= require(@get('path')) # TODO: make async
  loadModules: (callback) -> PackageUtils.call(@, 'loadModules', arguments)
  install: (callback) -> PackageUtils.call(@, 'install', arguments)
  uninstall: (callback) -> PackageUtils.call(@, 'uninstall', arguments)
