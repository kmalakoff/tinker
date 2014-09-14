_ = require 'underscore'
Queue = require 'queue-async'
Vinyl = require 'vinyl-fs'
es = require 'event-stream'

Config = require '../config'
Package = require '../package'
Module = require '../module'

module.exports = class Utils
  @load: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    queue = new Queue(1)
    queue.defer (callback) -> Config.load(options, callback)
    queue.defer (callback) -> Package.destroy(callback)
    queue.defer (callback) -> Module.destroy(callback)

    queue.defer (callback) -> Utils.loadType Package, Package.optionsToDirectories(options), (err, packages) ->
      return callback(err) if err

      package_queue = new Queue()
      for pkg in packages
        do (pkg) -> package_queue.defer (callback) -> pkg.loadModules(callback)
      package_queue.await callback

    queue.await callback

  @loadType: (type, src, callback) ->
    if _.isArray(src)
      return callback(null, []) unless src.length
    else
      src = [src]; $one = true

    queue = new Queue()
    for type_path in src
      do (type_path) -> queue.defer (callback) ->
        type.findOrCreate {path: type_path}, (err, model) ->
          return callback(err) if err
          return callback(null, model) if model.get('contents')

          try type.findOrCreateByFile({path: type_path, contents: require(type_path)}, callback)
          catch err then console.log "Warning: failed to load #{type_path}. Is it installed?".yellow; callback()
    queue.await (err) ->
      return callback(err) if err
      models = _.compact(Array::splice.call(arguments, 1))
      callback(null, if $one then models[0] or null else models)
