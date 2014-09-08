fs = require 'fs'
path = require 'path'
es = require 'event-stream'
colors = require 'colors'
Queue = require 'queue-async'
Tinker = require 'tinker'
Utils = require './lib/utils'

module.exports = class TinkerCLI
  @on: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    directory = if options.directory then path.join(process.cwd(), options.directory) else process.cwd()
    console.log "tinker on #{glob}".black

    Utils.packages directory, (err, packages) ->
      return callback(err) if err

      modules = []
      queue = new Queue()
      for pkg in packages
        do (pkg) -> queue.defer (callback) ->
          pkg.modules glob, (err, _modules) -> modules = modules.concat(_modules); callback(err)
      queue.await (err) ->
        (console.error "failed #{err}".red; callback(err)) if err
        console.log 'modules', modules

  @off: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    directory = if options.directory then path.join(process.cwd(), options.directory) else process.cwd()

    console.log "tinker off #{glob}".black
    callback()
