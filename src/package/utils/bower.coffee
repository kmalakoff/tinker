path = require 'path'
Wrench = require 'wrench'

BaseUtils = require './base'
spawn = require '../../lib/spawn'

module.exports = class Utils extends BaseUtils
  @loadModules: (pkg, callback) ->
    module_directory = Utils.moduleDirectory(pkg)

    fs.readdir module_directory, (err, files) =>
      return callback(err) if err

      es.readArray((file for file in files when minimatch(file, glob)))
        .pipe es.map (file_name, callback) =>
          module_path = path.join(module_directory, file_name)
          fs.exists path.join(module_path, 'bower.json'), (exists) =>
            return callback() unless exists

            callback = _.once(callback)
            bower.commands.lookup(file_name)
              .on('error', callback)
              .on 'end', (info) =>
                contents = @get('contents')
                callback(null, new Module({owner: pkg, name: file_name, path: module_path, root: Utils.moduleDirectory(pkg), url: url = info?.url, package_url: (contents.dependencies or {})[file_name]}))

        .pipe(es.writeArray(callback))

  @install: (pkg, callback) -> spawn 'bower install', BaseUtils.cwd(pkg), callback
  @uninstall: (pkg, callback) -> Wrench.rmdirSyncRecursive(Utils.moduleDirectory(pkg), true); callback()

  @installModule: (pkg, module, callback) -> spawn "bower install #{module.name}", BaseUtils.cwd(pkg), callback

  @moduleDirectory: (pkg) -> path.join(BaseUtils.root(pkg), 'bower_components')
