fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
es = require 'event-stream'
Queue = require 'queue-async'
bower = require 'bower'
Vinyl = require 'vinyl-fs'
gitURLNormalizer = require 'github-url-from-git'
jsonFileParse = require '../json_file_parse'

spawn = require '../spawn'
Module = require '../../module'

module.exports = class Utils extends (require './index')
  @loadModules: (pkg, callback) ->
    Module.destroy {package_id: pkg.id}, (err) ->
      return callback(err) if err

      Vinyl.src(path.join(Utils.modulesDirectory(pkg), '*', 'bower.json'))
        .pipe jsonFileParse()
        .pipe es.map (file, callback) ->
          # TODO: BackboneORM - why is two-step save needed
          new Module(_.extend({name: file.contents.name}, _.pick(file, 'cwd', 'path', 'contents'))).save (err, module) -> module.save {package: pkg}, callback
        .pipe es.writeArray callback

  @install: (pkg, callback) ->
    spawn 'bower install', Utils.cwd(pkg), (err) ->
      return callback(err) if err
      Utils.loadModules(pkg, callback)
  @uninstall: (pkg, callback) -> fs.remove Utils.modulesDirectory(pkg), callback

  @modulesDirectory: (pkg) -> path.join(Utils.root(pkg), 'bower_components')
  @installModule: (pkg, module, callback) -> spawn "bower install #{module.get('name')}", Utils.cwd(module), callback
  @gitURL: (pkg, module, callback) ->
    # a git url - pass raw
    return callback(null, location) if (location = pkg.get('contents').dependencies?[module.get('name')]) and gitURLNormalizer(location)

    callback = _.once(callback)
    bower.commands.lookup(module.get('name'))
      .on('error', callback)
      .on 'end', (info) =>
        return callback(new Error "Module not found on bower: #{module.get('name')}") unless git_url = info?.url
        callback(null, git_url)
