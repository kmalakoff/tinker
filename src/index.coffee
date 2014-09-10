_ = require 'underscore'
Async = require 'async'

Package = require './package'
Module = require './module'
GitRepo = require './git_repo'

Utils = require './lib/utils'

module.exports = class Tinker
  @install: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    Utils.load options, (err) ->
      return callback(err) if err

      Package.all (err, packages) ->
        return callback(err) if err
        Async.each packages, ((pkg, callback) -> pkg.install callback), callback

  @uninstall: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    Utils.load options, (err) ->
      return callback(err) if err

      Package.all (err, packages) ->
        return callback(err) if err
        Async.each packages, ((pkg, callback) -> pkg.uninstall callback), callback

  @on: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    Utils.load options, (err) ->
      return callback(err) if err

      Module.findByGlob glob, options, (err, modules) ->
        return callback(err) if err
        return callback(new Error "No modules found for glob #{glob}") if modules.length is 0
        Async.each modules, ((module, callback) -> module.tinkerOn callback), callback

  @off: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    Utils.load options, (err) ->
      return callback(err) if err

      Module.findByGlob glob, options, (err, modules) ->
        return callback(err) if err
        return callback(new Error "No modules found for glob #{glob}") if modules.length is 0
        Async.each modules, ((module, callback) -> module.tinkerOff callback), callback
