fs = require 'fs-extra'
path = require 'path'
Queue = require 'queue-async'
rpt = require 'read-package-tree'

spawn = require '../spawn'
Module = require '../../module'
RepoURL = require '../repo_url'

module.exports = class Utils extends (require './index')
  @loadModules: (pkg, callback) ->
    collectModules = (data, cwd) =>
      results = []
      if cwd # skip root
        results.push new Module({name: data.package.name, cwd: cwd, path: path.join(data.path, 'package.json'), contents: data.package})
      else
        cwd = data.path
      results = results.concat(collectModules(child, cwd)) for child in (data.children or [])
      return results

    rpt Utils.root(pkg), (err, data) ->
      return callback(err) if err

      queue = new Queue()
      for module in collectModules(data)
        do (module) -> queue.defer (callback) -> module.save({package: pkg}, callback)

      queue.await (err) -> callback(err, Array::splice.call(arguments, 1))

  @install: (pkg, callback) -> spawn 'npm install', Utils.cwd(pkg), callback
  @uninstall: (pkg, callback) -> fs.remove Utils.modulesDirectory(pkg), callback

  @modulesDirectory: (pkg) -> path.join(Utils.root(pkg), 'node_modules')
  @installModule: (pkg, module, callback) ->
    cwd = path.dirname(Utils.root(module))
    fs.ensureDir cwd, -> spawn "npm install #{module.get('name')}", {cwd: cwd}, callback

  @repositories: (pkg, module, callback) ->
    repositories = []
    repositories.push(url) if RepoURL.isValid(url = pkg.get('contents').dependencies?[module.get('name')])
    if RepoURL.isValid(url = module.get('contents').repository?.url)
      repositories.push(url)
      repositories.push("#{RepoURL.normalize(url)}##{module.get('contents').version}")

    callback(null, repositories)
