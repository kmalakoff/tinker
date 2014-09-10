_ = require 'underscore'
Git = require 'nodegit'

module.exports = class GitRepo extends (require 'backbone').Model
  model_name: 'GitRepo'
  sync: (require 'backbone-orm').sync(GitRepo)

  @load: (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1

    return callback()

  clone: (path, callback) ->
    Git.Repo.clone @get('git_url'), path, null, (err, repo) => callback(err)
