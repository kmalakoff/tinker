Async = require 'async'
Package = require './package/package'

module.exports = class Tinker
  @install: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    Package.load options, (err, packages) ->
      return callback(err) if err
      Async.each packages, ((pkg, callback) -> pkg.install callback), callback

  @uninstall: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    Package.load options, (err, packages) ->
      return callback(err) if err
      Async.each packages, ((pkg, callback) -> pkg.uninstall callback), callback

  @on: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    Utils.modulesExec glob, options, ((module, callback) -> module.on options, callback), (err) ->
      console.log err.toString().red if err
      callback(err)

  @off: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    Utils.modulesExec glob, options, ((module, callback) -> module.off options, callback), (err) ->
      console.log err.toString().red if err
      callback(err)

      Package.all (err, packages) ->
        console.log 'err, packages', err, packages
        Async.each packages, fn, callback
