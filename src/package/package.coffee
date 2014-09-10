fs = require 'fs'
path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
Vinyl = require 'vinyl-fs'
es = require 'event-stream'

minimatch = require 'minimatch'
File = require 'vinyl'
jsonFileParse = require '../lib/json_file_parse'
Queue = require 'queue-async'
Module = require './module'

bower = require 'bower'
spawn = require '../lib/spawn'
Wrench = require 'wrench'
Utils = require './utils'

module.exports = class Package extends (require 'backbone').Model
  model_name: 'Package'
  sync: (require 'backbone-orm').sync(Package)

  @TYPES = [
    {type: 'npm', file_name: 'package.json'}
    {type: 'bower', file_name: 'bower.json'}
    # {type: 'component', file_name: 'component.json'}
  ]

  @load: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    Vinyl.src(@optionsToDirectories(options), {read: false})
      .pipe es.writeArray (err, files) ->
        return callback(err) if err
        queue = new Queue()
        for file in files
          do (file) -> queue.defer (callback) -> Package.createFromFile(file, callback)
        queue.await (err) -> callback(err, Array::splice.call(arguments, 1))

  @optionsToDirectories: (options) ->
    directory = if options.directory then path.join(process.cwd(), options.directory) else process.cwd()
    types = Package.TYPES
    if _.size(load_types = _.pick(options, _.pluck(Package.TYPES, 'type'))) # filter
      types = _.filter(Package.TYPES, (info) -> !!load_types[info.type])
    (path.join(directory, info.file_name) for info in types)

  @createFromFile: (file, callback) ->
    file_name = path.basename(file.path)
    info = _.find(Package.TYPES, (info) -> info.file_name is file_name)
    new Package({type: info.type, path: file.path}).save (err, pkg) ->
      return callback(err) if err
      callback(null, pkg)

  loadModules: (callback) -> Utils.call(@, 'loadModules', arguments)
  install: (callback) -> Utils.call(@, 'install', arguments)
  uninstall: (callback) -> Utils.call(@, 'uninstall', arguments)
