path = require 'path'
_ = require 'underscore'
Async = require 'async'
jsonFileParse = require '../lib/json_file_parse'

Package = require './package'

module.exports = class Utils
  @modules: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    Utils.packages options, (err, packages) ->
      return callback(err) if err

      modules = []
      queue = new Queue()
      for pkg in packages
        do (pkg) -> queue.defer (callback) ->
          pkg.modules glob, (err, _modules) -> modules = modules.concat(_modules); callback(err)
      queue.await (err) ->
        return callback(err) if err
        callback(null, modules)

  @modulesExec: (glob, options, fn, callback) ->
    Utils.modules glob, options, (err, modules) ->
      return callback(err) if err
      Async.each modules, fn, callback
