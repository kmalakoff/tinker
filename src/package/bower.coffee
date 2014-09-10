fs = require 'fs'
path = require 'path'
_ = require 'underscore'
es = require 'event-stream'
minimatch = require 'minimatch'
File = require 'vinyl'
jsonFileParse = require '../lib/json_file_parse'
Queue = require 'queue-async'
Module = require './module'

bower = require 'bower'
spawn = require '../lib/spawn'
Wrench = require 'wrench'

PROPERTIES = ['path', 'contents']

module.exports = class BowerPackage extends (require 'backbone').Model
  constructor: (options) ->
    @[key] = value for key, value of _.pick(options, PROPERTIES)
    throw new Error "Module missing #{key}" for key in PROPERTIES when not @hasOwnProperty(key)
    @contents.dependencies or= {}

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
                callback(null, new Module({owner: @, name: file_name, path: module_path, root: @componentDirectory(), url: url = info?.url, package_url: @contents.dependencies[file_name]}))

        .pipe(es.writeArray(callback))

  install: (callback) -> spawn 'bower install', {cwd: @baseDirectory()}, callback
  uninstall: (callback) -> Wrench.rmdirSyncRecursive(@componentDirectory(), true); callback()

  installModule: (module, callback) -> spawn "bower install #{module.name}", {cwd: @baseDirectory()}, callback

  baseDirectory: -> path.dirname(@path)
  componentDirectory: -> path.join(path.dirname(@path), 'bower_components')
