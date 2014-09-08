fs = require 'fs'
path = require 'path'
es = require 'event-stream'
colors = require 'colors'
Async = require 'async'
Tinker = require 'tinker'
Utils = require './lib/utils'

module.exports = class TinkerCLI
  @on: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    directory = if options.directory then path.join(process.cwd(), options.directory) else process.cwd()

    Utils.modules directory, glob, options, (err, modules) ->
      (console.error "failed #{err}".red; callback(err)) if err
      Async.each modules, ((module, callback) -> module.on callback), (err) ->
        (console.error "failed #{err}".red; callback(err)) if err
        callback()

  @off: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    directory = if options.directory then path.join(process.cwd(), options.directory) else process.cwd()

    Utils.modules directory, glob, options, (err, modules) ->
      (console.error "failed #{err}".red; callback(err)) if err
      Async.each modules, ((module, callback) -> module.off callback), (err) ->
        (console.error "failed #{err}".red; callback(err)) if err
        callback()
