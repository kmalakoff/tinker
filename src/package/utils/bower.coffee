fs = require 'fs'
path = require 'path'
_ = require 'underscore'
es = require 'event-stream'
bower = require 'bower'
Wrench = require 'wrench'

spawn = require '../../lib/spawn'
Module = require '../module'

module.exports = class Utils extends (require './base')
  @loadModules: (pkg, callback) ->
    module_directory = Utils.moduleDirectory(pkg)

    fs.readdir module_directory, (err, files) =>
      return callback() if err # does not exist

      es.readArray(files)
        .pipe es.map (file_name, callback) =>
          module_path = path.join(module_directory, file_name)
          fs.exists path.join(module_path, 'bower.json'), (exists) =>
            return callback() unless exists

            callback = _.once(callback)
            bower.commands.lookup(file_name)
              .on('error', callback)
              .on 'end', (info) =>
                callback(null, new Module({owner: pkg, name: file_name, path: module_path, root: Utils.moduleDirectory(pkg), url: url = info?.url}))

        .pipe(es.writeArray(callback))

  @install: (pkg, callback) -> spawn 'bower install', Utils.cwd(pkg), callback
  @uninstall: (pkg, callback) -> Wrench.rmdirSyncRecursive(Utils.moduleDirectory(pkg), true); callback()

  @installModule: (pkg, module, callback) -> spawn "bower install #{module.name}", Utils.cwd(pkg), callback

  @moduleDirectory: (pkg) -> path.join(Utils.root(pkg), 'bower_components')
