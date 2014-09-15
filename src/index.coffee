_ = require 'underscore'
Async = require 'async'

Package = require './package'
Module = require './module'
RepoUtils = require './lib/repo_utils'
TinkerUtils = require './lib/utils'
Config = require './config'
tinkerInit = require './init/tinker'

loadAndRun = (args, count, fn) ->
  [count, fn] = [2, count] if arguments.length is 2
  args = Array::slice.call(args, 0)
  args.splice(args.length-2, 1, {}) while args.length < count
  [options, callback] = args.slice(-2)
  TinkerUtils.load options, (err) -> if err then callback(err) else fn.apply(Tinker, args)

module.exports = class Tinker
  @init: (options, callback) -> loadAndRun arguments, (options, callback) ->
    tinkerInit(options, callback)

  @config: (args, options, callback) -> loadAndRun arguments, 3, (args, options, callback) ->
    if args.length then Config.save(Config.parseArgs(args), callback) else console.log Config.toJSON()

  @update: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    loadAndRun [options, callback], ->
      Module.eachSeriesByGlob options, ((module, callback) -> module.init _.defaults({force: true}, options), callback), callback

  @install: (options, callback) -> loadAndRun arguments, (options, callback) ->
    if options.glob is '*'
      Package.each ((pkg, callback) -> pkg.install(options, callback)), callback
    else
      Module.eachSeriesByGlob options, ((module, callback) -> module.install options, callback), callback

  @uninstall: (options, callback) -> loadAndRun arguments, (options, callback) ->
    if options.glob is '*'
      Package.each ((pkg, callback) -> pkg.uninstall(options, callback)), callback
    else
      Module.eachSeriesByGlob options, ((module, callback) -> module.uninstall options, callback), callback

  @on: (options, callback) -> loadAndRun arguments, (options, callback) ->
    Module.eachSeriesByGlob options, ((module, callback) -> module.tinkerOn options, callback), callback

  @off: (options, callback) -> loadAndRun arguments, (options, callback) ->
    Module.eachSeriesByGlob options, ((module, callback) -> module.tinkerOff options, callback), callback

  @exec: (args, options, callback) -> loadAndRun arguments, 3, (args, options, callback) ->
    Module.eachSeriesByGlob options, ((module, callback) -> module.exec args, options, callback), callback

  @cache: (action, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2

    switch action
      when 'clear', 'clean' then return RepoUtils.cacheClear(options, callback)
      else return callback(new Error "Unrecognized cache action '#{action}'")
