Queue = require 'queue-async'

Package = require '../package'
Config = require '../config'

module.exports = class Utils
  @load: (options, callback) ->
    queue = new Queue(1)
    queue.defer (callback) -> Config.load options, callback
    queue.defer (callback) -> Package.load options, callback
    queue.await callback
