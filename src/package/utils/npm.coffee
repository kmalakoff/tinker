path = require 'path'
Queue = require 'queue-async'
rimraf = require 'rimraf'
rpt = require 'read-package-tree'

spawn = require '../../lib/spawn'
Module = require '../module'

module.exports = class Utils extends (require './base')
  @loadModules: (pkg, callback) ->
    Module.destroy {package_id: pkg.id}, (err) ->
      return callback(err) if err

      collectModules = (data) =>
        results = []
        results.push new Module({name: (data.package?.name or ''), path: data.path, root: Utils.moduleDirectory(pkg), git_url: data.package?.url})
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
  @uninstall: (pkg, callback) -> rimraf Utils.moduleDirectory(pkg), callback

  @moduleDirectory: (pkg) -> path.join(Utils.root(pkg), 'node_modules')
  @installModule: (pkg, module, callback) -> spawn "npm install #{module.name}", Utils.cwd(pkg), callback
