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

    queue.defer (callback) ->
      Vinyl.src(Package.optionsToDirectories(options))
        .pipe jsonFileParse()
        .pipe es.writeArray (err, files) ->
          return callback(err) if err

          package_queue = new Queue()
          for file in files
            do (file) -> queue.defer (callback) -> Package.findOrCreateByFile file, (err, pkg) ->
              if err then callback(err) else pkg.loadModules(callback)
          package_queue.await callback
    queue.await callback
