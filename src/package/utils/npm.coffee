path = require 'path'
Wrench = require 'wrench'
rpt = require 'read-package-tree'

BaseUtils = require './base'
spawn = require '../../lib/spawn'

module.exports = class Utils extends BaseUtils
  @loadModules: (pkg, callback) ->
    collectModules = (data, glob) =>
      results = []
      if minimatch(name = (data.package?.name or ''), glob)
        contents = @get('contents')
        results.push new Module({owner: @, name, path: data.path, root: @componentDirectory(), url: data.package?.url, package_url: (contents.dependencies or {})[name]})
      results = results.concat(collectModules(child, glob)) for child in (data.children or [])
      return results

    rpt @baseDirectory(), (err, data) => callback(null, collectModules(data, glob))

  @install: (pkg, callback) -> spawn 'npm install', BaseUtils.cwd(pkg), callback
  @uninstall: (pkg, callback) -> Wrench.rmdirSyncRecursive(Utils.moduleDirectory(pkg), true); callback()

  @installModule: (pkg, module, callback) -> spawn "npm install #{module.name}", BaseUtils.cwd(pkg), callback

  @moduleDirectory: (pkg) -> path.join(BaseUtils.root(pkg), 'node_modules')
