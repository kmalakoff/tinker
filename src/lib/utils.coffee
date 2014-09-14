_ = require 'underscore'
Queue = require 'queue-async'
Vinyl = require 'vinyl-fs'
es = require 'event-stream'
jsonFileParse = require './json_file_parse'

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

    # load packages
    queue.defer (callback) -> Utils.loadType Package, Package.optionsToDirectories(options), (err, packages) ->
      return callback(err) if err

      package_queue = new Queue()
      for pkg in packages
        do (pkg) -> package_queue.defer (callback) -> pkg.loadModules(callback)
      package_queue.await callback

    # load modules from config
    queue.defer (callback) ->
      module_infos = Config.get('modules') or []
      needed_paths = (module_info.path for module_info in module_infos)
      Utils.loadType Module, needed_paths, (err, modules) ->
        return callback(err) if err

        module_queue = new Queue(1)
        for module_info in module_infos
          do (module_info) -> module_queue.defer (callback) ->
            unless module = _.find(modules, (module) -> module.get('path') is module_info.path)
              console.log "Failed to load module: #{JSON.stringify(_.pick(module_info, 'name', 'path'))}".red
              return callback()
            return callback() if module.get('package') # has a package

            Package.findOne {path: module_info.package}, (err, pkg) ->
              return callback(err) if err
              unless pkg
                console.log "Failed to find package for module: #{JSON.stringify(_.pick(module_info, 'name', 'path'))}".red
                return callback()
              module.save({package: pkg}, callback)

        module_queue.await callback
    queue.await callback

  @loadType: (type, src, callback) ->
    if _.isArray(src)
      return callback(null, []) unless src.length
    else
      src = [src]; $one = true

    type.find {'path': {$in: src}}, (err, models) ->
      return callback(err) if err

      loaded_paths = (model.get('path') for model in models)
      return callback(null, models) unless (missing_paths = _.difference(src, loaded_paths)).length

      Vinyl.src(missing_paths)
        .pipe jsonFileParse()
        .pipe es.writeArray (err, files) ->
          return callback(err) if err

          queue = new Queue()
          for file in files
            do (file) -> queue.defer (callback) ->
              type.findOne({path: file.path}, (err, model) -> if err or model then callback(err, model) else type.createByFile(file, callback))
          queue.await (err) ->
            return callback(err) if err

            models = models.concat(Array::splice.call(arguments, 1))
            callback(null, if $one then models[0] or null else models)
