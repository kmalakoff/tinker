fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
Vinyl = require 'vinyl-fs'
es = require 'event-stream'
jsonFileParse = require '../json_file_parse'
bower = require 'bower'

spawn = require '../spawn'
Module = require '../../module'
RepoURL = require '../repo_url'

module.exports = class Utils extends (require './index')
  @loadModules: (pkg, callback) ->
    Vinyl.src(path.join(Utils.modulesDirectory(pkg), '*', 'bower.json'))
      .pipe jsonFileParse()
      .pipe es.map (file, callback) ->
        Module.findOrCreateByFile file, (err, module) -> if err then callback(err) else module.save({package: pkg}, callback)
      .pipe es.writeArray callback

  @install: (pkg, callback) -> spawn 'bower install', Utils.cwd(pkg), callback
  @uninstall: (pkg, callback) -> fs.remove Utils.modulesDirectory(pkg), callback

  @modulesDirectory: (pkg) -> path.join(Utils.root(pkg), 'bower_components')
  @installModule: (pkg, module, callback) ->
    cwd = path.dirname(pkg.get('path'))
    fs.ensureDir cwd, -> spawn "bower install #{module.get('name')}", {cwd: cwd}, callback

  @repositories: (pkg, module, callback) ->
    repositories = []
    repositories.push(url) if RepoURL.isValid(url = pkg.get('contents').dependencies?[module.get('name')])

    if RepoURL.isValid(url = module.get('contents')._source)
      if resolution = module.get('contents')._resolution
        switch resolution.type
          when 'version' then repositories.push("#{url}##{resolution.tag}")
          when 'branch' then repositories.push("#{url}##{resolution.branch}")
        repositories.push("#{url}##{resolution.commit}")
      repositories.push(url)

    queue = new Queue()
    queue.defer (callback) ->
      callback = _.once(callback)
      bower.commands.lookup(module.get('name'))
        .on('error', callback)
        .on 'end', (info) => repositories.push(url) if RepoURL.isValid(url = info?.url); callback()
    queue.await (err) -> callback(err, repositories)
