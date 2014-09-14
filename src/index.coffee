_ = require 'underscore'
Async = require 'async'

Package = require './package'
Module = require './module'
RepoUtils = require './lib/repo_utils'
Utils = require './lib/utils'
Config = require './config'
tinkerInit = require './init/tinker'

module.exports = class Tinker
  @init: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    Utils.load options, (err) ->
      return callback(err) if err
      tinkerInit(options, callback)

  @config: (args, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    Config.load options, (err) ->
      return callback(err) if err
      if args.length
        Config.save Config.parseArgs(args), callback
      else
        console.log Config.toJSON()

  @update: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    options = _.defaults({force: true}, options)
    Utils.load options, (err) ->
      return callback(err) if err

      Module.findByGlob options, (err, modules) ->
        return callback(err) if err
        return callback(new Error "No modules found for glob #{options.glob}") if modules.length is 0
        Async.eachSeries modules, ((module, callback) -> module.init options, callback), callback

  @install: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    Utils.load options, (err) ->
      return callback(err) if err

      if options.glob is '*'
        Package.cursor().include('modules').toModels (err, packages) ->
          return callback(err) if err
          Async.eachSeries packages, ((pkg, callback) -> pkg.install(options, callback)), callback
      else
        Module.findByGlob options, (err, modules) ->
          return callback(err) if err
          return callback(new Error "No modules found for glob #{options.glob}") if modules.length is 0
          Async.eachSeries modules, ((module, callback) -> module.install options, callback), callback

  @uninstall: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    Utils.load options, (err) ->
      return callback(err) if err

      if options.glob is '*'
        Package.cursor().include('modules').toModels (err, packages) ->
          return callback(err) if err
          Async.eachSeries packages, ((pkg, callback) -> pkg.uninstall(options, callback)), callback
      else
        Module.findByGlob options, (err, modules) ->
          return callback(err) if err
          return callback(new Error "No modules found for glob #{options.glob}") if modules.length is 0
          Async.eachSeries modules, ((module, callback) -> module.uninstall options, callback), callback

  @on: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    Utils.load options, (err) ->
      return callback(err) if err

      Module.findByGlob options, (err, modules) ->
        return callback(err) if err
        return callback(new Error "No modules found for glob #{options.glob}") if modules.length is 0
        Async.eachSeries modules, ((module, callback) -> module.tinkerOn options, callback), callback

  @off: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    Utils.load options, (err) ->
      return callback(err) if err

      Module.findByGlob options, (err, modules) ->
        return callback(err) if err
        return callback(new Error "No modules found for glob #{options.glob}") if modules.length is 0
        Async.eachSeries modules, ((module, callback) -> module.tinkerOff options, callback), callback

  @exec: (args, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    Utils.load options, (err) ->
      return callback(err) if err

      Module.findByGlob options, (err, modules) ->
        return callback(err) if err
        return callback(new Error "No modules found for glob #{options.glob}") if modules.length is 0
        Async.eachSeries modules, ((module, callback) -> module.exec args, options, callback), callback

  @cache: (action, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2

    switch action
      when 'clear', 'clean' then return RepoUtils.cacheClear(options, callback)
      else return callback(new Error "Unrecognized cache action '#{action}'")
