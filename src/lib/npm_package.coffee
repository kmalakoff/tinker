fs = require 'fs'
path = require 'path'
_ = require 'underscore'
es = require 'event-stream'
minimatch = require 'minimatch'
File = require 'vinyl'
jsonFileParse = require './json_file_parse'
Queue = require 'queue-async'
bower = require 'bower'
Module = require './module'
rpt = require 'read-package-tree'

spawn = require './spawn'
Wrench = require 'wrench'

PROPERTIES = ['path', 'contents']

module.exports = class NPMPackage
  constructor: (options) ->
    @[key] = value for key, value of _.pick(options, PROPERTIES)
    throw new Error "Module missing #{key}" for key in PROPERTIES when not @hasOwnProperty(key)
    @contents.dependencies or= {}

  modules: (glob, callback) ->
    collectModules = (data, glob) =>
      results = []
      if minimatch(name = (data.package?.name or ''), glob)
        results.push new Module({owner: @, name, path: data.path, root: @componentDirectory(), url: data.package?.url, package_url: @contents.dependencies[name]})
      results = results.concat(collectModules(child, glob)) for child in (data.children or [])
      return results

    rpt @baseDirectory(), (err, data) => callback(null, collectModules(data, glob))

  install: (callback) -> spawn 'npm install', {cwd: @baseDirectory()}, callback
  uninstall: (callback) -> Wrench.rmdirSyncRecursive(@componentDirectory(), true); callback()

  installModule: (module, callback) -> spawn "npm install #{module.name}", {cwd: @baseDirectory()}, callback

  baseDirectory: -> path.dirname(@path)
  componentDirectory: -> path.join(path.dirname(@path), 'node_modules')
