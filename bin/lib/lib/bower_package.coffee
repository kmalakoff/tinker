fs = require 'fs'
path = require 'path'
_ = require 'underscore'
es = require 'event-stream'
minimatch = require 'minimatch'
File = require 'vinyl'
jsonFileParse = require './json_file_parse'
Queue = require 'queue-async'
bower = require 'bower'
{Module} = require 'tinker'

PROPERTIES = ['path', 'contents']

module.exports = class BowerPackage
  constructor: (options) ->
    @[key] = value for key, value of _.pick(options, PROPERTIES)
    throw new Error "Module missing #{key}" for key in PROPERTIES when not @hasOwnProperty(key)
    @contents.dependencies or= {}

  modules: (glob, callback) ->
    directory = path.join(path.dirname(@path), 'bower_components')
    fs.readdir directory, (err, files) =>
      return callback(err) if err

      es.readArray((file for file in files when minimatch(file, glob)))
        .pipe es.map (file_name, callback) =>
          module_path = path.join(directory, file_name)
          fs.exists path.join(module_path, 'bower.json'), (exists) =>
            return callback() unless exists

            callback = _.once(callback)
            bower.commands.lookup(file_name)
              .on('error', callback)
              .on 'end', (info) => callback(null, new Module({name: file_name, path: module_path, url: info?.url, package_url: @contents.dependencies[file_name]}))

        .pipe(es.writeArray(callback))
