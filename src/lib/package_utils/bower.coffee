fs = require 'fs'
path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
bower = require 'bower'
fs = require 'fs-extra'
gitURLNormalizer = require 'github-url-from-git'

spawn = require '../spawn'
Module = require '../../module'

module.exports = class Utils extends (require './index')
  @loadModules: (pkg, callback) ->
    Module.destroy {package_id: pkg.id}, (err) ->
      return callback(err) if err

      modules_path = Utils.modulesDirectory(pkg)
      cwd = path.dirname(modules_path)
      fs.readdir modules_path, (err, file_names) =>
        return callback() if err # does not exist

        queue = new Queue()
        for file_name in file_names
          do (file_name) -> queue.defer (callback) ->
            base = path.join(modules_path, file_name)
            fs.exists path.join(base, 'bower.json'), (exists) =>
              return callback() unless exists

              # TODO: BackboneORM - why is two-step save needed
              new Module({name: file_name, cwd: cwd, base: base, path: path.join(base, 'bower.json')}).save (err, module) -> module.save {package: pkg}, callback

        queue.await (err) ->
          callback(err, Array::splice.call(arguments, 1))

  @install: (pkg, callback) ->
    spawn 'bower install', Utils.cwd(pkg), (err) ->
      return callback(err) if err
      Utils.loadModules(pkg, callback)
  @uninstall: (pkg, callback) -> fs.remove Utils.modulesDirectory(pkg), callback

  @modulesDirectory: (pkg) -> path.join(Utils.root(pkg), 'bower_components')
  @installModule: (pkg, module, callback) -> spawn "bower install #{module.get('name')}", Utils.cwd(module), callback
  @gitURL: (pkg, module, callback) ->
    package_json = pkg.packageJSON()
    module_name = module.get('name')

    # a git url - pass raw
    return callback(null, location) if (location = package_json.dependencies?[module_name]) and gitURLNormalizer(location)

    callback = _.once(callback)
    bower.commands.lookup(module_name)
      .on('error', callback)
      .on 'end', (info) =>
        return callback(new Error "Module not found on bower: #{module_name}") unless git_url = info?.url
        callback(null, git_url)
