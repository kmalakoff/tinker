_ = require 'underscore'
Git = require 'nodegit'

PROPERTIES = ['path', 'url']

module.exports = class GitRepo
  constructor: (options) ->
    @[key] = value for key, value of _.pick(options, PROPERTIES)
    throw new Error "GitRepo missing #{key}" for key in PROPERTIES when not @hasOwnProperty(key)

  clone: (callback) ->
    Git.Repo.clone @url, @path, null, (err, repo) => callback(err)
