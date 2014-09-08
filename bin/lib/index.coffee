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
      queue = new Queue()
      for pkg in packages
        do (pkg) -> queue.defer (callback) ->
          pkg.modules glob, (err, modules) ->
            (console.error "failed #{err}".red; callback(err)) if err
            console.log 'modules', modules
            callback()
      queue.await callback

  @off: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    directory = if options.directory then path.join(process.cwd(), options.directory) else process.cwd()

    console.log "tinker off #{glob}".black
    callback()
