fs = require 'fs-extra'
path = require 'path'
Queue = require 'queue-async'
rpt = require 'read-package-tree'

spawn = require '../spawn'
Module = require '../../module'

module.exports = class Utils extends (require './index')
  @loadModules: (pkg, callback) ->
    Module.destroy {package_id: pkg.id}, (err) ->
      return callback(err) if err

      collectModules = (data) =>
        results = []
        results.push new Module({name: (data.package?.name or ''), path: data.path, root: Utils.moduleDirectory(pkg), git_url: data.package.repository?.url})
        results = results.concat(collectModules(child)) for child in (data.children or [])
        return results

      rpt Utils.root(pkg), (err, data) ->
        return callback(err) if err

        queue = new Queue()
        for module in collectModules(data)
          do (module) -> queue.defer (callback) ->
            # TODO: BackboneORM - why is two-step save needed
            module.save (err, module) -> module.save {package: pkg}, callback

        queue.await (err) -> callback(err, Array::splice.call(arguments, 1))

  @install: (pkg, callback) -> spawn 'npm install', Utils.cwd(pkg), callback
  @uninstall: (pkg, callback) -> fs.remove Utils.moduleDirectory(pkg), callback

  @moduleDirectory: (pkg) -> path.join(Utils.root(pkg), 'node_modules')
  @installModule: (pkg, module, callback) -> spawn "npm install #{module.get('name')}", Utils.cwd(module), callback
