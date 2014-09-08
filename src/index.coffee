colors = require 'colors'
Utils = require './lib/utils'

module.exports = class Tinker
  @install: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    Utils.packagesExec options, ((pkg, callback) -> pkg.install callback), (err) ->
      console.log err.toString().red if err
      callback(err)

  @uninstall: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    Utils.packagesExec options, ((pkg, callback) -> pkg.uninstall callback), (err) ->
      console.log err.toString().red if err
      callback(err)

  @on: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    Utils.modulesExec glob, options, ((module, callback) -> module.on callback), (err) ->
      console.log err.toString().red if err
      callback(err)

  @off: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    Utils.modulesExec glob, options, ((module, callback) -> module.off callback), (err) ->
      console.log err.toString().red if err
      callback(err)
