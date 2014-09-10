fs = require 'fs'
path = require 'path'
_ = require 'underscore'
es = require 'event-stream'
minimatch = require 'minimatch'
File = require 'vinyl'
jsonFileParse = require '../lib/json_file_parse'
Queue = require 'queue-async'
bower = require 'bower'
Module = require './module'
rpt = require 'read-package-tree'

spawn = require '../lib/spawn'
Wrench = require 'wrench'

module.exports = class NPMPackage extends (require 'backbone').Model
  model_name: 'NPMPackage'
  sync: (require 'backbone-orm').sync(NPMPackage)

  modules: (glob, callback) ->
    collectModules = (data, glob) =>
      results = []
      if minimatch(name = (data.package?.name or ''), glob)
        contents = @get('contents')
        results.push new Module({owner: @, name, path: data.path, root: @componentDirectory(), url: data.package?.url, package_url: (contents.dependencies or {})[name]})
      results = results.concat(collectModules(child, glob)) for child in (data.children or [])
      return results

    rpt @baseDirectory(), (err, data) => callback(null, collectModules(data, glob))

  install: (callback) -> spawn 'npm install', {cwd: @baseDirectory()}, callback
  uninstall: (callback) -> Wrench.rmdirSyncRecursive(@componentDirectory(), true); callback()

  installModule: (module, callback) -> spawn "npm install #{module.name}", {cwd: @baseDirectory()}, callback

  baseDirectory: -> path.dirname(@get('path'))
  componentDirectory: -> path.join(path.dirname(@get('path')), 'node_modules')
