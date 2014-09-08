fs = require 'fs'
path = require 'path'
_ = require 'underscore'
es = require 'event-stream'
minimatch = require 'minimatch'
File = require 'vinyl'
jsonFileParse = require './json_file_parse'
Queue = require 'queue-async'
bower = require 'bower'
{Module} = require 'tinker'
rpt = require 'read-package-tree'

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
        results.push new Module({name, path: data.path, url: data.package?.url, package_url: @contents.dependencies[name]})
      results = results.concat(collectModules(child, glob)) for child in (data.children or [])
      return results

    rpt path.dirname(@path), (err, data) => callback(null, collectModules(data, glob))

