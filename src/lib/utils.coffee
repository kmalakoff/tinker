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

    queue.await (err) ->
      return callback(err) if err
      return callback() unless (src = Package.optionsToDirectories(options)).length

      Vinyl.src(src)
        .pipe es.map(Package.findOrCreate)
        .pipe es.writeArray(callback)
