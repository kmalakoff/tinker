path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
Vinyl = require 'vinyl-fs'
es = require 'event-stream'
jsonFileParse = require './json_file_parse'

MODULES =
  bower:
    package_name: 'bower.json'
    Class: require './bower_package'
  npm:
    package_name: 'package.json'
    Class: require './npm_package'

module.exports = class Utils
  @packages: (directory, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2

    if _.size(module_options = _.pick(options, _.keys(MODULES)))
      modules = {}; modules[key] = MODULES[key] for key, value of module_options when !!value
    else
      modules = MODULES

    Vinyl.src((path.join(directory, info.package_name) for name, info of modules))
      .pipe(es.map (file, callback) -> jsonFileParse(file, (err, parsed_file) -> callback(err, parsed_file)))
      .pipe es.writeArray (err, files) ->
        return callback(err) if err

        packages = []
        for file in files
          package_name = path.basename(file.path)
          info = _.find(MODULES, (info, name) -> info.package_name is package_name)
          packages.push new info.Class(file)
        callback(null, packages)

  @modules: (directory, glob, options, callback) ->
    Utils.packages directory, options, (err, packages) ->
      return callback(err) if err

      modules = []
      queue = new Queue()
      for pkg in packages
        do (pkg) -> queue.defer (callback) ->
          pkg.modules glob, (err, _modules) -> modules = modules.concat(_modules); callback(err)
      queue.await (err) ->
        callback(err) if err
        callback(null, modules)
