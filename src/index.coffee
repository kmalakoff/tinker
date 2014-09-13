_ = require 'underscore'
Async = require 'async'

Package = require './package'
Module = require './module'
RepoUtils = require './lib/repo_utils'
Utils = require './lib/utils'
tinkerInit = require './init/tinker'

module.exports = class Tinker
  @config: require './lib/config'

  @init: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    Utils.load options, (err) ->
      return callback(err) if err
      tinkerInit(options, callback)

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

  @on: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    Utils.load options, (err) ->
      return callback(err) if err

      Module.findByGlob options, (err, modules) ->
        return callback(err) if err
        return callback(new Error "No modules found for glob #{options.glob}") if modules.length is 0
        Async.eachSeries modules, ((module, callback) -> module.tinkerOn options, callback), callback

  @off: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    Utils.load options, (err) ->
      return callback(err) if err

      Module.findByGlob options, (err, modules) ->
        return callback(err) if err
        return callback(new Error "No modules found for glob #{options.glob}") if modules.length is 0
        Async.eachSeries modules, ((module, callback) -> module.tinkerOff options, callback), callback

  @cache: (action, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2

    switch action
      when 'clear', 'clean' then return RepoUtils.cacheClear(options, callback)
      else return callback(new Error "Unrecognized cache action '#{action}'")
