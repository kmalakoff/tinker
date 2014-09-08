path = require 'path'
Vinyl = require 'vinyl-fs'
es = require 'event-stream'
BowerPackage = require './bower_package'
jsonFileParse = require './json_file_parse'

MODULES = ['bower.json']

module.exports = class Utils
  @packages: (directory, callback) ->
    Vinyl.src((path.join(directory, module) for module in MODULES))
      .pipe(es.map (file, callback) -> jsonFileParse(file, (err, parsed_file) -> callback(err, parsed_file)))
      .pipe es.writeArray (err, files) ->
        return callback(err) if err
        callback(null, (new BowerPackage(file) for file in files))
