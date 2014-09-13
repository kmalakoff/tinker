Queue = require 'queue-async'

Config = require '../config'
Package = require '../package'
Module = require '../module'

module.exports = class Utils
  @load: (options, callback) ->
    queue = new Queue(1)
    queue.defer (callback) -> Config.load options, callback
    queue.defer (callback) -> Package.load options, callback
    queue.defer (callback) -> Module.load options, callback
    queue.await callback
