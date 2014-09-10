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

module.exports = class Package extends (require 'backbone').Model
  model_name: 'Package'
  sync: (require 'backbone-orm').sync(Package)

  @TYPES = [
    # {name: 'npm', file_name: 'package.json'}
    {name: 'bower', file_name: 'bower.json'}
    # {name: 'component', file_name: 'component.json'}
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

    # filter
    types = Package.TYPES
    types = _.filter(Package.TYPES, (info) -> !!load_types[info.name]) if _.size(load_types = _.pick(options, _.pluck(Package.TYPES, 'name')))

    (path.join(directory, info.file_name) for info in types)

  @createFromFile: (file, callback) ->
    file_name = path.basename(file.path)
    info = _.find(Package.TYPES, (info, name) -> info.file_name is file_name)
    new Package({type: info.type, path: file.path}).save (err, pkg) ->
      return callback(err) if err
      callback(null, pkg)

  modules: (glob, callback) ->
    fs.readdir @componentDirectory(), (err, files) =>
      return callback(err) if err

      es.readArray((file for file in files when minimatch(file, glob)))
        .pipe es.map (file_name, callback) =>
          module_path = path.join(@componentDirectory(), file_name)
          fs.exists path.join(module_path, 'bower.json'), (exists) =>
            return callback() unless exists

            callback = _.once(callback)
            bower.commands.lookup(file_name)
              .on('error', callback)
              .on 'end', (info) =>
                contents = @get('contents')
                callback(null, new Module({owner: @, name: file_name, path: module_path, root: @componentDirectory(), url: url = info?.url, package_url: (contents.dependencies or {})[file_name]}))

        .pipe(es.writeArray(callback))

  install: (callback) -> spawn 'bower install', {cwd: @baseDirectory()}, callback
  uninstall: (callback) -> Wrench.rmdirSyncRecursive(@componentDirectory(), true); callback()

  installModule: (module, callback) -> spawn "bower install #{module.name}", {cwd: @baseDirectory()}, callback

  baseDirectory: -> path.dirname(@get('path'))
  componentDirectory: -> path.join(path.dirname(@get('path')), 'bower_components')
