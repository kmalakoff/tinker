fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
es = require 'event-stream'
Queue = require 'queue-async'
bower = require 'bower'
Vinyl = require 'vinyl-fs'

spawn = require '../spawn'
Module = require '../../module'
jsonFileParse = require '../json_file_parse'
RepoUtils = require '../repo_utils'

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
  @repositories: (pkg, module, callback) ->
    repositories = []
    repositories.push(url) if RepoUtils.isURL(url = pkg.get('contents').dependencies?[module.get('name')])

    queue = new Queue()
    queue.defer (callback) ->
      callback = _.once(callback)
      bower.commands.lookup(module.get('name'))
        .on('error', callback)
        .on 'end', (info) => repositories.push(url) if RepoUtils.isURL(url = info?.url); callback()
    queue.await (err) -> callback(err, repositories)
