path = require 'path'
Wrench = require 'wrench'
rpt = require 'read-package-tree'

spawn = require '../../lib/spawn'
Module = require '../module'

module.exports = class Utils extends (require './base')
  @loadModules: (pkg, callback) ->
    collectModules = (data) =>
      results = []
      results.push new Module({owner: pkg, name: (data.package?.name or ''), path: data.path, root: Utils.moduleDirectory(pkg), url: data.package?.url})
      results = results.concat(collectModules(child)) for child in (data.children or [])
      return results

    rpt Utils.root(pkg), (err, data) => callback(null, collectModules(data))

  @install: (pkg, callback) -> spawn 'npm install', Utils.cwd(pkg), callback
  @uninstall: (pkg, callback) -> Wrench.rmdirSyncRecursive(Utils.moduleDirectory(pkg), true); callback()

  @installModule: (pkg, module, callback) -> spawn "npm install #{module.name}", Utils.cwd(pkg), callback

  @moduleDirectory: (pkg) -> path.join(Utils.root(pkg), 'node_modules')
