fs = require 'fs-extra'
path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
Vinyl = require 'vinyl-fs'
es = require 'event-stream'
request = require 'superagent'
inquirer =  require 'inquirer'

spawn = require '../spawn'
Module = require '../../module'
RepoURL = require '../repo_url'

BOWER_REGISTRY_URL = (new (require 'bower-config')()).load()._config.registry

module.exports = class Utils extends (require './index')
  @loadModules: (pkg, callback) ->
    Vinyl.src(path.join(Utils.modulesDirectory(pkg), '*', 'bower.json'))
      .pipe es.map (file, callback) ->
        Module.findOrCreate file, (err, module) -> if err then callback(err) else module.save({package: pkg}, callback)
      .pipe es.writeArray callback

  @install: (pkg, callback) -> spawn 'bower install --force-latest', Utils.cwd(pkg), callback
  @uninstall: (pkg, callback) -> fs.remove Utils.modulesDirectory(pkg), callback

  @modulesDirectory: (pkg) -> path.join(Utils.root(pkg), 'bower_components')
  @installModule: (pkg, module, callback) ->
    cwd = path.dirname(pkg.get('path'))
    fs.ensureDir cwd, -> spawn "bower install #{module.get('name')} --force-latest", {cwd: cwd}, callback

  @repositories: (pkg, module, callback) ->
    repositories = []
    repositories.push(url) if RepoURL.isValid(url = pkg.get('contents').dependencies?[module.get('name')])

    if RepoURL.isValid(url = module.get('contents')?._source)
      if resolution = module.get('contents')?._resolution
        switch resolution.type
          when 'version' then repositories.push("#{url}##{resolution.tag}")
          when 'branch' then repositories.push("#{url}##{resolution.branch}")
        repositories.push("#{url}##{resolution.commit}")
      repositories.push(url)

    queue = new Queue()
    queue.defer (callback) ->
      request.get("#{BOWER_REGISTRY_URL}/packages/#{module.get('name')}").end (err, res) ->
        repositories.push(url) if RepoURL.isValid(url = res?.body?.url)
        callback()
    queue.await (err) -> callback(err, repositories)
