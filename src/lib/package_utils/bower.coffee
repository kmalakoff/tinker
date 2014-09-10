fs = require 'fs'
path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
bower = require 'bower'
fs = require 'fs-extra'

spawn = require '../spawn'
Module = require '../../module'

module.exports = class Utils extends (require './index')
  @loadModules: (pkg, callback) ->
    Module.destroy {package_id: pkg.id}, (err) ->
      return callback(err) if err

      module_directory = Utils.moduleDirectory(pkg)
      fs.readdir module_directory, (err, file_names) =>
        return callback() if err # does not exist

        queue = new Queue()
        for file_name in file_names
          do (file_name) -> queue.defer (callback) ->
            module_path = path.join(module_directory, file_name)
            fs.exists path.join(module_path, 'bower.json'), (exists) =>
              return callback() unless exists

              callback = _.once(callback)
              bower.commands.lookup(file_name)
                .on('error', callback)
                .on 'end', (info) =>

                  # TODO: BackboneORM - why is two-step save needed
                  new Module({name: file_name, path: module_path, root: Utils.moduleDirectory(pkg), git_url: info?.url}).save (err, module) -> module.save {package: pkg}, callback

        queue.await (err) -> callback(err, Array::splice.call(arguments, 1))

  @install: (pkg, callback) ->
    spawn 'bower install', Utils.cwd(pkg), (err) ->
      return callback(err) if err
      Utils.loadModules(pkg, callback)
  @uninstall: (pkg, callback) -> fs.remove Utils.moduleDirectory(pkg), callback

  @moduleDirectory: (pkg) -> path.join(Utils.root(pkg), 'bower_components')
  @installModule: (pkg, module, callback) -> spawn "bower install #{module.get('name')}", Utils.cwd(pkg), callback
