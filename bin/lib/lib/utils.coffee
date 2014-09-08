path = require 'path'
_ = require 'underscore'
Vinyl = require 'vinyl-fs'
es = require 'event-stream'
jsonFileParse = require './json_file_parse'

MODULES =
  'bower.json': require './bower_package'
  'package.json': require './npm_package'

module.exports = class Utils
  @packages: (directory, callback) ->
    Vinyl.src((path.join(directory, module) for module in _.keys(MODULES)))
      .pipe(es.map (file, callback) -> jsonFileParse(file, (err, parsed_file) -> callback(err, parsed_file)))
      .pipe es.writeArray (err, files) ->
        return callback(err) if err
        callback(null, (new MODULES[path.basename(file.path)](file) for file in files))
