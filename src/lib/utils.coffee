path = require 'path'
_ = require 'underscore'
Async = require 'async'
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
  @packages: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    directory = if options.directory then path.join(process.cwd(), options.directory) else process.cwd()

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

  @packagesExec: (options, fn, callback) ->
    Utils.packages options, (err, packages) ->
      return callback(err) if err
      Async.each packages, fn, callback

  @modules: (glob, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2
    Utils.packages options, (err, packages) ->
      return callback(err) if err

      modules = []
      queue = new Queue()
      for pkg in packages
        do (pkg) -> queue.defer (callback) ->
          pkg.modules glob, (err, _modules) -> modules = modules.concat(_modules); callback(err)
      queue.await (err) ->
        return callback(err) if err
        callback(null, modules)

  @modulesExec: (glob, options, fn, callback) ->
    Utils.modules glob, options, (err, modules) ->
      return callback(err) if err
      Async.each modules, fn, callback
